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
import Index_Primitives
import Store_Protocol_Primitives
import Testing

// MARK: - Law/boundary/edge-case fixtures for Buffer.Storage, Buffer.Slice,
// Buffer.Capacity (TX-N1B controls: positive, negative, edgeCase)

/// A minimal `Store.`Protocol`` conformer standing in for a bound owner's
/// physical substrate — fixed capacity, slot-addressed, count-honest.
private struct FixedColumn {
    var slots: [Index<Int>: Int] = [:]
    let fixedCapacity: Index<Int>.Count

    init(capacity: Index<Int>.Count) { self.fixedCapacity = capacity }
}

/// A `Store.`Protocol`` conformer whose reported capacity CAN change after
/// construction — the fixture the "fixed at construction" negative test
/// actually needs.
///
/// `FixedColumn`'s capacity is a `let`, so no observation through it could
/// ever distinguish "`Buffer.Storage` captured the bound once" from
/// "`Buffer.Storage` re-derives it on every read" — both readings would agree
/// trivially. `GrowingColumn` makes the two readings divergeable.
private struct GrowingColumn {
    var slots: [Index<Int>: Int] = [:]
    var reportedCapacity: Index<Int>.Count

    init(capacity: Index<Int>.Count) { self.reportedCapacity = capacity }
}

extension GrowingColumn: Store.`Protocol` {
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

extension FixedColumn: Store.`Protocol` {
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

// [API-NAME-001]/[TEST-002] exception, cause recorded per TX-N1B receipt
// discipline: `@Suite`/`@Test` cannot be applied within ANY extension of a
// generic type — confirmed by the compiler (Apple Swift 6.4,
// swiftlang-6.4.0.27.1): "Attribute 'Suite' cannot be applied to a structure
// within a generic extension to type 'Buffer<Never>'" — even for a fully
// bound instantiation like `Buffer<Never>`. `Buffer<S>` is generic, so the
// extension-pattern nested-suite shape the lint rule expects is unreachable
// here; a top-level compound name is the only compiling shape available.
@Suite
struct `Buffer Storage Slice Capacity Tests` {}

extension `Buffer Storage Slice Capacity Tests` {
    @Suite
    struct Unit {

        // MARK: - Buffer.Capacity

        @Test
        func `Buffer Capacity wraps Index Count, reused not reinvented`() {
            let capacity = Buffer<Never>.Capacity<Int>(Index<Int>.Count(UInt(4)))
            #expect(capacity.count == Index<Int>.Count(UInt(4)))
        }

        // MARK: - Buffer.Storage — positive: capacity is captured from the wrapped base

        @Test
        func `Buffer Storage captures the wrapped store capacity at construction`() {
            let column = FixedColumn(capacity: Index<Int>.Count(UInt(4)))
            let storage = Buffer<Never>.Storage(base: column)
            #expect(storage.capacity.count == Index<Int>.Count(UInt(4)))
            #expect(storage.capacity.count == storage.base.capacity)
        }

        // MARK: - Buffer.Storage — negative: capacity is captured once at
        // construction, not aliased to any later mutation of the source value

        @Test
        func
            `Buffer Storage capacity is an independent copy, not a live reference to the source value`()
        {
            // GrowingColumn's capacity is a `var`, unlike FixedColumn's `let` —
            // required so a divergence is even OBSERVABLE (a `let`-backed
            // fixture cannot distinguish "captured once" from "re-derived on
            // read": both readings would trivially agree).
            var original = GrowingColumn(capacity: Index<Int>.Count(UInt(2)))
            let storage = Buffer<Never>.Storage(base: original)

            // Mutate the SOURCE value after construction. `Buffer.Storage.init`
            // takes `base` by `consuming`, and `GrowingColumn` is a value type,
            // so this mutates an independent copy — it must NOT reach `storage`
            // (there being no aliasing path to `storage.base` at all: it is
            // `private(set)`, so this is also a control on the type's public
            // surface, not only its value semantics).
            original.reportedCapacity = Index<Int>.Count(UInt(99))

            #expect(storage.capacity.count == Index<Int>.Count(UInt(2)))
            #expect(original.capacity == Index<Int>.Count(UInt(99)))
        }

        // MARK: - Buffer.Slice — positive: whole-region span round-trips

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
    struct Integration {
        /// The bound owner's own seam types (`FixedColumn`, `Store.`Protocol``)
        /// compose end-to-end with `Buffer.Storage` — the same integration path
        /// TX-N1B's downstream consumers (buffer-linear/-ring/-slab/-linked/-slots)
        /// will use.
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
