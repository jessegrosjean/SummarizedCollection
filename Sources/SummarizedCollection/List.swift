/*public struct ListContext<Element>: SummarizedTreeContextProtocol {

    public typealias Summary = ListSummary<Element>
    
    @inlinable
    public subscript(parent node: ContextNode) -> ContextNode? {
        get { node.parent }
        set { node.parent = newValue }
    }

    @inlinable
    public mutating func mapElements<C>(_ elements: C, to leaf: ContextNode) where C : Collection, C.Element == Element {
    }
    
    @inlinable
    public mutating func unmapElements<C>(_ elements: C, from leaf: ContextNode) where C : Collection, C.Element == Element {
    }
    
    public init(root: ContextNode?) {
    }

}

public struct ListSummary<Element>: CollectionSummary {
    public var count: Int
    
    public static var zero: Self {
        .init(count: 0)
    }
    
    public static func summarize<C>(elements: C) -> Self where C : BidirectionalCollection, C.Element == Element {
        .init(count: elements.count)
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(count: lhs.count + rhs.count)
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(count: lhs.count - rhs.count)
    }
}

public typealias List<Element> = SummarizedTree<ListContext<Element>>
*/
