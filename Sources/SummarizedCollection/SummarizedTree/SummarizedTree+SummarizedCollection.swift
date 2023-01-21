extension SummarizedTree: SummarizedCollection {
        
    @inlinable
    @inline(__always)
    public var count: Int {
        summary.count
    }
    
    @inlinable
    @inline(__always)
    public var isEmpty: Bool {
        root.summary.count == 0
    }

    @inlinable
    @inline(__always)
    public var summary: Summary {
        root.summary
    }
    
    @inlinable
    public func summary(at index: Index) -> Summary {
        index.summary
    }

    @inlinable
    public func pointToDimension<B, D>(
        point: CollectionPoint<B, D>
    ) -> D?
    where
        B.Summary == Summary,
        D.Summary == Summary
    {
        var c = cursor(at: point.base)
        return c.extent() + point.offset
    }
    
    public func dimensionToPoint<D, B>(
        _ dimension: D
    ) -> CollectionPoint<B, D>?
    where
        B.Summary == Summary,
        D.Summary == Summary
    {
        var c = cursor(at: dimension)
        var point: CollectionPoint<B, D> = c.point()
        point.offset += (dimension - c.extent())
        return point
    }

    @inlinable
    public var startIndex: Index {
        if count == 0 {
            return endIndex
        }
        
        var cursor = Cursor(root: root.unmanagedNode, version: version)
        cursor.resetToStart()
        return .init(cursor: cursor)
    }
    
    @inlinable
    public var endIndex: Index {
        var cursor = Cursor(root: root.unmanagedNode, version: version)
        cursor.resetToEnd()
        return .init(cursor: cursor)
    }

    @inlinable
    public func distance(from start: Index, to end: Index) -> Int {
        start.ensureValid(with: end)
        start.ensureValid(in: self)
        return end.offset - start.offset
    }

    @inlinable
    public func index(after i: Index) -> Index {
        var newIndex = i
        formIndex(after: &newIndex)
        return newIndex
    }

    @inlinable
    public func formIndex(after index: inout Index) {
        index.ensureValid(in: self)
        precondition(index.offset < count, "Attempt to advance out of collection bounds.")
        index.next()
    }

    @inlinable
    public func index(before i: Index) -> Index {
        var newIndex = i
        formIndex(before: &newIndex)
        return newIndex
    }

    @inlinable
    public func formIndex(before index: inout Index) {
        precondition(!isEmpty && index.offset != 0, "Attempt to advance out of collection bounds.")
        index.previous()
    }

    @inlinable
    public func formIndex(_ i: inout Index, offsetBy distance: Int) {
        i.ensureValid(in: self)
        
        let newIndex = i.offset + distance
        
        precondition(0 <= newIndex && newIndex <= count, "Attempt to advance out of collection bounds.")
        
        if newIndex == count {
            i = endIndex
            return
        }
        
        i.seek(forward: IndexDimension(distance))
    }

    @inlinable
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        var newIndex = i
        formIndex(&newIndex, offsetBy: distance)
        return newIndex
    }

    @inlinable
    public func index<D>(
        _ i: Self.Index,
        offsetBy distance: D
    ) -> Index where D: CollectionDimension, D.Summary == Summary {
        var newIndex = i
        formIndex(&newIndex, offsetBy: distance)
        return newIndex
    }
    

    @inlinable
    public func formIndex<D>(_ i: inout Index, offsetBy distance: D) where D: CollectionDimension, D.Summary == Summary {
        i.ensureValid(in: self)
        
        let newIndex = D.get(i.summary) + distance
        
        if newIndex > D.get(summary) {
            i = endIndex
            return
        }
        
        i.seek(forward: distance)
    }

    @inlinable
    public func index<D>(at distance: D) -> Index where D: CollectionDimension, D.Summary == Summary {
        index(startIndex, offsetBy: distance)
    }

    @inlinable
    @inline(__always)
    public subscript(index: Index) -> Element {
        _read {
            index.ensureValid(in: self)
            yield index.element
        }
    }

}
