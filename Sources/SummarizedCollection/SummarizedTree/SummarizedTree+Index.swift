extension SummarizedTree {
    
    public struct Index {
        
        @usableFromInline
        var cursor: Cursor
        
        @inlinable
        init(cursor: Cursor) {
            self.cursor = cursor
        }
        
        @inlinable
        var offset: Int {
            cursor.index
        }

        @inlinable
        var summary: Summary {
            cursor.summary
        }

        @inlinable
        var element: Element {
            cursor.uncheckedElement()
        }

        @inlinable
        mutating func previous() {
            _ = cursor.prevElement()
        }

        @inlinable
        mutating func next() {
            _ = cursor.nextElement()
        }

        @inlinable
        mutating func seek<D>(forward dimension: D) where D: CollectionDimension, D.Summary == Summary {
            _ = cursor.seek(forward: dimension)
        }
        
        @inlinable
        func ensureValid(in tree: SummarizedTree) {
            cursor.ensureValid(for: tree.root, version: tree.version)
        }
        
        @inlinable
        func ensureValid(with index: Index) {
            cursor.ensureValid(with: index.cursor)
        }
    }

}

extension SummarizedTree.Index: Comparable {
    
    @inlinable
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.cursor == rhs.cursor
    }
    
    @inlinable
    public static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.cursor < rhs.cursor
    }
    
}
