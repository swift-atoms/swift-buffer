public import Cardinal
import Ordinal
public import Tagged

extension Buffer.Capacity: Swift.Comparable where S: ~Copyable, Element: ~Copyable {

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.count < rhs.count
    }
}
