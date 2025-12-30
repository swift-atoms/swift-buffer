import Binary
import StandardsTestSupport
import Testing

@testable import Buffer

// Tests for Buffer.Aligned conformance to Binary.Contiguous/Mutable.
// Array/ContiguousArray conformance tests are in swift-standards.

extension Buffer {
    enum BinaryConformance {
        #TestSuites
    }
}

// MARK: - Unit Tests

extension Buffer.BinaryConformance.Test.Unit {
    @Test("Buffer.Aligned conforms to Binary.Contiguous")
    func alignedConformsToContiguous() throws {
        var buffer = try Buffer.Aligned(byteCount: 16, alignment: 16)

        buffer.withUnsafeMutableBytes { ptr in
            for i in 0..<16 {
                ptr[i] = UInt8(i)
            }
        }

        buffer.withUnsafeBytes { ptr in
            #expect(ptr.count == 16)
            #expect(ptr[0] == 0)
            #expect(ptr[15] == 15)
        }
    }

    @Test("Buffer.Aligned conforms to Binary.Mutable")
    func alignedConformsToMutable() throws {
        var buffer = try Buffer.Aligned.zeroed(byteCount: 8, alignment: 8)

        buffer.withUnsafeMutableBytes { ptr in
            ptr[0] = 0xFF
        }

        buffer.withUnsafeBytes { ptr in
            #expect(ptr[0] == 0xFF)
        }
    }

    @Test("Buffer.Aligned count satisfies Binary.Contiguous requirement")
    func alignedCountProperty() throws {
        let buffer = try Buffer.Aligned(byteCount: 1024, alignment: 512)
        #expect(buffer.count == 1024)

        buffer.withUnsafeBytes { ptr in
            #expect(ptr.count == buffer.count)
        }
    }

    @Test("generic function accepts Buffer.Aligned as Binary.Contiguous")
    func genericContiguousFunction() throws {
        func readFirstByte<T: Binary.Contiguous & ~Copyable>(
            _ bytes: borrowing T
        ) -> UInt8 {
            bytes.withUnsafeBytes { ptr in
                ptr.first ?? 0
            }
        }

        var aligned = try Buffer.Aligned(byteCount: 16, alignment: 16)
        aligned.withUnsafeMutableBytes { $0[0] = 0x44 }

        #expect(readFirstByte(aligned) == 0x44)
    }

    @Test("generic function accepts Buffer.Aligned as Binary.Mutable")
    func genericMutableFunction() throws {
        func writeFirstByte<T: Binary.Mutable & ~Copyable>(
            _ bytes: inout T,
            value: UInt8
        ) {
            bytes.withUnsafeMutableBytes { ptr in
                if !ptr.isEmpty {
                    ptr[0] = value
                }
            }
        }

        var aligned = try Buffer.Aligned.zeroed(byteCount: 16, alignment: 16)

        writeFirstByte(&aligned, value: 0xCC)

        aligned.withUnsafeBytes { #expect($0[0] == 0xCC) }
    }
}
