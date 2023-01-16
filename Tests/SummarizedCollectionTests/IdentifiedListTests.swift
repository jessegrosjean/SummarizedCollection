import XCTest
@testable import SummarizedCollection

final class IdentifiedListTests: XCTestCase {
    
    struct IdentifiedItem: Identifiable {
        let id: Int
    }
        
    func testEmpty() throws {
        let empty = IdentifiedList<IdentifiedItem>()
        XCTAssertEqual(empty.summary, .zero)
        XCTAssertEqual(empty.offset(id: 0), nil)
    }

    func testSingle() throws {
        let single = IdentifiedList<IdentifiedItem>([.init(id: 2)])
        XCTAssertEqual(single.summary.count, 1)
        XCTAssertEqual(single.offset(id: 0), nil)
        XCTAssertEqual(single.offset(id: 2), 0)
    }
    
    
    /*
    func testLookups() throws {
        var list = IdentifiedList((0 ..< 1000000).map { IdentifiedItem(id: $0) })
        list.context.addNode(list.root)
        assert(Array(list).count == list.count)
        
        measure {
            //for _ in 0..<list.count {
                for i in 500000..<500100 {
                    assert(list.offset(id: i) == i)
                }
            //}
        }
    }

    func testLookupsArray() throws {
        var list = Array((0 ..< 1000000).map { IdentifiedItem(id: $0) })
        
        measure {
            //for _ in 0..<list.count {
                for i in 500000..<500100 {
                    assert(list.firstIndex { $0.id == i } == i)
                }
            //}
        }
    }*/

}
