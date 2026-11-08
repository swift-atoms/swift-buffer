import Buffer
import Index
import Store
import Testing

private struct FixedColumn {
    var slots: [(slot: Index<Int>, element: Int)] = []
    let fixedCapacity: Index<Int>.Count

    init(capacity: Index<Int>.Count) { self.fixedCapacity = capacity }
}

private struct GrowingColumn {
    var slots: [(slot: Index<Int>, element: Int)] = []
    var reportedCapacity: Index<Int>.Count

    init(capacity: Index<Int>.Count) { self.reportedCapacity = capacity }
}

extension GrowingColumn: Store::Store.`Protocol` {
    typealias Element = Int

    var capacity: Index<Int>.Count { reportedCapacity }

    subscript(slot: Index<Int>) -> Int {
        get {
            guard let found = slots.first(where: { $0.slot == slot }) else {
                preconditionFailure("GrowingColumn: read of uninitialized slot \(slot)")
            }
            return found.element
        }
        set {
            guard let index = slots.firstIndex(where: { $0.slot == slot }) else {
                preconditionFailure("GrowingColumn: write to uninitialized slot \(slot)")
            }
            slots[index].element = newValue
        }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        slots.append((slot, element))
    }

    mutating func move(at slot: Index<Int>) -> Int {
        guard let index = slots.firstIndex(where: { $0.slot == slot }) else {
            preconditionFailure("GrowingColumn: move of uninitialized slot \(slot)")
        }
        return slots.remove(at: index).element
    }
}

extension FixedColumn: Store::Store.`Protocol` {
    typealias Element = Int

    var capacity: Index<Int>.Count { fixedCapacity }

    subscript(slot: Index<Int>) -> Int {
        get {
            guard let found = slots.first(where: { $0.slot == slot }) else {
                preconditionFailure("FixedColumn: read of uninitialized slot \(slot)")
            }
            return found.element
        }
        set {
            guard let index = slots.firstIndex(where: { $0.slot == slot }) else {
                preconditionFailure("FixedColumn: write to uninitialized slot \(slot)")
            }
            slots[index].element = newValue
        }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        slots.append((slot, element))
    }

    mutating func move(at slot: Index<Int>) -> Int {
        guard let index = slots.firstIndex(where: { $0.slot == slot }) else {
            preconditionFailure("FixedColumn: move of uninitialized slot \(slot)")
        }
        return slots.remove(at: index).element
    }
}

@Suite
struct `Buffer Storage Tests` {}

extension `Buffer Storage Tests` {
    @Suite
    struct Unit {

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
    }
}

extension `Buffer Storage Tests` {
    @Suite
    struct `Edge Case` {

        @Test
        func
            `Buffer Storage at boundary-capacity zero reports zero capacity, not the store's own drift`()
        {
            let column = FixedColumn(capacity: .zero)
            let storage = Buffer<Never>.Storage(base: column)
            #expect(storage.capacity.count == .zero)
        }
    }
}

extension `Buffer Storage Tests` {
    @Suite
    struct Integration {

        @Test
        func `Buffer Storage over a live Store Protocol conformer composes end-to-end`() {
            var column = FixedColumn(capacity: Index<Int>.Count(UInt(3)))
            let slotZero = Index<Int>.zero
            column.initialize(at: slotZero, to: 42)
            let storage = Buffer<Never>.Storage(base: column)
            #expect(storage.base[slotZero] == 42)
            #expect(storage.capacity.count == Index<Int>.Count(UInt(3)))
        }
    }
}
