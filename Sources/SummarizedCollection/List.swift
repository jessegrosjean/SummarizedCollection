public struct ListContext<Element>: SummarizedTreeContext {
    
    public typealias Slot = UInt16
    public typealias Summary = ListSummary<Element>

    public var maintainsBackpointers: Bool { false }

    public init(root: TreeNode?, maintainBackpointersIfAble: Bool) {
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
