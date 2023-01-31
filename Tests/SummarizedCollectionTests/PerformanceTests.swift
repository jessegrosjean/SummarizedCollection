/*import XCTest
import OSLog

@testable import SummarizedCollection

import _CollectionsTestSupport

final class PerformanceTests: CollectionTestCase {
    
    let count = 100000
    
    @usableFromInline
    struct IdentifiedItem: Identifiable {
        @usableFromInline
        let id: Int
    }
    
    func testPerformanceIdentifiedList() {
        let list = IdentifiedList((0..<count).map { IdentifiedItem(id: $0) })
        let shuffled = (0..<count).shuffled()

        OSLog.pointsOfInterest.begin(name: "testPerformanceIdentifiedList")
        measure {
            for i in shuffled {
                precondition(list.offset(id: i) == i)
            }
        }
        OSLog.pointsOfInterest.end(name: "testPerformanceIdentifiedList")
    }
    
    func testPerformanceArray() {
        let list = Array((0..<count).map { IdentifiedItem(id: $0) })
        let shuffled = (0..<count).shuffled()
        
        OSLog.pointsOfInterest.begin(name: "testPerformanceArray")
        measure {
            for i in shuffled {
                precondition(list.firstIndex { $0.id == i } == i)
            }
        }
        OSLog.pointsOfInterest.end(name: "testPerformanceArray")
    }
    
}
*/
