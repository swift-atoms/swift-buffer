import Index
public import Store_Protocol

extension Buffer where S: ~Copyable {

    @frozen
    public struct Storage<Base: ~Copyable>: ~Copyable where Base: Store::Store.`Protocol` {

        public private(set) var base: Base

        public let capacity: Buffer.Capacity<Base.Element>

        public init(base: consuming Base) {
            self.capacity = Buffer.Capacity(base.capacity)
            self.base = base
        }
    }
}
