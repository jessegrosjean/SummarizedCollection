public struct CollectionIndexDimension<Summary: CollectionSummary> {
    
    public var rawValue: Int
        
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }

}

extension CollectionIndexDimension: CollectionDimension {
    
    public typealias Element = Summary.Element
    
    public static func get(_ summary: Summary) -> Self {
        .init(summary.count)
    }
    
    public static func measure<C>(_ elements: C) -> Self where C : BidirectionalCollection, C.Element == Element {
        .init(elements.count)
    }
        
}

extension CollectionIndexDimension {
    
    public static func isBoundary<C>(at i: C.Index, elements: C) -> Bool
        where
            C : BidirectionalCollection, C.Element == Element
    {
        i <= elements.endIndex
    }
    
    public static func index<C>(
        to: Self,
        summary: Summary?,
        elements: C
    ) -> C.Index?
        where
            C: BidirectionalCollection, C.Element == Element
    {
        elements.index(elements.startIndex, offsetBy: to.rawValue)
    }
    
}
