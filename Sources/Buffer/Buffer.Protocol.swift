public import Cardinal
public import Index
public import Ordinal
public import Tagged

extension Buffer where S: ~Copyable {

    public typealias `Protocol` = __BufferProtocol
}

public protocol __BufferProtocol: ~Copyable, ~Escapable {

    associatedtype Element: ~Copyable

    var count: Index<Element>.Count { get }

    var isEmpty: Bool { get }
}

extension Buffer.`Protocol` where Self: ~Copyable & ~Escapable {

    @inlinable
    public var isEmpty: Bool { count == .zero }
}


