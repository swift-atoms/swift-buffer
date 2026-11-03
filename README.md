# swift-buffer

Use `Buffer` when you are building a container on top of a `Store` and need the shared vocabulary every buffer speaks: a typed capacity, a count of initialized elements, storage that fixes its capacity when it is wrapped, and a borrowed view over contiguous elements. It holds no elements itself and has no growth or indexing policy; use a `Store` conformer directly when raw slots are all you need.

## Model

`Buffer<S>` is an empty namespace; `S` (which may be `~Copyable`, and is `Never` when nothing distinguishes it) only separates one family of buffer types from another. Everything below is nested in it and accepts `~Copyable` elements.

- `Buffer.Protocol`: a `~Copyable`, `~Escapable` protocol for anything that reports `count` as an `Index<Element>.Count`. `isEmpty` defaults to `count == .zero`.
- `Buffer.Capacity<Element>`: a value wrapping an `Index<Element>.Count`. It is `Equatable`, `Comparable` by its count, and has `.zero`.
- `Buffer.Storage<Base>`: a `~Copyable` wrapper that consumes a `Store.Protocol` conformer in `init(base:)`. `base` is readable but not settable from outside; `capacity` is a `Buffer.Capacity<Base.Element>`.
- `Buffer.Slice<Element>`: a `~Copyable`, `~Escapable` view over a `Span<Element>` that never outlives that span. `count` and `isEmpty` read it, `span()` borrows the elements, and `extracting(_:)` returns a narrower `Buffer.Slice` over an `Int` range with the same lifetime.

## Laws

- `Buffer.Storage.capacity` is read from the base once, at construction, and stored. Later changes to the capacity the source value reports do not reach it.
- A capacity of zero and an empty slice are valid; `extracting(0..<count)` keeps every element, and `extracting(n..<n)` is empty.
- A type that conforms to both `Store.Protocol` and `Buffer.Protocol` must keep `count` in step with its slots: zero when fresh, one more after `initialize(at:to:)`, unchanged after a subscript write, one fewer after `move(at:)`, and capacity unchanged by all of these. `Seam.Ledger.violations(makeEmpty:element:)` in `Buffer Test Support` checks this for your conformer and returns one message per broken law; it needs a fresh value with capacity of at least two.

## Example

```swift
let one = Buffer<Never>.Capacity<Int>(1)
let two = Buffer<Never>.Capacity<Int>(2)
one < two                                   // true

let values: [UInt8] = [10, 20, 30, 40, 50]
values.withUnsafeBufferPointer { buffer in
    let slice = Buffer<Never>.Slice(unsafe Span(_unsafeElements: buffer))
    slice.extracting(1..<4).count           // 3
}
```
