public struct ListContext<Element>: SummarizedTreeContext {

    public typealias Slot = UInt16
    public typealias Summary = ListSummary<Element>
    
    @inlinable
    public init() {}

}

public struct ListSummary<Element>: CollectionSummary {
    public var count: Int
    
    @inlinable
    public init(count: Int) {
        self.count = count
    }
    
    @inlinable
    public static var zero: Self {
        .init(count: 0)
    }
    
    @inlinable
    public static func summarize<C>(elements: C) -> Self where C : BidirectionalCollection, C.Element == Element {
        .init(count: elements.count)
    }

    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(count: lhs.count + rhs.count)
    }
    
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(count: lhs.count - rhs.count)
    }
}

public typealias List<Element> = SummarizedTree<ListContext<Element>>
