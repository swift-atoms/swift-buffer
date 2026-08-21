extension Buffer.Slice where Element: ~Copyable {

    @inlinable
    public var count: Int { _span.count }

    @inlinable
    public var isEmpty: Bool { _span.isEmpty }

    @_lifetime(borrow self)
    @inlinable
    public borrowing func span() -> Swift.Span<Element> {
        _span
    }

    @_lifetime(copy self)
    @inlinable
    public borrowing func extracting(_ bounds: Range<Int>) -> Buffer.Slice<Element> {
        Buffer.Slice(_span.extracting(bounds))
    }
}
