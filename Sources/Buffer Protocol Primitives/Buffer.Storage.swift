import Index_Primitives
public import Store_Protocol_Primitives

extension Buffer where S: ~Copyable {

    @frozen
    public struct Storage<Base: ~Copyable>: ~Copyable where Base: Store.`Protocol` {

        public private(set) var base: Base

        public let capacity: Buffer.Capacity<Base.Element>

        public init(base: consuming Base) {
            self.capacity = Buffer.Capacity(base.capacity)
            self.base = base
        }
    }
}
