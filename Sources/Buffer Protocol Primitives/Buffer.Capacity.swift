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

public import Index_Primitives

// MARK: - Buffer.Capacity (TX-N1B)

extension Buffer where S: ~Copyable {
    /// The fixed upper bound a bounded buffer discipline may hold, spelled in
    /// the `Buffer` namespace.
    ///
    /// ## Composes, does not reinvent
    ///
    /// The single stored property reuses `Index<Element>.Count` — the same
    /// `Tagged<Element, Cardinal>` representation `Buffer.`Protocol`.count`
    /// uses for live occupancy (`buffer-storage-associatedtype-prior-art.md`;
    /// `Ordinal.Protocol.swift`: `Tagged<Tag, Ordinal>.Count ==
    /// Tagged<Tag, Cardinal>`). It is a distinct **nominal** type wrapping
    /// that representation, not a `typealias` — a unification typealias over
    /// an existing member type is a lint violation here (`[API-NAME-004]`):
    /// type unification must use the canonical type at every call site, so a
    /// distinct role earns a distinct nominal type, with the arithmetic
    /// delegated rather than duplicated.
    ///
    /// ## Why a bound is worth naming, distinctly from `count`
    ///
    /// `Buffer.`Protocol`.count` is a running tally that changes on every
    /// append/remove. `Buffer.Capacity` is the fixed ceiling a bounded
    /// discipline is constructed with and never exceeds —
    /// `Buffer.Storage.capacity` is a `let`, `count` is a `var`.
    @frozen
    public struct Capacity<Element: ~Copyable>: Equatable {
        /// The underlying bound, in the same representation `Buffer.Storage`
        /// and `Store.`Protocol`.capacity` already use.
        public let count: Index<Element>.Count

        /// Wraps an existing `Index<Element>.Count` as a capacity bound.
        @inlinable
        public init(_ count: Index<Element>.Count) {
            self.count = count
        }
    }
}
