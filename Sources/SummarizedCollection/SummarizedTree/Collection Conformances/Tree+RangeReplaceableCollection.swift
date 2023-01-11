extension SummarizedTree: RangeReplaceableCollection {
    
    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C: Collection, C.Element == Element {
        let start = subrange.lowerBound.offset
        let end = subrange.upperBound.offset
        let tail = split(end)
        _ = split(start)
        concat(.init(newElements))
        concat(tail)
    }
    
}
