import XCTest
@testable import SummarizedCollection

extension SummarizedTreeTests {

    typealias IndexDim = OutlineSummarizedTree.IndexDimension
    
    func testCursorDimension() {
        OutlineSummarizedTree([]).testCursorDimension(IndexDim.self)
        OutlineSummarizedTree([
            .init(line: "", height: 0)
        ]).testCursorDimension(IndexDim.self)
        OutlineSummarizedTree([
            .init(line: "", height: 0),
            .init(line: "", height: 0),
            .init(line: "", height: 0)
        ]).testCursorDimension(IndexDim.self)
        OutlineSummarizedTree([
            .init(line: "", height: 0),
            .init(line: "", height: 0),
            .init(line: "", height: 0),
            .init(line: "", height: 0)]
        ).testCursorDimension(IndexDim.self)
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
        return // because test depends on leaf size
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
        XCTAssertEqual(cursor.leaf(), leaf1)

        XCTAssertEqual(cursor.seek(to: IndexDim(3)), 3)
        XCTAssertEqual(cursor.leaf(), leaf2)
        XCTAssertEqual(cursor.seek(to: IndexDim(4)), 4)
        XCTAssertEqual(cursor.leaf(), leaf2)
        XCTAssertEqual(cursor.index, 4)
        XCTAssertEqual(cursor.point(), .init(base: IndexDim(4), offset: IndexDim(0)))
    }

}
