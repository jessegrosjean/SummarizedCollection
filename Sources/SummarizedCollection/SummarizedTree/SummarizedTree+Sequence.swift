extension SummarizedTree: Sequence {
        
    @inlinable
    @inline(__always)
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        var cursor = cursor()
        while let leaf = cursor.nextLeaf() {
            for each in leaf {
                try body(each)
            }
        }
    }

    @inlinable
    @inline(__always)
    public __consuming func makeIterator() -> Iterator {
        return Iterator(tree: self)
    }

    public struct Iterator: IteratorProtocol {

        @usableFromInline
        let retained: SummarizedTree

        @usableFromInline
        var cursor: Cursor

        @usableFromInline
        var index: Int

        @usableFromInline
        var endIndex: Int

        @usableFromInline
        var leafIterator: IndexingIterator<ElementsBuffer>?
        
        @inlinable
        init(tree: __owned SummarizedTree, startIndex: __owned Index? = nil, endIndex: __owned Index? = nil) {
            self.retained = tree
            self.cursor = startIndex?.cursor ?? tree.cursor()
            self.index = cursor.index
            self.endIndex = endIndex?.offset ?? tree.count
            self.leafIterator = nil
            
            if cursor.isSeeking {
                leafIterator = cursor.leaf().makeIterator()
                var offset = cursor.position.offset
                while offset > 0 {
                    _ = leafIterator?.next()
                    offset -= 1
                }
            }
        }
        
        @inlinable
        public mutating func next() -> Element? {
            while true {
                if index == endIndex {
                    return nil
                }
                
                if let element = leafIterator?.next() {
                    index += 1
                    return element
                }
                
                leafIterator = cursor.nextLeaf()?.makeIterator()
                
                if leafIterator == nil {
                    return nil
                }
            }
        }
    }
    
}
