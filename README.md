# swift-buffer

Use this package when you are building a container on top of a `Store.Protocol` conformer and need the vocabulary every buffer shares: a typed capacity, a count of initialized elements, a wrapper that owns the store, and a borrowed view over contiguous elements. Start from `Buffer<S>.Storage<Base>` to own a store, `Buffer<S>.Protocol` to report a count, `Buffer<S>.Capacity<Element>` for capacities and `Buffer<S>.Slice<Element>` to lend out a `Swift.Span<Element>`. The package holds no elements and has no growth, eviction or indexing policy; when raw slots are all you need, use a `Store.Protocol` conformer from `swift-store` directly. `S` only separates one family of buffer types from another and carries no behaviour; pass `Never` when nothing needs separating.

## Laws

- `Buffer<S>.Storage<Base>.capacity` is read from the base once, in `init(base:)`, and stored; it is never re-read from the base.
- A type that conforms to both `Store.Protocol` and `Buffer<S>.Protocol` keeps `count` in step with its initialized slots: zero when fresh, one more after `initialize(at:to:)`, unchanged after a subscript write, one fewer after `move(at:)`, and `capacity` unchanged by all of these. `Seam.Ledger.violations(makeEmpty:element:)` in `Buffer Test Support` checks a conformer against these laws and returns one message per broken law, or a single precondition message when the fresh value's capacity is below two.
