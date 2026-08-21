extension Model {

    public enum Element {}
}

extension Model.Element {

    public struct Tracked: ~Copyable {
        public let id: Int
        public let group: Int
        public let serial: Int
        private let census: Model.Census

        public init(id: Int, group: Int = 0, census: Model.Census) {
            self.id = id
            self.group = group
            self.census = census
            self.serial = census.mint()
        }

        deinit {
            census.record(death: serial)
        }
    }
}
