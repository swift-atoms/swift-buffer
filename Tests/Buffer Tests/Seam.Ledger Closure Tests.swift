import Buffer
import Buffer_Protocol
import Buffer_Test_Support
import Cardinal_Tagged
import Index
import Ordinal
import Ordinal_Protocol
import Store
import Store_Protocol
import Tagged
import Testing

private struct LawfulColumn: Store::Store.`Protocol`, Buffer.`Protocol` {
    typealias Element = Int

    var slots: [(slot: Index<Int>, element: Int)] = []
    let capacityLimit: Index<Int>.Count

    init(capacity: Index<Int>.Count) { self.capacityLimit = capacity }

    var capacity: Index<Int>.Count { capacityLimit }
    var count: Index<Int>.Count { Index<Int>.Count(UInt(slots.count)) }

    subscript(slot: Index<Int>) -> Int {
        get {
            guard let found = slots.first(where: { $0.slot == slot }) else {
                preconditionFailure("LawfulColumn: read of uninitialized slot \(slot)")
            }
            return found.element
        }
        set {
            guard let index = slots.firstIndex(where: { $0.slot == slot }) else {
                preconditionFailure("LawfulColumn: write to uninitialized slot \(slot)")
            }
            slots[index].element = newValue
        }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        slots.append((slot: slot, element: element))
    }

    mutating func move(at slot: Index<Int>) -> Int {
        guard let index = slots.firstIndex(where: { $0.slot == slot }) else {
            preconditionFailure("LawfulColumn: move of uninitialized slot \(slot)")
        }
        return slots.remove(at: index).element
    }
}

private struct CountLaggingColumn: Store::Store.`Protocol`, Buffer.`Protocol` {
    typealias Element = Int

    var lawful = LawfulColumn(capacity: Index<Int>.Count(UInt(4)))

    var capacity: Index<Int>.Count { lawful.capacity }
    var count: Index<Int>.Count {

        lawful.slots.isEmpty
            ? Index<Int>.Count(UInt(0))
            : Index<Int>.Count(UInt(lawful.slots.count - 1))
    }

    subscript(slot: Index<Int>) -> Int {
        get { lawful[slot] }
        set { lawful[slot] = newValue }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        lawful.initialize(at: slot, to: element)
    }

    mutating func move(at slot: Index<Int>) -> Int {
        lawful.move(at: slot)
    }
}

private struct CapacityDriftingColumn: Store::Store.`Protocol`, Buffer.`Protocol` {
    typealias Element = Int

    var lawful = LawfulColumn(capacity: Index<Int>.Count(UInt(4)))
    var operations: UInt = 0

    var capacity: Index<Int>.Count { Index<Int>.Count(UInt(4) + operations) }
    var count: Index<Int>.Count { lawful.count }

    subscript(slot: Index<Int>) -> Int {
        get { lawful[slot] }
        set { lawful[slot] = newValue }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        operations += 1
        lawful.initialize(at: slot, to: element)
    }

    mutating func move(at slot: Index<Int>) -> Int {
        operations += 1
        return lawful.move(at: slot)
    }
}

@Suite
struct SeamLedgerClosureTests {

    @Test
    func `a lawful reference column passes the seam ledger laws`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { LawfulColumn(capacity: Index<Int>.Count(UInt(4))) },
            element: { $0 }
        )
        #expect(violations.isEmpty, "\(violations)")
    }

    @Test
    func `a lawful column at the boundary capacity of exactly two passes the seam ledger laws`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { LawfulColumn(capacity: Index<Int>.Count(UInt(2))) },
            element: { $0 }
        )
        #expect(violations.isEmpty, "\(violations)")
    }

    @Test
    func `the ledger rejects a column below the minimum capacity precondition`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { LawfulColumn(capacity: Index<Int>.Count(UInt(1))) },
            element: { $0 }
        )
        #expect(!violations.isEmpty)
    }

    @Test
    func `the ledger catches a column whose initialize fails to increment count`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { CountLaggingColumn() },
            element: { $0 }
        )
        #expect(!violations.isEmpty)
    }

    @Test
    func `the ledger catches a column whose seam ops drift capacity`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { CapacityDriftingColumn() },
            element: { $0 }
        )
        #expect(!violations.isEmpty)
    }
}
