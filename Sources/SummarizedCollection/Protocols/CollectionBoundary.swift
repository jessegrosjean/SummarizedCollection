public protocol CollectionBoundary {
    
    associatedtype Element

    static var canFragment: Bool { get }

    static func isBoundary<C>(
        at i: C.Index,
        elements: C
    ) -> Bool
    where
        C: BidirectionalCollection, C.Element == Element
    
    static func boundary<C>(
        before i: C.Index,
        elements: C
    ) -> C.Index?
    where
        C: BidirectionalCollection, C.Element == Element
    
    static func boundary<C>(
        after i: C.Index,
        elements: C
    ) -> C.Index?
    where
        C: BidirectionalCollection, C.Element == Element
}

extension CollectionBoundary {

    @inlinable
    public static var canFragment: Bool {
        false
    }
    
    @inlinable
    public static func boundary<C>(
        before i: C.Index,
        elements: C
    ) -> C.Index?
    where
        C: BidirectionalCollection, C.Element == Element
    {
        let startIndex = elements.startIndex
        var i = i
        while i != startIndex {
            elements.formIndex(before: &i)
            if isBoundary(at: i, elements: elements) {
                return i
            }
        }
        return nil    }

    @inlinable
    public static func boundary<C>(
        after i: C.Index,
        elements: C
    ) -> C.Index?
    where
        C: BidirectionalCollection, C.Element == Element
    {
        let endIndex = elements.endIndex
        var i = i
        while i != endIndex {
            elements.formIndex(after: &i)
            if isBoundary(at: i, elements: elements) {
                return i
            }
        }
        return nil
    }

}

extension BidirectionalCollection {

    @inlinable
    public func isBoundary<B>(_ type: B.Type, at i: Index) -> Bool
        where B: CollectionBoundary, B.Element == Element
    {
        B.isBoundary(at: i, elements: self)
    }

    @inlinable
    public func boundary<B>(_ type: B.Type, before i: Index) -> Index?
        where B: CollectionBoundary, B.Element == Element
    {
        B.boundary(before: i, elements: self)
    }

    @inlinable
    public func boundary<B>(_ type: B.Type, after i: Index) -> Index?
        where B: CollectionBoundary, B.Element == Element
    {
        B.boundary(after: i, elements: self)
    }
    
}
