extension SummarizedTree: SummarizedCollection {
        
    public var count: Int {
        summary.count
    }
    
    @inlinable
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

    public var startIndex: Index {
        if count == 0 {
            return endIndex
        }
        
        var cursor = Cursor(root: root, version: version)
        cursor.resetToStart()
        return .init(cursor: cursor)
    }
    
    public var endIndex: Index {
        var cursor = Cursor(root: root, version: version)
        cursor.resetToEnd()
        return .init(cursor: cursor)
    }

    public func distance(from start: Index, to end: Index) -> Int {
        start.ensureValid(with: end)
        start.ensureValid(in: self)
        return end.offset - start.offset
    }

    public func formIndex(after index: inout Index) {
        index.ensureValid(in: self)
        precondition(index.offset < count, "Attempt to advance out of collection bounds.")
        index.next()
    }

    public func index(after i: Index) -> Index {
        var newIndex = i
        formIndex(after: &newIndex)
        return newIndex
    }

    public func formIndex(before index: inout Index) {
        precondition(!isEmpty && index.offset != 0, "Attempt to advance out of collection bounds.")
        formIndex(&index, offsetBy: -1)
    }

    public func index(before i: Index) -> Index {
        var newIndex = i
        formIndex(before: &newIndex)
        return newIndex
    }

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

    public func formIndex<D>(_ i: inout Index, offsetBy distance: D) where D: CollectionDimension, D.Summary == Summary {
        i.ensureValid(in: self)
        
        let newIndex = D.get(i.summary) + distance
        
        if newIndex > D.get(summary) {
            i = endIndex
            return
        }
        
        i.seek(forward: distance)
    }

    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        var newIndex = i
        formIndex(&newIndex, offsetBy: distance)
        return newIndex
    }

    public func index<D>(
        _ i: Self.Index,
        offsetBy distance: D
    ) -> Index where D: CollectionDimension, D.Summary == Summary {
        var newIndex = i
        formIndex(&newIndex, offsetBy: distance)
        return newIndex
    }
    
    public func index<D>(at distance: D) -> Index where D: CollectionDimension, D.Summary == Summary {
        index(startIndex, offsetBy: distance)
    }

    public subscript(index: Index) -> Element {
        _read {
            index.ensureValid(in: self)
            yield index.element
        }
    }

}
