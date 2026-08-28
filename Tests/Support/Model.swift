#if canImport(Darwin)
    import Darwin
#elseif os(Android)
    import Android
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(ucrt)
    import ucrt
#endif

public enum Model {}

extension Model {

    public struct Random {
        var state: UInt64

        public init(seed: UInt64) { self.state = seed }
    }
}

extension Model.Random {
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    public mutating func below(_ bound: Int) -> Int {
        Int(next() % UInt64(bound))
    }

    public mutating func chance(_ percent: Int) -> Bool {
        below(100) < percent
    }
}

extension Model {

    public struct Verdict {
        public let seed: UInt64
        public var transcript: [String] = []
        public var findings: [String] = []

        public init(seed: UInt64) { self.seed = seed }
    }
}

extension Model.Verdict {
    public var isClean: Bool { findings.isEmpty }

    public mutating func record(_ operation: String) {
        transcript.append(operation)
    }

    public mutating func diverged(_ messages: [String]) {
        guard !messages.isEmpty else { return }
        let at = transcript.endIndex - 1
        let operation = at >= 0 ? transcript[at] : "(setup)"
        findings.append(contentsOf: messages.map { "after op #\(at) `\(operation)`: \($0)" })
    }

    public var report: String {
        if isClean {
            return "clean — seed 0x\(String(seed, radix: 16)), \(transcript.count) ops"
        }
        return """
            MODEL DIVERGENCE — seed 0x\(String(seed, radix: 16)), \(transcript.count) ops run
            findings:
            \(findings.map { "  - \($0)" }.joined(separator: "\n"))
            transcript (replay by passing this seed):
            \(transcript.enumerated().map { "  \($0.offset): \($0.element)" }.joined(separator: "\n"))
            """
    }
}

extension Model {

    public static func operations(default count: Int) -> Int {
        guard
            let raw = environment("MODEL_SOAK_OPERATIONS"),
            let soak = Int(raw),
            soak > 0
        else {
            return count
        }
        return soak
    }

    public static func seeds(default fixed: [UInt64]) -> [UInt64] {
        guard let raw = environment("MODEL_SOAK_SEEDS") else { return fixed }
        let extras = raw.split(separator: ",").compactMap { piece -> UInt64? in
            let cleaned = piece.filter { !$0.isWhitespace }
            if cleaned.hasPrefix("0x") || cleaned.hasPrefix("0X") {
                return UInt64(cleaned.dropFirst(2), radix: 16)
            }
            return UInt64(cleaned)
        }
        return fixed + extras
    }

    public static func shouldAudit(op index: Int, of operations: Int) -> Bool {
        if operations <= 4_096 { return true }
        return index % 64 == 0 || index == operations - 1
    }

    private static func environment(_ name: String) -> String? {

        #if hasFeature(Embedded)
            return nil
        #else
            guard let pointer = unsafe getenv(name) else { return nil }
            return unsafe String(validatingCString: pointer)
        #endif
    }
}
