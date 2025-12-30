extension Buffer.Aligned {
    /// Errors that can occur during aligned buffer operations.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The requested size is invalid (negative).
        case invalidSize

        /// The requested alignment is invalid (not a power of 2).
        case invalidAlignment

        /// Memory allocation failed.
        case allocationFailed
    }
}
