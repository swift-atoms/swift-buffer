extension Buffer where S: ~Copyable {

    @frozen
    public struct Slice<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        let _span: Swift.Span<Element>

        @_lifetime(copy span)
        @inlinable
        public init(_ span: consuming Swift.Span<Element>) {
            self._span = span
        }
    }
}
