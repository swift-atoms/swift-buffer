import Buffer
import Index
import Testing

@Suite
struct `Buffer Capacity Tests` {

    @Test
    func `Buffer Capacity wraps Index Count, reused not reinvented`() {
        let capacity = Buffer<Never>.Capacity<Int>(Index<Int>.Count(UInt(4)))
        #expect(capacity.count == Index<Int>.Count(UInt(4)))
    }

    @Test
    func `Buffer Capacity supports the zero-length edge case`() {
        let capacity = Buffer<Never>.Capacity<Int>(.zero)
        #expect(capacity == .zero)
    }
}
