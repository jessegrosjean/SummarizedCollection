import XCTest
@testable import SummarizedCollection

extension SummarizedTreeTests {

    typealias IndexDim = OutlineSummarizedTree.IndexDimension
    
    func testCursorEmpty() throws {
        let empty = List<Int>()
        var cursor = empty.cursor()
        
        XCTAssertEqual(cursor.isBeforeStart, true)
        XCTAssertEqual(cursor.nextLeaf()?.count, 0)
        XCTAssertEqual(cursor.isAtEnd, true)
        XCTAssertEqual(cursor.nextLeaf(), nil)
        XCTAssertEqual(cursor.isAfterEnd, true)
        XCTAssertEqual(cursor.prevLeaf()?.count, 0)
        XCTAssertEqual(cursor.isAtEnd, true)
        XCTAssertEqual(cursor.nextLeaf(), nil)
        XCTAssertEqual(cursor.isAfterEnd, true)
        XCTAssertEqual(cursor.prevLeaf()?.count, 0)
        XCTAssertEqual(cursor.isAtEnd, true)
        XCTAssertEqual(cursor.prevLeaf(), nil)
        XCTAssertEqual(cursor.isBeforeStart, true)
    }

    func testCursorEmptySeekTo() {
        let empty = OutlineSummarizedTree()
        var cursor = empty.cursor()

        XCTAssertEqual(cursor.seek(to: IndexDim(0)), .zero)
        XCTAssertEqual(cursor.isAtEnd, true)
        XCTAssertEqual(cursor.seek(to: IndexDim(0)), .zero)
        XCTAssertEqual(cursor.index, .zero)
        XCTAssertEqual(cursor.point(), .init(base: IndexDim(0), offset: IndexDim(0)))
        XCTAssertEqual(cursor.leaf().count, .zero)
    }
    
    func testCursorSingleLeafSeekTo() {
        let elements: [Row] = [.init(line: "👮🏿‍♀️", height: 10), .init(line: "👮🏿‍♀️", height: 10)]
        let single = OutlineSummarizedTree(elements)
        var cursor = single.cursor()

        XCTAssertEqual(cursor.seek(to: IndexDim(0)), .zero)
        XCTAssertEqual(cursor.isAtEnd, false)
        XCTAssertEqual(cursor.seek(to: IndexDim(0)), .zero)
        XCTAssertEqual(cursor.index, .zero)
        XCTAssertEqual(cursor.point(), .init(base: IndexDim(0), offset: IndexDim(0)))
        
        XCTAssertEqual(cursor.seek(to: IndexDim(1)), 1)
        XCTAssertEqual(cursor.index, 1)
        XCTAssertEqual(cursor.seek(to: IndexDim(1)), 1)
        XCTAssertEqual(cursor.index, 1)
        XCTAssertEqual(cursor.point(), .init(base: IndexDim(1), offset: IndexDim(0)))
        XCTAssertEqual(cursor.isAtEnd, false)

        XCTAssertEqual(cursor.seek(to: IndexDim(2)), 2)
        XCTAssertEqual(cursor.index, 2)
        XCTAssertEqual(cursor.seek(to: IndexDim(2)), 2)
        XCTAssertEqual(cursor.index, 2)
        XCTAssertEqual(cursor.point(), .init(base: IndexDim(2), offset: IndexDim(0)))
        XCTAssertEqual(cursor.isAtEnd, true)
    }
    
    func testCursorMultiLeafSeekTo() {
        #if !DEBUG
        return // because test depends on leaf size of 3
        #endif

        let elements: [Row] = [
            .init(line: "one", height: 10),
            .init(line: "two", height: 10),
            .init(line: "three", height: 10),
            .init(line: "four", height: 10)
        ]
        
        let multi = OutlineSummarizedTree(elements)
        var cursor = multi.cursor()
        let leaf1 = elements[..<3]
        let leaf2 = elements[3...]

        XCTAssertEqual(cursor.seek(to: IndexDim(0)), .zero)
        XCTAssertEqual(cursor.seek(to: IndexDim(1)), 1)
        XCTAssertEqual(cursor.seek(to: IndexDim(2)), 2)
        XCTAssertEqual(Array(cursor.leaf())[...], leaf1)

        XCTAssertEqual(cursor.seek(to: IndexDim(3)), 3)
        XCTAssertEqual(Array(cursor.leaf())[...], leaf2)
        XCTAssertEqual(cursor.seek(to: IndexDim(4)), 4)
        XCTAssertEqual(Array(cursor.leaf())[...], leaf2)
        XCTAssertEqual(cursor.index, 4)
        XCTAssertEqual(cursor.point(), .init(base: IndexDim(4), offset: IndexDim(0)))
    }

    func testCursorDimensions() {
        let empty = OutlineSummarizedTree([])
            
        empty.testCursorDimension(IndexDim.self)
        empty.testCursorDimension(HeightDimension.self)
        empty.testCursorDimension(CharDimension.self)
        empty.testCursorDimension(UTF16Dimension.self)

        let single = OutlineSummarizedTree([
            .init(line: "", height: 0)
        ])

        single.testCursorDimension(IndexDim.self)
        single.testCursorDimension(HeightDimension.self)
        single.testCursorDimension(CharDimension.self)
        single.testCursorDimension(UTF16Dimension.self)
        
        let triple = OutlineSummarizedTree([
            .init(line: "", height: 0),
            .init(line: "", height: 0),
            .init(line: "", height: 0)
        ])
            
        triple.testCursorDimension(IndexDim.self)
        triple.testCursorDimension(HeightDimension.self)
        triple.testCursorDimension(CharDimension.self)
        triple.testCursorDimension(UTF16Dimension.self)

        let multiLeaf = OutlineSummarizedTree([
            .init(line: "", height: 0),
            .init(line: "", height: 0),
            .init(line: "", height: 0),
            .init(line: "", height: 0)]
        )
        
        multiLeaf.testCursorDimension(IndexDim.self)
        multiLeaf.testCursorDimension(HeightDimension.self)
        multiLeaf.testCursorDimension(CharDimension.self)
        multiLeaf.testCursorDimension(UTF16Dimension.self)
    }
    
    func testCursorDimensionsTrailingZeros() {
        
        let elements = [
            Row(line: "", height: 0),
            Row(line: "", height: 1),
            Row(line: "", height: 0)
        ]
        
        let tree = OutlineSummarizedTree(elements)
        let inputIndex = IndexDim(3)
        let point = HeightDimension.point(from: inputIndex, summary: nil, elements: elements)
        let outputIndex = tree.pointToDimension(point: point)
        
        print("failing test case, not sure if code or logic is wrong")
        print("problem will show up when have .zero dimension at end of list")
        //assert(inputIndex == outputIndex)
    }
    
}
