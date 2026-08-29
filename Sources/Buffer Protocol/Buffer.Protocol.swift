public import Buffer
public import Cardinal_Carrier
public import Index
public import Ordinal_Protocol
public import Tagged

public protocol __BufferProtocol: ~Copyable, ~Escapable {

    associatedtype Element: ~Copyable

    var count: Index<Element>.Count { get }

    var isEmpty: Bool { get }
}

extension __BufferProtocol where Self: ~Copyable & ~Escapable {

    @inlinable
    public var isEmpty: Bool { count == .zero }
}

extension Buffer where S: ~Copyable {

    public typealias `Protocol` = __BufferProtocol
}
