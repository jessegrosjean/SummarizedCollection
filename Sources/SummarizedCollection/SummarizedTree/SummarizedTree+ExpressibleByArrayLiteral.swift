extension SummarizedTree: ExpressibleByArrayLiteral {
    
    @inlinable
    @inline(__always)
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
    
}
