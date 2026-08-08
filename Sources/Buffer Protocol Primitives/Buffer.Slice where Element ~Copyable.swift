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

extension Buffer.Slice where Element: ~Copyable {
    /// The number of elements in this slice.
    @inlinable
    public var count: Int { _span.count }

    /// Whether this slice is empty (the zero-length edge case named in
    /// TX-N1B's controls).
    @inlinable
    public var isEmpty: Bool { _span.isEmpty }

    /// Borrowing access to the underlying `Span` — the read capability this
    /// type exists to carry.
    @_lifetime(borrow self)
    @inlinable
    public borrowing func span() -> Swift.Span<Element> {
        _span
    }

    /// A bounds-checked sub-slice. A `func`, never a subscript — the
    /// producer-is-a-func discipline the spike established for
    /// `~Escapable`-returning bound operations.
    @_lifetime(copy self)
    @inlinable
    public borrowing func extracting(_ bounds: Range<Int>) -> Buffer.Slice<Element> {
        Buffer.Slice(_span.extracting(bounds))
    }
}
