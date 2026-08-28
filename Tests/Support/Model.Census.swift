extension Model {

    public final class Census {
        public private(set) var born: [Int] = []
        public private(set) var died: [Int] = []

        public init() {}
    }
}

extension Model.Census {

    public func mint() -> Int {
        let serial = born.count
        born.append(serial)
        return serial
    }

    public func record(death serial: Int) {
        died.append(serial)
    }

    public var isExact: Bool {
        born.sorted() == died.sorted()
    }
}
