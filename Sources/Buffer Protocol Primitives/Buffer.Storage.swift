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

import Index_Primitives
public import Store_Protocol_Primitives

// MARK: - Buffer.Storage (TX-N1B)

extension Buffer where S: ~Copyable {
    /// The occupancy-layer wrapper around a physical `Store.`Protocol``
    /// substrate.
    ///
    /// ## HAS-A, never IS-A
    ///
    /// `Buffer.Storage` composes a `Store.`Protocol`` conformer; it does not
    /// refine it. This follows the standing decision that `Buffer.`Protocol``
    /// does not refine `Storage.`Protocol`` — a buffer *has-a* storage, it is
    /// not a *kind-of* storage (`Buffer.Protocol.swift`, "Orthogonal to
    /// Storage.Protocol"; `buffer-storage-associatedtype-prior-art.md`,
    /// APPROVED Tier-3 `cross-layer-capability-protocol-model.md` §3.4).
    /// `Buffer.Storage` is the named occupancy-layer type that carries out
    /// that composition, so a discipline can hold "a storage" as a typed
    /// field instead of ad-hoc-wrapping `some Store.`Protocol`` at each call
    /// site.
    ///
    /// ## Occupancy layer, not a reintroduced allocator
    ///
    /// `Buffer.*` is exactly the logical occupancy layer over physical
    /// storage; raw byte/slot regions are owned by `Memory`/`Storage`, never
    /// by `Buffer` (`buffer-namespace-membership-occupancy-vs-region.md`,
    /// principal directives 1–2). The historical `Buffer.Aligned` /
    /// `Buffer.Unbounded` allocator shape has already migrated out of this
    /// package (verified empirically: no `Aligned`/`Unbounded` source remains
    /// here as of this transaction) — `Buffer.Storage` does not resurrect
    /// that shape. It borrows/owns a `Base: Store.`Protocol`` region; it does
    /// not allocate raw memory itself.
    ///
    /// ## Capacity, not count
    ///
    /// `capacity` is fixed at construction from the wrapped store's own
    /// `Store.`Protocol`.capacity` and never changes; live occupancy
    /// (`count`) is a `Buffer.`Protocol`` concern for the discipline built on
    /// top of this storage, not a `Buffer.Storage` field — `Buffer.Storage`
    /// only knows the bound, not which slots within it are populated.
    @frozen
    public struct Storage<Base: ~Copyable>: ~Copyable where Base: Store.`Protocol` {
        /// The wrapped physical element-store substrate.
        public private(set) var base: Base

        /// The fixed upper bound of this storage, read once from `base` at
        /// construction (`Buffer.Capacity<Base.Element>` — a
        /// generic-instantiation alias onto `Index<Base.Element>.Count`).
        public let capacity: Buffer.Capacity<Base.Element>

        /// Wraps `base`, capturing its capacity at the moment of composition.
        public init(base: consuming Base) {
            self.capacity = Buffer.Capacity(base.capacity)
            self.base = base
        }
    }
}
