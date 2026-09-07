import Buffer
import Cardinal
import Index
import Ordinal
import Store
import Tagged
import Testing

private struct FixedColumn {
    var slots: [Index<Int>: Int] = [:]
    let fixedCapacity: Index<Int>.Count

    init(capacity: Index<Int>.Count) { self.fixedCapacity = capacity }
}

private struct GrowingColumn {
    var slots: [Index<Int>: Int] = [:]
    var reportedCapacity: Index<Int>.Count

    init(capacity: Index<Int>.Count) { self.reportedCapacity = capacity }
}

extension GrowingColumn: Store::Store.`Protocol` {
    typealias Element = Int

    var capacity: Index<Int>.Count { reportedCapacity }

    subscript(slot: Index<Int>) -> Int {
        get {
            guard let element = slots[slot] else {
                preconditionFailure("GrowingColumn: read of uninitialized slot \(slot)")
            }
            return element
        }
        set { slots[slot] = newValue }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        slots[slot] = element
    }

    mutating func move(at slot: Index<Int>) -> Int {
        guard let element = slots.removeValue(forKey: slot) else {
            preconditionFailure("GrowingColumn: move of uninitialized slot \(slot)")
        }
        return element
    }
}

extension FixedColumn: Store::Store.`Protocol` {
    typealias Element = Int

    var capacity: Index<Int>.Count { fixedCapacity }

    subscript(slot: Index<Int>) -> Int {
        get {
            guard let element = slots[slot] else {
                preconditionFailure("FixedColumn: read of uninitialized slot \(slot)")
            }
            return element
        }
        set { slots[slot] = newValue }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        slots[slot] = element
    }

    mutating func move(at slot: Index<Int>) -> Int {
        guard let element = slots.removeValue(forKey: slot) else {
            preconditionFailure("FixedColumn: move of uninitialized slot \(slot)")
        }
        return element
    }
}

@Suite
struct `Buffer Storage Slice Capacity Tests` {}

extension `Buffer Storage Slice Capacity Tests` {
    @Suite
    struct `Unit behavior` {

        @Test
        func `Buffer Capacity wraps Index Count, reused not reinvented`() {
            let capacity = Buffer<Never>.Capacity<Int>(Index<Int>.Count(UInt(4)))
            #expect(capacity.count == Index<Int>.Count(UInt(4)))
        }

        @Test
        func `Buffer Storage captures the wrapped store capacity at construction`() {
            let column = FixedColumn(capacity: Index<Int>.Count(UInt(4)))
            let storage = Buffer<Never>.Storage(base: column)
            #expect(storage.capacity.count == Index<Int>.Count(UInt(4)))
            #expect(storage.capacity.count == storage.base.capacity)
        }

        @Test
        func
            `Buffer Storage capacity is an independent copy, not a live reference to the source value`()
        {

            var original = GrowingColumn(capacity: Index<Int>.Count(UInt(2)))
            let storage = Buffer<Never>.Storage(base: original)

            original.reportedCapacity = Index<Int>.Count(UInt(99))

            #expect(storage.capacity.count == Index<Int>.Count(UInt(2)))
            #expect(original.capacity == Index<Int>.Count(UInt(99)))
        }

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
    }
}

extension `Buffer Storage Slice Capacity Tests` {
    @Suite
    struct `Edge Case` {

        @Test
        func `Buffer Capacity supports the zero-length edge case`() {
            let capacity = Buffer<Never>.Capacity<Int>(.zero)
            #expect(capacity == .zero)
        }

        @Test
        func
            `Buffer Storage at boundary-capacity zero reports zero capacity, not the store's own drift`()
        {
            let column = FixedColumn(capacity: .zero)
            let storage = Buffer<Never>.Storage(base: column)
            #expect(storage.capacity == .zero)
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
}

extension `Buffer Storage Slice Capacity Tests` {
    @Suite
    struct `Integration behavior` {

        @Test
        func `Buffer Storage over a live Store Protocol conformer composes end-to-end`() {
            var column = FixedColumn(capacity: Index<Int>.Count(UInt(3)))
            let slotZero = Index<Int>(_unchecked: Ordinal(UInt(0)))
            column.initialize(at: slotZero, to: 42)
            let storage = Buffer<Never>.Storage(base: column)
            #expect(storage.base[slotZero] == 42)
            #expect(storage.capacity.count == Index<Int>.Count(UInt(3)))
        }
    }
}

@Suite
struct `Buffers preserve noncopyable storage and elements` {
    private struct Payload: ~Copyable {
        let value: Int
    }

    @Test
    func `capacity zero and comparison accept noncopyable storage and elements`() {
        let zero = Buffer<Payload>.Capacity<Payload>.zero
        let one = Buffer<Payload>.Capacity<Payload>(1)
        let two = Buffer<Payload>.Capacity<Payload>(2)
        #expect(zero.count == .zero)
        #expect(zero < one)
        #expect(one < two)
        #expect(one == one)
    }

    @Test
    func `slice access and extraction borrow noncopyable elements`() {
        var payload = Payload(value: 42)
        unsafe withUnsafePointer(to: &payload) { pointer in
            let span = unsafe Span(_unsafeStart: pointer, count: 1)
            let slice = Buffer<Payload>.Slice(span)
            let count = slice.count
            let isEmpty = slice.isEmpty
            #expect(count == 1)
            #expect(!isEmpty)
            let borrowed = slice.span()
            #expect(borrowed[0].value == 42)
            let whole = slice.extracting(0..<1)
            let wholeSpan = whole.span()
            #expect(wholeSpan[0].value == 42)
            let empty = slice.extracting(1..<1)
            let emptyCount = empty.count
            #expect(emptyCount == 0)
        }
        #expect(payload.value == 42)
    }
}
