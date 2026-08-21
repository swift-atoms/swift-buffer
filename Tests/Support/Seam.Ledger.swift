public import Buffer_Protocol_Primitives

import Index_Primitives
public import Store_Protocol_Primitives

extension Seam {

    public enum Ledger {}
}

extension Seam.Ledger {

    public static func violations<S: Store.`Protocol` & Buffer.`Protocol` & ~Copyable>(
        makeEmpty: () -> S,
        element: (Int) -> S.Element
    ) -> [String] {
        var found: [String] = []
        var column = makeEmpty()

        let zero = Index<S.Element>.Count(UInt(0))
        let one = Index<S.Element>.Count(UInt(1))
        let two = Index<S.Element>.Count(UInt(2))
        let slot0: Index<S.Element> = 0
        let slot1: Index<S.Element> = 1

        guard column.capacity >= two else {
            return ["precondition: makeEmpty() must provide capacity >= 2 (got \(column.capacity))"]
        }
        if column.count != zero {
            found.append("law 0: a fresh column must report count == 0 (got \(column.count))")
        }
        let capacityBefore = column.capacity

        column.initialize(at: slot0, to: element(0))
        if column.count != one {
            found.append("law 1: initialize(at:to:) must increment count by one (got \(column.count), expected 1)")
        }
        column.initialize(at: slot1, to: element(1))
        if column.count != two {
            found.append("law 1: initialize(at:to:) must increment count by one (got \(column.count), expected 2)")
        }

        column[slot0] = element(2)
        if column.count != two {
            found.append("law 2: the element subscript must leave count unchanged (got \(column.count), expected 2)")
        }

        _ = column.move(at: slot1)
        if column.count != one {
            found.append("law 3: move(at:) must decrement count by one (got \(column.count), expected 1)")
        }
        _ = column.move(at: slot0)
        if column.count != zero {
            found.append("law 3: move(at:) must decrement count by one (got \(column.count), expected 0)")
        }

        if column.capacity != capacityBefore {
            found.append("law 4: seam element ops must not change capacity (was \(capacityBefore), now \(column.capacity))")
        }
        return found
    }
}
