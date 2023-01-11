public struct CollectionPoint<
    B: CollectionDimension,
    O: CollectionDimension
> where B.Summary == O.Summary {
    public var base: B
    public var offset: O
}

extension CollectionPoint: Comparable {
    
    public static func < (lhs: CollectionPoint<B, O>, rhs: CollectionPoint<B, O>) -> Bool {
        if lhs.base == rhs.base {
            return lhs.offset < rhs.offset
        }
        return lhs.base < rhs.base
    }
    
}

public protocol CollectionDimension: CollectionBoundary, AdditiveArithmetic, Comparable {
    associatedtype Summary: CollectionSummary where Summary.Element == Element

    static func get(_ summary: Summary) -> Self
    
    static func measure<C>(_ elements: C) -> Self
    where
        C: BidirectionalCollection, C.Element == Element

    static func index<C>(
        to: Self,
        summary: Summary?,
        elements: C
    ) -> C.Index?
    where
        C: BidirectionalCollection, C.Element == Element
    
    static func point<O, C>(from dimension: O, summary: Summary?, elements: C) -> CollectionPoint<Self, O>
    where
        O: CollectionDimension, O.Summary == Summary,
        C: BidirectionalCollection, C.Element == Element
    
    var rawValue: Int { get set }
    
    init(_ rawValue: Int)
}

extension CollectionDimension {
    
    public static var zero: Self {
        .init(0)
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(lhs.rawValue + rhs.rawValue)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(lhs.rawValue - rhs.rawValue)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func isBoundary<C>(at i: C.Index, elements: C) -> Bool
        where
            C : BidirectionalCollection, Element == C.Element
    {
        if i == elements.startIndex {
            return true
        }

        if i == elements.endIndex {
            return true
        }
            
        let prevIndex = elements.index(before: i)
        let prev = measure(elements[elements.startIndex..<prevIndex])
        let current = measure(elements[elements.startIndex..<i])
        return prev != current
    }
    
    /// Map this dimension into item dimension.
    ///
    /// Measures given items in this dimension until total is >= given target
    /// value. Returns item index of item where that threshhold is met.
    public static func index<C>(
        to: Self,
        summary: Summary?,
        elements: C
    ) -> C.Index?
        where
            C: BidirectionalCollection, C.Element == Element
    {
        if let summary = summary, .get(summary) < to {
            return nil
        }
        
        var total: Self = .zero
        if to <= total {
            return elements.startIndex
        }
        
        var prev = elements.startIndex
        while let i = boundary(after: prev, elements: elements) {
            total += .measure(elements[prev..<i])
            if to < total {
                return prev
            } else if to == total {
                return i
            }
            prev = i
        }
        
        return nil
    }
    
    /// Map index dimension (offset) to this dimension (base).
    ///
    /// Returned value is a point containing this dimension's value (base) at
    /// the given index and an (offset) in index dimension. Offset is needed
    /// because given index might not lie on boundary of this base dimension.
    public static func point<O, C>(
        from offset: O,
        summary: Summary?,
        elements: C
    ) -> CollectionPoint<Self, O>
        where
            O: CollectionDimension, O.Summary == Summary,
            C: BidirectionalCollection, C.Element == Element
    {
        if let summary = summary, Self.get(summary) == .zero {
            return .init(base: .zero, offset: offset)
        }
        
        let index = O.index(
            to: offset,
            summary: summary,
            elements: elements
        )!
        
        if Self.isBoundary(at: index, elements: elements) {
            let slice = elements[elements.startIndex..<index]
            return .init(
                base: .measure(slice),
                offset: offset - O.measure(slice)
            )
        } else if let prev = Self.boundary(before: index, elements: elements) {
            let slice = elements[elements.startIndex..<prev]
            let prevIndex = O.measure(slice)
            return .init(
                base: .measure(slice),
                offset: offset - prevIndex
            )
        } else {
            return .init(base: .zero, offset: offset)
        }
    }
    
}

extension SummarizedCollection {
    
    public func isBoundary<D>(_ type: D.Type, i: Index) -> Bool
        where D: CollectionDimension, D.Summary == Summary
    {
        if i == startIndex || i == endIndex {
            return true
        }

        let indexD: D = .get(summary(at: i))
        let beforeD = i == startIndex ? indexD : .get(summary(at: index(before: i)))
        let afterD = i == endIndex ? indexD : .get(summary(at: index(after: i)))
        return beforeD < indexD || indexD < afterD
    }

    public func boundary<D>(_ type: D.Type, before i: Index) -> Index?
        where D: CollectionDimension, D.Summary == Summary
    {
        guard i > startIndex else {
            return nil
        }

        let indexD: D = .get(summary(at: i))

        var i = i
        while i > startIndex {
            formIndex(before: &i)
            if .get(summary(at: i)) < indexD {
                return i
            }
        }
        
        return i
    }

    public func boundary<D>(_ type: D.Type, after i: Index) -> Index?
        where D: CollectionDimension, D.Summary == Summary
    {
        guard i < endIndex else {
            return nil
        }

        let indexD: D = .get(summary(at: i))

        var i = i
        while i < endIndex {
            formIndex(after: &i)
            if .get(summary(at: i)) > indexD {
                return i
            }
        }
        
        return i
    }

    public func index<D>(
        _ i: Self.Index,
        offsetBy distance: D
    ) -> Index where D: CollectionDimension, D.Summary == Summary {
        let start = D.get(summary(at: i))
        let end = start + distance
        return D.index(to: end, summary: nil, elements: self) ?? endIndex
    }

    public func index<D>(at distance: D) -> Index where D: CollectionDimension, D.Summary == Summary {
        index(startIndex, offsetBy: distance)
    }

    public func index<B, O>(
        _ i: Self.Index,
        offsetBy point: CollectionPoint<B, O>) -> Index
    where
        B.Summary == Summary
    {
        let baseOffset = index(i, offsetBy: point.base)
        return index(baseOffset, offsetBy: point.offset)
    }

    public func index<B, O>(
        at point: CollectionPoint<B, O>) -> Index
    where
        B.Summary == Summary
    {
        return index(startIndex, offsetBy: point.offset)
    }

}
