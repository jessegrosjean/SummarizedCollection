import XCTest
@testable import SummarizedCollection

final class SummarizedTreeTests: XCTestCase {
        
    func testEmpty() throws {
        let empty = OutlineSummarizedTree()
        XCTAssertEqual(empty.summary, .zero)
        XCTAssertEqual(empty.isBoundary(HeightDimension.self, i: empty.startIndex), true)
        XCTAssertEqual(empty.isBoundary(CharDimension.self, i: empty.startIndex), true)
        XCTAssertEqual(empty.isBoundary(UTF16Dimension.self, i: empty.startIndex), true)
    }

    func testSingle() throws {
        let single = OutlineSummarizedTree([.init(line: "👮🏿‍♀️", height: 10)])
        XCTAssertEqual(single.summary, .init(count: 1, height: .init(10), charCount: .init(1), utf16Count: .init(7)))
        XCTAssertEqual(single.isBoundary(HeightDimension.self, i: single.startIndex), true)
        XCTAssertEqual(single.isBoundary(HeightDimension.self, i: single.startIndex), true)
    }
    
    func testIndexOffsetByDimension() throws {
        let empty = OutlineSummarizedTree()
        XCTAssertEqual(empty.index(at: HeightDimension.zero), empty.startIndex)
        XCTAssertEqual(empty.index(at: HeightDimension(300)), empty.startIndex) // capped

        let o = OutlineSummarizedTree(createTestOutline())
        let index0 = o.startIndex
        let index1 = o.index(index0, offsetBy: 1)
        let index2 = o.index(index0, offsetBy: 2)
        let index10 = o.index(index0, offsetBy: 10)

        XCTAssertEqual(o.index(at: HeightDimension(0)), index0)
        XCTAssertEqual(o.index(at: HeightDimension(5)), index0)
        XCTAssertEqual(o.index(at: HeightDimension(10)), index1)
        XCTAssertEqual(o.index(at: HeightDimension(15)), index1)
        XCTAssertEqual(o.index(at: CharDimension(0)), index0)
        XCTAssertEqual(o.index(at: CharDimension(2)), index0)
        XCTAssertEqual(o.index(at: CharDimension(5)), index1)

        XCTAssertEqual(o.index(index1, offsetBy: HeightDimension(5)), index1)
        XCTAssertEqual(o.index(index1, offsetBy: HeightDimension(9)), index1)
        XCTAssertEqual(o.index(index1, offsetBy: HeightDimension(10)), index2)
        XCTAssertEqual(o.index(index1, offsetBy: HeightDimension(11)), index2)
        XCTAssertEqual(o.index(index1, offsetBy: HeightDimension(1000)), index10) // capped
    }
    
    func testDimensionToPointAndPointToDimension() throws {
        typealias IndexDim = CollectionIndexDimension<OutlineSummary>
        let o = OutlineSummarizedTree(createTestOutline())
        var charDim = CharDimension(0)
        while charDim <= CharDimension.get(o.summary) {
            let point: CollectionPoint<IndexDim, CharDimension> = o.dimensionToPoint(charDim)!
            assert(charDim == o.pointToDimension(point: point))
            charDim += .init(1)
        }
    }
    
    func testIndexOfID() throws {
        let o = OutlineSummarizedTree(createTestOutline())
        for (i, each) in o.enumerated() {
            assert(o.index(o.startIndex, offsetBy: i) == o.index(id: each.id))
        }
    }

    func testBuildWithOverflow() throws {
        let small = OutlineSummarizedTree([
            .init(line: "one", height: 10),
            .init(line: "two", height: 10),
            .init(line: "three", height: 10),
            .init(line: "four", height: 10)
        ])
        small.ensureValid()
        
        let bigger = OutlineSummarizedTree(createTestOutline())
        bigger.ensureValid()
    }

    //func testBuilder() throws {
    //    var builder = OutlineSummarizedTree.Builder()
    //    builder.concat(elements: createTestOutline(count: 200))
    //}
    
    func testRemoveWithCollapsing() throws {
        typealias IndexDim = CollectionIndexDimension<OutlineSummary>
        var bigger = OutlineSummarizedTree(createTestOutline())
        bigger.removeSubrange(bigger.index(at: IndexDim(1))..<bigger.index(at: IndexDim(10)))
        bigger.ensureValid()
        
        assert(bigger.count == 1)
        
        while !bigger.isEmpty {
            bigger.removeSubrange(bigger.startIndex..<bigger.index(at: IndexDim(1)))
            bigger.ensureValid()
        }
        bigger.ensureValid()
    }
    
    func testRandomMutations() throws {
        var empty = OutlineSummarizedTree()
        testRandomMutations(tree: &empty, mutations: 10)

        var single = OutlineSummarizedTree([.init(line: "👮🏿‍♀️", height: 10)])
        testRandomMutations(tree: &single, mutations: 100)

        var two = OutlineSummarizedTree([.init(line: "one", height: 10), .init(line: "two", height: 10)])
        testRandomMutations(tree: &two, mutations: 100)

        var three = OutlineSummarizedTree([.init(line: "one", height: 10), .init(line: "two", height: 10), .init(line: "three", height: 10)])
        testRandomMutations(tree: &three, mutations: 100)

        var four = OutlineSummarizedTree([.init(line: "one", height: 10), .init(line: "two", height: 10), .init(line: "three", height: 10), .init(line: "four", height: 10)])
        testRandomMutations(tree: &four, mutations: 100)

        //var many = OutlineSummarizedTree(createTestOutline())
        //testRandomMutations(tree: &many, mutations: 100)
    }
    
    func testRandomMutations(tree: inout OutlineSummarizedTree, mutations: Int) {
        var saved: [OutlineSummarizedTree.Element] = []
        
        for _ in 0..<mutations {
            switch (0..<2).randomElement() {
            case 0: // insert
                let i = tree.randomIndex()
                tree.insert(contentsOf: saved, at: i)
                saved.removeAll()
            case 1: // remove
                let r = tree.randomRange()
                saved.append(contentsOf: tree[r])
                tree.removeSubrange(r)
            default:
                fatalError()
            }
            
            tree.ensureValid()
        }
    }
}

extension BidirectionalCollection {
    func randomIndex() -> Index {
        let i = (0..<count).randomElement() ?? 0
        return index(startIndex, offsetBy: i)
    }

    func randomRange() -> Range<Index> {
        let start = (0..<count).randomElement() ?? 0
        let end = (start..<count).randomElement() ?? start
        return index(startIndex, offsetBy: start)..<index(startIndex, offsetBy: end)
    }
}
