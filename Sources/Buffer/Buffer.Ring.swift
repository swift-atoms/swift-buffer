// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-buffer open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-buffer project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Buffer {
    /// Bounded circular buffer with optional storage.
    ///
    /// O(1) enqueue/dequeue with fixed capacity limit.
    ///
    /// ## Thread Safety
    /// Not thread-safe. External synchronization required for concurrent access.
    ///
    /// ## Memory Management
    /// Uses optional storage to avoid needing placeholder elements.
    /// Empty slots are nil, which allows ARC to release element resources.
    ///
    /// ## Invariants
    /// - `count <= capacity` always holds
    /// - `enqueue` returns false when full (does not grow)
    /// - `dequeue` returns nil when empty
    public struct Ring<Element> {
        @usableFromInline
        var storage: [Element?]

        @usableFromInline
        var head: Int = 0

        @usableFromInline
        var tail: Int = 0

        @usableFromInline
        var _count: Int = 0

        /// The fixed capacity of the buffer.
        public let capacity: Int

        /// Creates a ring buffer with the given capacity.
        ///
        /// - Parameter capacity: Maximum number of elements (minimum 1).
        @inlinable
        public init(capacity: Int) {
            self.capacity = max(capacity, 1)
            self.storage = [Element?](repeating: nil, count: self.capacity)
        }

        /// The current number of elements in the buffer.
        @inlinable
        public var count: Int { _count }

        /// Whether the buffer is empty.
        @inlinable
        public var isEmpty: Bool { _count == 0 }

        /// Whether the buffer is at capacity.
        @inlinable
        public var isFull: Bool { _count >= capacity }
    }
}

// MARK: - Enqueue / Dequeue

extension Buffer.Ring {
    /// Enqueue an element at the tail.
    ///
    /// - Parameter element: The element to enqueue.
    /// - Returns: `true` if enqueued, `false` if buffer is full.
    @inlinable
    public mutating func enqueue(_ element: Element) -> Bool {
        guard !isFull else { return false }
        storage[tail] = element
        tail = (tail + 1) % capacity
        _count += 1
        return true
    }

    /// Enqueue an element, trapping if full.
    ///
    /// Use when the caller has ensured capacity is available.
    @inlinable
    public mutating func enqueueUnchecked(_ element: Element) {
        precondition(!isFull, "Ring buffer is full")
        storage[tail] = element
        tail = (tail + 1) % capacity
        _count += 1
    }

    /// Dequeue an element from the head.
    ///
    /// - Returns: The dequeued element, or `nil` if empty.
    @inlinable
    public mutating func dequeue() -> Element? {
        guard _count > 0 else { return nil }
        let element = storage[head]
        storage[head] = nil
        head = (head + 1) % capacity
        _count -= 1
        return element
    }

    /// Dequeue an element, trapping if empty.
    ///
    /// Use when the caller has ensured an element is available.
    @inlinable
    public mutating func dequeueUnchecked() -> Element {
        precondition(_count > 0, "Ring buffer is empty")
        guard let element = storage[head] else {
            preconditionFailure("Ring buffer invariant violated: count=\(_count) but head slot is nil")
        }
        storage[head] = nil
        head = (head + 1) % capacity
        _count -= 1
        return element
    }
}

// MARK: - Drain

extension Buffer.Ring {
    /// Drain all elements from the buffer.
    ///
    /// - Returns: Array of all elements in FIFO order.
    @inlinable
    public mutating func drain() -> [Element] {
        var result: [Element] = []
        result.reserveCapacity(_count)
        while let element = dequeue() {
            result.append(element)
        }
        return result
    }

    /// Remove all elements without returning them.
    @inlinable
    public mutating func removeAll() {
        while _count > 0 {
            storage[head] = nil
            head = (head + 1) % capacity
            _count -= 1
        }
    }
}

// MARK: - Subscript Access

extension Buffer.Ring {
    /// Access an element by logical index (0 = head).
    ///
    /// - Parameter logicalIndex: Index from the head (0..<count).
    /// - Returns: The element at that position, or `nil` if out of bounds.
    @inlinable
    public subscript(logicalIndex: Int) -> Element? {
        get {
            guard logicalIndex >= 0, logicalIndex < _count else { return nil }
            return storage[(head + logicalIndex) % capacity]
        }
        set {
            guard logicalIndex >= 0, logicalIndex < _count else { return }
            storage[(head + logicalIndex) % capacity] = newValue
        }
    }
}

// MARK: - Iteration

extension Buffer.Ring {
    /// Iterate over all elements in FIFO order.
    @inlinable
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        for i in 0..<_count {
            if let element = storage[(head + i) % capacity] {
                try body(element)
            }
        }
    }

    /// Find the first element matching a predicate.
    @inlinable
    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        for i in 0..<_count {
            if let element = storage[(head + i) % capacity], try predicate(element) {
                return element
            }
        }
        return nil
    }

    /// Find the index of the first element matching a predicate.
    @inlinable
    public func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        for i in 0..<_count {
            if let element = storage[(head + i) % capacity], try predicate(element) {
                return i
            }
        }
        return nil
    }
}

// MARK: - Conditional Conformances

extension Buffer.Ring: Sendable where Element: Sendable {}
extension Buffer.Ring: Equatable where Element: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for i in 0..<lhs.count {
            if lhs[i] != rhs[i] { return false }
        }
        return true
    }
}
