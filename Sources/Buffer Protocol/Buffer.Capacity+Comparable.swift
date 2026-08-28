extension Buffer.Capacity: Comparable {

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.count < rhs.count
    }
}

extension Buffer.Capacity {

    @inlinable
    public static var zero: Self { Self(.zero) }
}
