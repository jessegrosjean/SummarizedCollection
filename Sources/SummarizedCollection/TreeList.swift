public struct TreeListContext<Element>: TreeContext {

    public typealias Slot = UInt16
    public typealias Summary = TreeListSummary<Element>

    public static var maintainsBackpointers: Bool { false }

    @inlinable
    public subscript(parent node: ContextNode) -> ContextNode? {
        get { nil }
        set {}
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

public struct TreeListSummary<Element>: CollectionSummary {
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

public typealias TreeList<Element> = SummarizedTree<TreeListContext<Element>>
