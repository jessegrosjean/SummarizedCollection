@testable import SummarizedCollection

extension SummarizedTree {

    func testCursorBoundary<B>(_ b: B.Type) where B: CollectionBoundary, B.Element == Element {
        var cursor = cursor()
        
        while let index = cursor.nextBoundary(b) {
            assert(cursor.isBoundary(b))
            _ = cursor.prevBoundary(b)
            assert(cursor.nextBoundary(b) == index)
            _ = cursor.nextBoundary(b)
            assert(cursor.prevBoundary(b) == index)
        }
    }

    func testCursorDimension<D>(_ d: D.Type) where D: CollectionDimension, D.Summary == Summary {
        testCursorBoundary(d)
        
        var dimCursor = cursor()
        var boundCursor = cursor()
        
        while let index = dimCursor.seekNext(d) {
            assert(dimCursor.isBoundary(d))
            assert(boundCursor.nextBoundary(d) == index)
            let point: CollectionPoint<D, IndexDimension> = dimCursor.point()
            assert(point.offset.rawValue == 0)
            assert(IndexDimension(index) == pointToDimension(point: point))
            assert(point == dimensionToPoint(IndexDimension(index)))
            
            var cursor = cursor()
            assert(cursor.seek(to: point.base) == dimCursor.index)
        }
    }

    public func testSplitAndConcat<D>(_ d: D.Type) where D: CollectionDimension, D.Summary == Summary {
        var cursor = cursor()
        while let index = cursor.seekNext(d) {
            var newTree = self
            let split = newTree.split(index)
            
            assert(count == newTree.count + split.count)

            newTree.ensureValid()
            split.ensureValid()
            
            newTree.concat(split)
            assert(count == newTree.count)
            newTree.ensureValid()
        }
    }
    
}


/*

public func testReplace<N, D>(node: N, dimension: D.Type) where N: NodeProtocol, D: Dimension, N.Summary == D.Summary {
    
}

public func testInsert<N, D>(node: N, dimension: D.Type) where N: NodeProtocol, D: Dimension, N.Summary == D.Summary {
    
}

public func testRemove<N, D>(node: N, dimension: D.Type) where N: NodeProtocol, D: Dimension, N.Summary == D.Summary {
    
}

*/
