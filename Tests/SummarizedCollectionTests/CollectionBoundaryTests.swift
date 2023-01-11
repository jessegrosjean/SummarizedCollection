import XCTest
@testable import SummarizedCollection

final class CollectionBoundaryTests: XCTestCase {
    
    func testBoundaries() throws {
        let a: [Int] = []
        
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 0, elements: a), true)
        XCTAssertEqual(ChangedBoundary.boundary(after: 0, elements: a), nil)
        XCTAssertEqual(ChangedBoundary.boundary(before: 0, elements: a), nil)
        
        let b: [Int] = [1]
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 0, elements: b), true)
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 1, elements: b), true)
        XCTAssertEqual(ChangedBoundary.boundary(after: 0, elements: b), 1)
        XCTAssertEqual(ChangedBoundary.boundary(after: 1, elements: b), nil)
        XCTAssertEqual(ChangedBoundary.boundary(before: 1, elements: b), 0)
        XCTAssertEqual(ChangedBoundary.boundary(before: 0, elements: b), nil)

        let c: [Int] = [1, 2]
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 0, elements: c), true)
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 1, elements: c), true)
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 2, elements: c), true)
        XCTAssertEqual(ChangedBoundary.boundary(after: 0, elements: c), 1)
        XCTAssertEqual(ChangedBoundary.boundary(after: 1, elements: c), 2)
        XCTAssertEqual(ChangedBoundary.boundary(after: 2, elements: c), nil)
        XCTAssertEqual(ChangedBoundary.boundary(before: 2, elements: c), 1)
        XCTAssertEqual(ChangedBoundary.boundary(before: 1, elements: c), 0)
        XCTAssertEqual(ChangedBoundary.boundary(before: 0, elements: c), nil)

        let d: [Int] = [1, 1]
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 0, elements: d), true)
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 1, elements: d), false)
        XCTAssertEqual(ChangedBoundary.isBoundary(at: 2, elements: d), true)
        XCTAssertEqual(ChangedBoundary.boundary(after: 0, elements: d), 2)
        XCTAssertEqual(ChangedBoundary.boundary(after: 2, elements: d), nil)
        XCTAssertEqual(ChangedBoundary.boundary(before: 2, elements: d), 0)
        XCTAssertEqual(ChangedBoundary.boundary(before: 0, elements: d), nil)

        XCTAssertEqual(d.isBoundary(ChangedBoundary.self, at: 0), true)
        XCTAssertEqual(d.isBoundary(ChangedBoundary.self, at: 1), false)
        XCTAssertEqual(d.isBoundary(ChangedBoundary.self, at: 2), true)
        XCTAssertEqual(d.boundary(ChangedBoundary.self, after: 0), 2)
        XCTAssertEqual(d.boundary(ChangedBoundary.self, after: 2), nil)
        XCTAssertEqual(d.boundary(ChangedBoundary.self, before: 2), 0)
        XCTAssertEqual(d.boundary(ChangedBoundary.self, before: 0), nil)
    }
    
}

enum ChangedBoundary: CollectionBoundary {
    typealias Element = Int
    
    static func isBoundary<C>(at i: C.Index, elements: C) -> Bool
    where
        C : BidirectionalCollection, C.Element == Element
    {
        if i == elements.startIndex {
            return true
        }

        if i == elements.endIndex {
            return true
        }
        
        return elements[i] != elements[elements.index(before: i)]
    }
    
}
