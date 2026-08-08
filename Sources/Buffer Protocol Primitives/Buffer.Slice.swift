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

// MARK: - Buffer.Slice (TX-N1B)
//
// The canonical contiguous byte-chunk representation bound here: `IO.Byte.Channel`
// fixes exactly `Buffer.Slice<Byte>` as its handoff type. Framed/element channels
// use `IO.Channel<Element>` instead — `Buffer.Slice` is not a general element
// container, it is the one contiguous-byte-region view the byte channel owns.
//
// ## Why this shape, and on what basis
//
// `Buffer.Slice` is NOT the shipped `Collection.Slice.`Protocol`` — that protocol
// is deliberately `Escapable`, `Range`-based, `SubSequence == Self`
// (`collection-slice-escapable-index-toolchain-fallout.md`, standing DECISION,
// unchanged). `Buffer.Slice` is the separate, additive `~Escapable` scoped-view
// shape that same document names as a viable-but-unproductized frontier, with one
// explicitly untested step: generic-dispatch `~Escapable` bound threading over a
// real `~Copyable` conformer (as opposed to the narrower concrete-only spike it
// had already run).
//
// That step was run for this transaction as a standalone scratchpad spike
// (coordinator-authorized; no shared-repository mutation) BEFORE this file was
// written: a generic `Slice<Base: ~Copyable & ~Escapable>: ~Escapable` storing two
// `~Escapable` bound indices plus a borrow of a generic base compiled cleanly
// (Apple Swift 6.4, swiftlang-6.4.0.27.1) with a func producer (never a
// subscript — subscripts were REFUTED in the prior concrete spike for exactly
// this reason: `borrowing` is rejected on subscript params and a
// `~Escapable`-returning getter cannot thread the lifetime). The escape-rejection
// negative control reproduced the exact same diagnostic as the narrower prior
// experiment verbatim: "stored property … of 'Escapable'-conforming struct …
// has non-Escapable type". Verdict: TRIVIAL, not arc — the productized shape
// below follows directly.
//
// Rather than reinvent bound-index arithmetic that the spike used only to test
// toolchain viability, the concrete implementation below composes the
// ecosystem's ALREADY-SHIPPING contiguous-slicing primitive: `Swift.Span<Element>`
// (SE-0447) already vends bounds-checked, lifetime-safe sub-extraction via
// `.extracting(_:)` — the exact operation `Binary.Cursor.swift` already uses
// (`storage.span.extracting(readerIdx..<writerIdx)`,
// `swift-binary-cursor-primitives/Sources/Binary Cursor Primitives/Binary.Cursor.swift:454`).
// `Buffer.Slice` is a named, `Buffer`-namespaced wrapper around that operation,
// not a parallel index/bounds mechanism.
extension Buffer where S: ~Copyable {
    /// A `~Copyable`, `~Escapable`, Span-backed bounded read view over
    /// contiguous storage — the canonical contiguous byte-chunk representation
    /// for `IO.Byte.Channel`.
    @frozen
    public struct Slice<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        let _span: Swift.Span<Element>

        /// Wraps an already-bounded `Span` — the sole init path; every other
        /// producer (whole-region, sub-range) goes through a `func`, never a
        /// subscript, per the spike's refutation of subscript producers for
        /// `~Escapable` results.
        @_lifetime(copy span)
        @inlinable
        public init(_ span: consuming Swift.Span<Element>) {
            self._span = span
        }
    }
}
