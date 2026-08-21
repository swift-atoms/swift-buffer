public import Index_Primitives

extension Buffer where S: ~Copyable {

    @frozen
    public struct Capacity<Element: ~Copyable>: Equatable {

        public let count: Index<Element>.Count

        @inlinable
        public init(_ count: Index<Element>.Count) {
            self.count = count
        }
    }
}
