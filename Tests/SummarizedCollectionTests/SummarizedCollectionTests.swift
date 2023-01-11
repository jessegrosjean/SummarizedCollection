import XCTest
@testable import SummarizedCollection

final class SummarizedCollectionTests: XCTestCase {
        
    func testEmpty() throws {
        let empty = OutlineArray(inner: [])
        XCTAssertEqual(empty.summary, .zero)
        XCTAssertEqual(empty.isBoundary(HeightDimension.self, i: 0), true)
        XCTAssertEqual(empty.isBoundary(CharDimension.self, i: 0), true)
        XCTAssertEqual(empty.isBoundary(UTF16Dimension.self, i: 0), true)
    }
 
    func testSingle() throws {
        let single = OutlineArray(inner: [.init(line: "👮🏿‍♀️", height: 10)])
        XCTAssertEqual(single.summary, .init(count: 1, height: .init(10), charCount: .init(1), utf16Count: .init(7)))
        XCTAssertEqual(single.isBoundary(HeightDimension.self, i: 0), true)
        XCTAssertEqual(single.isBoundary(HeightDimension.self, i: 1), true)
    }

    func testIndexOffsetByDimension() throws {
        let empty = OutlineArray(inner: [])
        XCTAssertEqual(empty.index(at: HeightDimension.zero), 0)
        XCTAssertEqual(empty.index(at: HeightDimension(300)), 0) // capped

        let o = OutlineArray(inner: createTestOutline())
        XCTAssertEqual(o.index(at: HeightDimension(0)), 0)
        XCTAssertEqual(o.index(at: HeightDimension(5)), 0)
        XCTAssertEqual(o.index(at: HeightDimension(10)), 1)
        XCTAssertEqual(o.index(at: HeightDimension(15)), 1)
        XCTAssertEqual(o.index(at: CharDimension(0)), 0)
        XCTAssertEqual(o.index(at: CharDimension(2)), 0)
        XCTAssertEqual(o.index(at: CharDimension(5)), 1)

        XCTAssertEqual(o.index(1, offsetBy: HeightDimension(5)), 1)
        XCTAssertEqual(o.index(1, offsetBy: HeightDimension(9)), 1)
        XCTAssertEqual(o.index(1, offsetBy: HeightDimension(10)), 2)
        XCTAssertEqual(o.index(1, offsetBy: HeightDimension(11)), 2)
        XCTAssertEqual(o.index(1, offsetBy: HeightDimension(1000)), 10) // capped
    }

    func testDimensionToPointAndPointToDimension() throws {
        typealias IndexDimensiion = CollectionIndexDimension<OutlineSummary>
        let o = OutlineArray(inner: createTestOutline())
        var charDim = CharDimension(0)
        while charDim <= CharDimension.get(o.summary) {
            let point: CollectionPoint<IndexDimensiion, CharDimension> = o.dimensionToPoint(charDim)!
            assert(charDim == o.pointToDimension(point: point))
            charDim += .init(1)
        }
    }

    func testIndexOfID() throws {
        let o = OutlineArray(inner: createTestOutline())
        for (i, each) in o.enumerated() {
            assert(i == o.index(id: each.id))
        }
    }
}
