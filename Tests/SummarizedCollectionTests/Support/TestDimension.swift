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

}
 
/*
public func testSplit<N, D>(node: N, dimension: D.Type) where N: NodeProtocol, D: Dimension, N.Summary == D.Summary {
    let cursor = node.cursor
    while let index = cursor.seekNext(dimension) {
        var newNode = node
        let split = newNode.split(index)
        assert(node.count == newNode.count + split.count)
        testNode(node: newNode)
        testNode(node: split)
    }
}

public func testReplace<N, D>(node: N, dimension: D.Type) where N: NodeProtocol, D: Dimension, N.Summary == D.Summary {
    
}

public func testInsert<N, D>(node: N, dimension: D.Type) where N: NodeProtocol, D: Dimension, N.Summary == D.Summary {
    
}

public func testRemove<N, D>(node: N, dimension: D.Type) where N: NodeProtocol, D: Dimension, N.Summary == D.Summary {
    
}

public func testNode<N>(node: N) where N: NodeProtocol {
    if node.height == 0 {
        assert(node.isLeaf)
        assert(node.summary == N.Summary.init(elements: node.elements.inner))
        testNodeChildren(children: node.children, allowUnderflowing: node.children.count == 1)
    } else {
        assert(node.isInner)
        assert(!node.children.isEmpty)
    }
}


func testNodeChildren<N>(children: NodeChildren<N>, allowUnderflowing: Bool) where N: NodeProtocol {
    var summary = N.Summary.zero
    let height = children.inner.first!.height
    for each in children.inner {
        if !allowUnderflowing || children.count > 1 {
            assert(!each.summary.isEmpty)
            assert(!each.isUnderflowing)
        }
        assert(each.height == height)
        summary += each.summary
    }
    assert(summary == children.summary)
}

*/
