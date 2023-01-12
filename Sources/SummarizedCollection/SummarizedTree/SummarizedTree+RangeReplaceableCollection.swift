extension SummarizedTree: RangeReplaceableCollection {
    
    @inlinable
    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        invalidateIndices()
        root = .init()
    }
    
    @inlinable
    public mutating func removeSubrange(_ bounds: Range<Index>) {
        guard bounds.lowerBound <= endIndex else { preconditionFailure("Index out of bounds.") }
        guard bounds.upperBound <= endIndex else { preconditionFailure("Index out of bounds.") }
        
        let start = bounds.lowerBound.offset
        let end = bounds.upperBound.offset
        let tail = split(end)
        _ = split(start)
        concat(tail)
    }

    @inlinable
    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C: Collection, C.Element == Element {
        let start = subrange.lowerBound.offset
        let end = subrange.upperBound.offset
        let tail = split(end)
        _ = split(start)
        concat(.init(newElements))
        concat(tail)
    }
    
}
