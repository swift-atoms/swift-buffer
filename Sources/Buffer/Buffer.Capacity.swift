public import Index
public import Ordinal

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

extension Buffer.Capacity where S: ~Copyable, Element: ~Copyable {

    @inlinable
    public static var zero: Self { Self(.zero) }
}
