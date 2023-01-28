extension SummarizedTree {
    
    public struct SubSequence {

        public typealias Element = SummarizedTree.Element

        public var startIndex: Index
        public var endIndex: Index

        @usableFromInline
        var base: SummarizedTree

        @inlinable
        @inline(__always)
        init(base: SummarizedTree, bounds: Range<Index>? = nil) {
            self.base = base
            if let bounds {
                self.startIndex = bounds.lowerBound
                self.endIndex = bounds.upperBound
            } else {
                self.startIndex = self.base.startIndex
                self.endIndex = self.base.endIndex
            }
        }

        @inlinable
        func ensureValid() {
            base.ensureValid()
        }
        
    }

    @inlinable
    public subscript(bounds: Range<Int>) -> SubSequence {
        self[indexRange(from: bounds)]
    }

    @inlinable
    public subscript(bounds: Range<Self.Index>) -> SubSequence {
        return .init(base: self, bounds: bounds)
    }

}

extension SummarizedTree.SubSequence: Equatable {
    
    public static func == (lhs: SummarizedTree<Context>.SubSequence, rhs: SummarizedTree<Context>.SubSequence) -> Bool {
        lhs.base.root == rhs.base.root && lhs.startIndex.offset == rhs.startIndex.offset && lhs.endIndex.offset == rhs.endIndex.offset
    }
    
}

extension SummarizedTree.SubSequence: Sequence {

    public typealias Iterator = SummarizedTree.Iterator
    
    @inlinable
    @inline(__always)
    public func makeIterator() -> Iterator {
        return Iterator(tree: base, startIndex: startIndex, endIndex: endIndex)
    }

}

extension SummarizedTree.SubSequence: BidirectionalCollection {
    
    public typealias Index = SummarizedTree.Index
    public typealias SubSequence = Self
        
    @inlinable
    @inline(__always)
    public var count: Int {
        base.distance(from: startIndex, to: endIndex)
    }

    @inlinable
    @inline(__always)
    public func distance(from start: Index, to end: Index) -> Int {
        base.distance(from: start, to: end)
    }

    @inlinable
    @inline(__always)
    public func index(before i: Index) -> Index {
        base.index(before: i)
    }

    @inlinable
    @inline(__always)
    public func formIndex(before i: inout Index) {
        base.formIndex(before: &i)
    }

    @inlinable
    @inline(__always)
    public func index(after i: Index) -> Index {
        base.index(after: i)
    }
    
    @inlinable
    @inline(__always)
    public func formIndex(after i: inout Index) {
        base.formIndex(after: &i)
    }

    @inlinable
    @inline(__always)
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        base.index(i, offsetBy: distance)
    }
    
    @inlinable
    @inline(__always)
    public func formIndex(_ i: inout Index, offsetBy distance: Int) {
        base.formIndex(&i, offsetBy: distance)
    }
    
    @inlinable
    @inline(__always)
    public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
        base.index(i, offsetBy: distance, limitedBy: limit)
    }

    @inlinable
    @inline(__always)
    public func formIndex(_ i: inout Index, offsetBy distance: Int, limitedBy limit: Self.Index) -> Bool {
        base.formIndex(&i, offsetBy: distance, limitedBy: limit)
    }
    
    @inlinable
    @inline(__always)
    public subscript(position: Index) -> Element {
        _failEarlyRangeCheck(position, bounds: startIndex..<endIndex)
        return base[position]
    }
    
    @inlinable
    public subscript(bounds: Range<Index>) -> SubSequence {
        _failEarlyRangeCheck(bounds, bounds: startIndex..<endIndex)
        return base[bounds]
    }

    @inlinable
    @inline(__always)
    public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
        base._failEarlyRangeCheck(index, bounds: bounds)
    }
    
    @inlinable
    @inline(__always)
    public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {
        base._failEarlyRangeCheck(range, bounds: bounds)
    }

}

extension SummarizedTree.SubSequence: RangeReplaceableCollection {
    
    public init() {
        let empty = SummarizedTree()
        self.init(base: empty, bounds: empty.startIndex..<empty.endIndex)
    }
    
    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        // Don't know if this is right...
        // Deal with it when some code actually uses it...
        if true {
            fatalError()
        }
        
        let startOffset = startIndex.offset
        let endOffset = endIndex.offset
        let replaceStartOffset = subrange.lowerBound.offset
        let replaceEndOffset = subrange.upperBound.offset
        let replaceLength = replaceEndOffset - replaceStartOffset
        let changeInLength = newElements.count - replaceLength

        base.replaceSubrange(subrange, with: newElements)
        startIndex = base.index(startIndex, offsetBy: startOffset)
        endIndex = base.index(startIndex, offsetBy: endOffset + changeInLength)
    }
    
}
