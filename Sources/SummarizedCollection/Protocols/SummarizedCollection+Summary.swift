public protocol CollectionSummary: AdditiveArithmetic {
    associatedtype Element
    
    static func summarize<C: BidirectionalCollection>(
        elements: C
    ) -> Self where C.Element == Element
        
    var count: Int { get }
}

extension CollectionSummary {

    @inlinable
    public static func summarize(element: Element) -> Self {
        summarize(elements: [element])
    }

}
