public struct ListContext<Element>: SummarizedTreeContext {

    public typealias Slot = UInt16
    public typealias Summary = ListSummary<Element>

    public static var maintainsBackpointers: Bool { false }

    @inlinable
    public subscript(parent node: TreeNode) -> TreeNode? {
        get { nil }
        set {}
    }

    @inlinable
    public mutating func mapElements<C>(_ elements: C, to leaf: TreeNode) where C : Collection, C.Element == Element {
    }
    
    @inlinable
    public mutating func unmapElements<C>(_ elements: C, from leaf: TreeNode) where C : Collection, C.Element == Element {
    }
    
    public init(root: TreeNode?) {
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
