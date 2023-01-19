extension SummarizedTree: RangeReplaceableCollection {
    
    @inlinable
    public mutating func append(_ newElement: Context.Element) {
        replace(summary.count..<summary.count, with: [newElement])
    }
    
    @inlinable
    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        invalidateIndices()
        root = .init()
    }
    
    @inlinable
    public mutating func removeSubrange(_ bounds: Range<Index>) {
        replace(bounds.lowerBound.offset..<bounds.upperBound.offset, with: [])
    }

    @inlinable
    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C: Collection, C.Element == Element {
        replace(subrange.lowerBound.offset..<subrange.upperBound.offset, with: ContiguousArray(newElements))
    }
    
}
