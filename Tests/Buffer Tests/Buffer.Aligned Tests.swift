import StandardsTestSupport
import Testing

@testable import Buffer

extension Buffer.Aligned {
    #TestSuites
}

// MARK: - Unit Tests

extension Buffer.Aligned.Test.Unit {
    @Test("allocates with valid parameters")
    func allocatesWithValidParameters() throws {
        let buffer = try Buffer.Aligned(byteCount: 1024, alignment: 512)
        #expect(buffer.count == 1024)
        #expect(buffer.alignment == 512)
    }

    @Test("allocates zeroed buffer")
    func allocatesZeroedBuffer() throws {
        let buffer = try Buffer.Aligned.zeroed(byteCount: 1024, alignment: 512)
        buffer.withUnsafeBytes { ptr in
            for byte in ptr {
                #expect(byte == 0)
            }
        }
    }

    @Test("allocates page-aligned buffer")
    func allocatesPageAlignedBuffer() throws {
        let buffer = try Buffer.Aligned.pageAligned(byteCount: 4096)
        #expect(buffer.count == 4096)
        #expect(buffer.alignment == Buffer.Memory.pageSize)
        let aligned = buffer.isAligned(to: Buffer.Memory.pageSize)
        #expect(aligned)
    }

    @Test("isAligned returns true for guaranteed alignment")
    func isAlignedToGuaranteed() throws {
        let buffer = try Buffer.Aligned(byteCount: 4096, alignment: 512)
        let aligned = buffer.isAligned(to: 512)
        #expect(aligned)
    }

    @Test("isAligned returns true for smaller alignments")
    func isAlignedToSmaller() throws {
        let buffer = try Buffer.Aligned(byteCount: 4096, alignment: 512)
        for boundary in [1, 2, 4, 8, 16, 32, 64, 128, 256] {
            let aligned = buffer.isAligned(to: boundary)
            #expect(aligned)
        }
    }

    @Test("withUnsafeBytes provides correct buffer")
    func withUnsafeBytesAccess() throws {
        var buffer = try Buffer.Aligned(byteCount: 1024, alignment: 512)

        buffer.withUnsafeMutableBytes { ptr in
            for i in 0..<ptr.count {
                ptr[i] = UInt8(i % 256)
            }
        }

        buffer.withUnsafeBytes { ptr in
            #expect(ptr.count == 1024)
            for i in 0..<ptr.count {
                #expect(ptr[i] == UInt8(i % 256))
            }
        }
    }

    @Test("withUnsafeMutableBytes allows modification")
    func withUnsafeMutableBytesAccess() throws {
        var buffer = try Buffer.Aligned.zeroed(byteCount: 1024, alignment: 512)

        buffer.withUnsafeMutableBytes { ptr in
            ptr[0] = 0xAB
            ptr[1] = 0xCD
        }

        buffer.withUnsafeBytes { ptr in
            #expect(ptr[0] == 0xAB)
            #expect(ptr[1] == 0xCD)
        }
    }

    @Test("typed throwing closure propagates error")
    func typedThrowingClosure() throws {
        enum TestError: Error { case expected }

        let buffer = try Buffer.Aligned(byteCount: 1024, alignment: 512)

        #expect(throws: TestError.expected) {
            try buffer.withUnsafeBytes { (_: UnsafeRawBufferPointer) throws(TestError) in
                throw TestError.expected
            }
        }
    }

    @Test("accepts power-of-2 alignments", arguments: [8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096])
    func acceptsValidAlignment(alignment: Int) throws {
        let buffer = try Buffer.Aligned(byteCount: alignment, alignment: alignment)
        #expect(buffer.alignment == alignment)
    }
}

// MARK: - Edge Cases

extension Buffer.Aligned.Test.EdgeCase {
    @Test("allows zero size (empty buffer)")
    func allowsZeroSize() throws {
        let buffer = try Buffer.Aligned(byteCount: 0, alignment: 512)
        #expect(buffer.count == 0)
        #expect(buffer.alignment == 512)
    }

    @Test("rejects negative size")
    func rejectsNegativeSize() {
        #expect(throws: Buffer.Aligned.Error.invalidSize) {
            _ = try Buffer.Aligned(byteCount: -1, alignment: 512)
        }
    }

    @Test("rejects non-power-of-2 alignment", arguments: [3, 5, 6, 7, 9, 10, 12, 15])
    func rejectsInvalidAlignment(alignment: Int) {
        #expect(throws: Buffer.Aligned.Error.invalidAlignment) {
            _ = try Buffer.Aligned(byteCount: 1024, alignment: alignment)
        }
    }

    @Test("rejects alignment below platform minimum", arguments: [1, 2, 4])
    func rejectsAlignmentBelowMinimum(alignment: Int) {
        // On 64-bit platforms, minimum alignment is 8 (sizeof(void*))
        // posix_memalign requires alignment >= sizeof(void*)
        #expect(throws: Buffer.Aligned.Error.invalidAlignment) {
            _ = try Buffer.Aligned(byteCount: 1024, alignment: alignment)
        }
    }

    @Test("isAligned returns false for invalid boundaries")
    func isAlignedRejectsInvalid() throws {
        let buffer = try Buffer.Aligned(byteCount: 4096, alignment: 512)
        let notAlignedTo0 = buffer.isAligned(to: 0)
        let notAlignedToNeg1 = buffer.isAligned(to: -1)
        let notAlignedTo3 = buffer.isAligned(to: 3)
        let notAlignedTo5 = buffer.isAligned(to: 5)
        #expect(!notAlignedTo0)
        #expect(!notAlignedToNeg1)
        #expect(!notAlignedTo3)
        #expect(!notAlignedTo5)
    }

    @Test("withMisalignedView creates offset pointer")
    func misalignedViewOffset() throws {
        let buffer = try Buffer.Aligned(byteCount: 1024, alignment: 512)

        buffer.withMisalignedView(offset: 1) { misaligned in
            #expect(misaligned.count == 1023)
            let aligned = isAligned(misaligned.baseAddress, to: 512)
            #expect(!aligned)
        }
    }

    @Test("withMisalignedMutableView creates offset pointer")
    func misalignedMutableViewOffset() throws {
        var buffer = try Buffer.Aligned.zeroed(byteCount: 1024, alignment: 512)

        buffer.withMisalignedMutableView(offset: 7) { misaligned in
            #expect(misaligned.count == 1017)
            misaligned[0] = 0xFF
        }

        buffer.withUnsafeBytes { ptr in
            #expect(ptr[7] == 0xFF)
        }
    }
}

// MARK: - Helper

private func isAligned(_ pointer: UnsafeRawPointer?, to boundary: Int) -> Bool {
    guard let pointer = pointer else { return false }
    return Int(bitPattern: pointer) % boundary == 0
}
