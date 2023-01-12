import XCTest
@testable import SummarizedCollection

final class TreeCursorTests: XCTestCase {

    typealias IndexDim = List<Int>.IndexDimension
        
    func testCursorEmpty() throws {
        let empty = List<Int>()
        var cursor = empty.cursor()
        
        XCTAssertEqual(cursor.isBeforeStart, true)
        XCTAssertEqual(cursor.nextLeaf(), [])
        XCTAssertEqual(cursor.isAtEnd, true)
        XCTAssertEqual(cursor.nextLeaf(), nil)
        XCTAssertEqual(cursor.isAfterEnd, true)
        XCTAssertEqual(cursor.prevLeaf(), [])
        XCTAssertEqual(cursor.isAtEnd, true)
        XCTAssertEqual(cursor.nextLeaf(), nil)
        XCTAssertEqual(cursor.isAfterEnd, true)
        XCTAssertEqual(cursor.prevLeaf(), [])
        XCTAssertEqual(cursor.isAtEnd, true)
        XCTAssertEqual(cursor.prevLeaf(), nil)
        XCTAssertEqual(cursor.isBeforeStart, true)
    }

    func testCursorSingleLeaf() {
        let elements = [0]
        let single = List(elements)
        var cursor = single.cursor()
        let leaf = elements[...]

        XCTAssertEqual(cursor.isBeforeStart, true)
        XCTAssertEqual(cursor.nextLeaf(), leaf)
        XCTAssertEqual(cursor.isAtStart, true)
        XCTAssertEqual(cursor.nextLeaf(), nil)
        XCTAssertEqual(cursor.isAfterEnd, true)
        XCTAssertEqual(cursor.prevLeaf(), leaf)
        XCTAssertEqual(cursor.isAtStart, true)
        XCTAssertEqual(cursor.prevLeaf(), nil)
        XCTAssertEqual(cursor.isBeforeStart, true)
    }

    func testCursorMultiLeaf() {
        #if !DEBUG
        return // because test depends on leaf size
        #endif

        let elements = [0, 1, 2, 3, 4]
        let multi = List(elements)
        var cursor = multi.cursor()
        let leaf1 = elements[..<3]
        let leaf2 = elements[3...]

        XCTAssertEqual(cursor.isBeforeStart, true)
        XCTAssertEqual(cursor.nextLeaf(), leaf1)
        XCTAssertEqual(cursor.isAtStart, true)
        XCTAssertEqual(cursor.nextLeaf(), leaf2)
        XCTAssertEqual(cursor.nextLeaf(), nil)
        XCTAssertEqual(cursor.isAfterEnd, true)
        XCTAssertEqual(cursor.prevLeaf(), leaf2)
        XCTAssertEqual(cursor.prevLeaf(), leaf1)
        XCTAssertEqual(cursor.prevLeaf(), nil)
    }

}
