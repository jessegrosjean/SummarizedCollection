import XCTest
@testable import SummarizedCollection

final class TreeTests: XCTestCase {
        
    func testEmpty() throws {
        let tree = List<Int>()
        tree.ensureValid()
        XCTAssertEqual(tree.count, 0)
    }

    func testSingle() throws {
        let tree = List([0])
        tree.ensureValid()
        XCTAssertEqual(tree.count, 1)
    }
    
    func testMany() throws {
        let elements = Array(repeating: 0, count: 100)
        let tree = List(elements)
        tree.ensureValid()
        XCTAssertEqual(tree.count, elements.count)
    }

    func testConcat() throws {
        var tree1 = List<Int>([0])
        let tree2 = List<Int>([1])
        
        tree1.concat(tree2)

        XCTAssertEqual(tree1.count, 2)
        XCTAssertEqual(tree2.count, 1)
        
        tree1.ensureValid()
        tree2.ensureValid()
    }

    func testSplitEmpty() {
        var tree = List<Int>()
        let split = tree.split(0)
        XCTAssertEqual(tree.count, 0)
        XCTAssertEqual(split.count, 0)
        tree.ensureValid()
        split.ensureValid()
    }

    func testSplitSingle() {
        var tree = List([0])
        let split = tree.split(0)
        XCTAssertEqual(tree.count, 0)
        XCTAssertEqual(split.count, 1)
        tree.ensureValid()
        split.ensureValid()
    }

    func testSplitLeaf() {
        var tree = List([0, 1, 2])
        let split = tree.split(1)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(split.count, 2)
        tree.ensureValid()
        split.ensureValid()
    }

    func testSplitBranch() {
        var tree = List([0, 1, 2, 3])
        let split = tree.split(2)
        XCTAssertEqual(tree.count, 2)
        XCTAssertEqual(split.count, 2)
        tree.ensureValid()
        split.ensureValid()
    }

    func testManySplitsAndConcats() {
        var list: [Int] = []
        for i in 0..<100 {
            list.append(i)
            List(list).testSplitAndConcat(List.IndexDimension.self)
        }
    }
    
    func testInsertRange() {
        var tree = List([0, 1, 2, 3])
        tree.insert(contentsOf: [9, 9, 9, 9, 9], at: tree.index(tree.startIndex, offsetBy: 3))
        XCTAssertEqual(tree.count, 9)
    }

}
