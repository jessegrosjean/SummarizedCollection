public protocol SummarizedCollection: BidirectionalCollection {
        
    associatedtype Summary: CollectionSummary where Summary.Element == Element
    
    typealias IndexDimension = CollectionIndexDimension<Summary>

    func index<D>(
        _ i: Self.Index,
        offsetBy distance: D
    ) -> Index where D: CollectionDimension, D.Summary == Summary
        
    func dimensionToPoint<D, B>(
        _ dimension: D
    ) -> CollectionPoint<B, D>?
    where
        B.Summary == Summary,
        D.Summary == Summary

    func pointToDimension<B, D>(
        point: CollectionPoint<B, D>
    ) -> D?
    where
        B.Summary == Summary,
        D.Summary == Summary

}

extension SummarizedCollection {
    
    public var summary: Summary {
        summary(at: endIndex)
    }
    
    public func summary(at index: Index) -> Summary {
        var summary = Summary.zero
        for i in indices {
            if i == index {
                return summary
            } else {
                summary += Summary.summarize(element: self[i])
            }
        }
        return summary
    }

    public func measure<D>(to i: Index? = nil) -> D where D: CollectionDimension, D.Summary == Summary {
        if let index = i {
            return .get(summary(at: index))
        } else {
            return .get(summary)
        }
    }
    
    public func pointToDimension<B, D>(
        point: CollectionPoint<B, D>
    ) -> D?
    where
        B.Summary == Summary,
        D.Summary == Summary
    {
        let baseIndex = index(startIndex, offsetBy: point.base)
        return measure(to: baseIndex) + point.offset
    }
    
    public func dimensionToPoint<D, B>(
        _ dimension: D
    ) -> CollectionPoint<B, D>?
    where
        B.Summary == Summary,
        D.Summary == Summary
    {
        B.point(from: dimension, summary: summary, elements: self)
    }

}
