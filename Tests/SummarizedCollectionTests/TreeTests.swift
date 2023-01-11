import XCTest
@testable import SummarizedCollection

final class TreeTests: XCTestCase {
        
    func testEmpty() throws {
        let tree = TreeList<Int>()
        tree.ensureValid()
        XCTAssertEqual(tree.count, 0)
    }

    func testSingle() throws {
        let tree = TreeList([0])
        tree.ensureValid()
        XCTAssertEqual(tree.count, 1)
    }
    
    func testMany() throws {
        let elements = Array(repeating: 0, count: 100)
        let tree = TreeList(elements)
        tree.ensureValid()
        XCTAssertEqual(tree.count, elements.count)
    }

    func testConcat() throws {
        var tree1 = TreeList<Int>([0])
        let tree2 = TreeList<Int>([1])
        
        tree1.concat(tree2)

        XCTAssertEqual(tree1.count, 2)
        XCTAssertEqual(tree2.count, 1)
        
        tree1.ensureValid()
        tree2.ensureValid()
    }

    func testSplitEmpty() {
        var tree = TreeList<Int>()
        let split = tree.split(0)
        XCTAssertEqual(tree.count, 0)
        XCTAssertEqual(split.count, 0)
        tree.ensureValid()
        split.ensureValid()
    }

    func testSplitSingle() {
        var tree = TreeList([0])
        let split = tree.split(0)
        XCTAssertEqual(tree.count, 0)
        XCTAssertEqual(split.count, 1)
        tree.ensureValid()
        split.ensureValid()
    }

    func testSplitLeaf() {
        var tree = TreeList([0, 1, 2])
        let split = tree.split(1)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(split.count, 2)
        tree.ensureValid()
        split.ensureValid()
    }

    func testSplitBranch() {
        var tree = TreeList([0, 1, 2, 3])
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

            let tree = TreeList(list)
            for i in 0..<tree.count {
                var t = tree
                let split = t.split(i)
                assert(t.count == i)
                assert(split.count == tree.count - i)
                t.ensureValid()
                split.ensureValid()
            }
        }
    }
    
    func testInsertRange() {
        var tree = TreeList([0, 1, 2, 3])
        tree.insert(contentsOf: [9, 9, 9, 9, 9], at: tree.index(tree.startIndex, offsetBy: 3))
        XCTAssertEqual(tree.count, 9)

    }

}
