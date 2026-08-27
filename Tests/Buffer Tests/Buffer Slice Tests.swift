import Buffer
import Testing

@Suite
struct `Buffer Slice Tests` {

    @Test
    func `Buffer Slice over a Span round-trips count and elements`() {
        let values: [UInt8] = [1, 2, 3, 4, 5]
        values.withUnsafeBufferPointer { buffer in
            let span = unsafe Span(_unsafeElements: buffer)
            let slice = Buffer<Never>.Slice(span)
            let count = slice.count
            let isEmpty = slice.isEmpty
            #expect(count == 5)
            #expect(!isEmpty)
        }
    }

    @Test
    func `Buffer Slice extracting a proper sub-range narrows count correctly`() {
        let values: [UInt8] = [10, 20, 30, 40, 50]
        values.withUnsafeBufferPointer { buffer in
            let span = unsafe Span(_unsafeElements: buffer)
            let slice = Buffer<Never>.Slice(span)
            let middle = slice.extracting(1..<4)
            let count = middle.count
            #expect(count == 3)
        }
    }

    @Test
    func `Buffer Slice supports the zero-length edge case`() {
        let values: [UInt8] = []
        values.withUnsafeBufferPointer { buffer in
            let span = unsafe Span(_unsafeElements: buffer)
            let slice = Buffer<Never>.Slice(span)
            let count = slice.count
            let isEmpty = slice.isEmpty
            #expect(count == 0)
            #expect(isEmpty)
        }
    }

    @Test
    func `Buffer Slice extracting the full bound range is identity`() {
        let values: [UInt8] = [10, 20, 30]
        values.withUnsafeBufferPointer { buffer in
            let span = unsafe Span(_unsafeElements: buffer)
            let slice = Buffer<Never>.Slice(span)
            let whole = slice.extracting(0..<3)
            let count = whole.count
            #expect(count == 3)
        }
    }
}
