public import Cardinal
import Ordinal
public import Tagged

extension Buffer.Capacity: Swift.Comparable {

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.count < rhs.count
    }
}
