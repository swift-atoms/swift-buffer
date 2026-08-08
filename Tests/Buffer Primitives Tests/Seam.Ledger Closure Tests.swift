// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

import Buffer_Primitives
import Buffer_Primitives_Test_Support
import Index_Primitives
import Store_Protocol_Primitives
import Testing

// MARK: - Self-firing closure fixtures for the seam-ledger laws (TX-N1B)
//
// The bound owner of the buffer discipline vends the seam-ledger law fixture
// (`Seam.Ledger.violations`) that every downstream column suite relies on. These
// closure fixtures prove, from the owner's OWN suite, that the fixture itself
// fires: a lawful reference column produces zero violations (positive control)
// and deliberately unlawful columns are each caught (negative controls). Without
// this, a silently broken ledger would let every downstream law suite pass
// vacuously.

// MARK: - Reference model columns

/// A minimal lawful column over the seam (`Store.Protocol` x `Buffer.Protocol`):
/// slot-addressed, count-honest, fixed capacity. Purely a model — no real storage.
private struct LawfulColumn: Store.`Protocol`, Buffer.`Protocol` {
    typealias Element = Int

    var slots: [(slot: Index<Int>, element: Int)] = []
    let capacityLimit: Index<Int>.Count

    init(capacity: Index<Int>.Count) { self.capacityLimit = capacity }

    var capacity: Index<Int>.Count { capacityLimit }
    var count: Index<Int>.Count { Index<Int>.Count(UInt(slots.count)) }

    subscript(slot: Index<Int>) -> Int {
        get { slots.first(where: { $0.slot == slot })!.element }
        set { slots[slots.firstIndex(where: { $0.slot == slot })!].element = newValue }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        slots.append((slot: slot, element: element))
    }

    mutating func move(at slot: Index<Int>) -> Int {
        slots.remove(at: slots.firstIndex(where: { $0.slot == slot })!).element
    }
}

/// An unlawful column whose `initialize(at:to:)` FAILS to increment `count`
/// (it reports the ledger of a column one element behind).
private struct CountLaggingColumn: Store.`Protocol`, Buffer.`Protocol` {
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

/// An unlawful column whose seam element ops SHRINK the reported capacity.
private struct CapacityDriftingColumn: Store.`Protocol`, Buffer.`Protocol` {
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

// MARK: - The closure fixtures

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
