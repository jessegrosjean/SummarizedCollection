import XCTest
@testable import SummarizedCollection

import _CollectionsTestSupport

extension Int: Identifiable {
    public var id: Int {
        self
    }
}

final class IdentifiedListTests: CollectionTestCase {
    
    func testInit() {
        withEvery("size", in: 0..<100) { size in
            withLifetimeTracking { tracker in
                let list = IdentifiedList(tracker.instances(for: 0..<size))
                
                list.ensureValid()
                for (i, each) in list.enumerated() {
                    XCTAssertEqual(list.offset(id: each.id), i)
                }
                
                XCTAssertEqual(list.count, size)
            }
        }
    }

    func testSplit() {
        withEvery("size", in: [1, 2, 4, 8, 16, 32, 64, 127, 128, 129]) { size in
            withEvery("index", in: 0..<size) { index in
                withLifetimeTracking { tracker in
                    var list = IdentifiedList(tracker.instances(for: 0..<size))
                    let split = list.split(index)
                    
                    list.ensureValid()
                    for (i, each) in list.enumerated() {
                        XCTAssertEqual(list.offset(id: each.id), i)
                    }
                    
                    split.ensureValid()
                    for (i, each) in split.enumerated() {
                        XCTAssertEqual(split.offset(id: each.id), i)
                    }
                    
                    expectEqual(list.count + split.count, size)
                }
            }
        }
    }
    
    func testConcat() {
        withEvery("size", in: [1, 2, 4, 8, 16, 32, 64, 127, 128, 129]) { size in
            withEvery("index", in: 0..<size) { index in
                withLifetimeTracking { tracker in
                    var list = IdentifiedList(tracker.instances(for: 0..<size))
                    let split = list.split(index)
                    var new = IdentifiedList<LifetimeTracked<Int>>()
                    
                    new.concat(list)
                    new.concat(split)
                    
                    list.ensureValid()
                    for (i, each) in list.enumerated() {
                        XCTAssertEqual(list.offset(id: each.id), i)
                    }
                    
                    split.ensureValid()
                    for (i, each) in split.enumerated() {
                        XCTAssertEqual(split.offset(id: each.id), i)
                    }
                    
                    new.ensureValid()
                    for (i, each) in new.enumerated() {
                        XCTAssertEqual(new.offset(id: each.id), i)
                    }
                    
                    expectEqual(new.count, size)
                }
            }
        }
    }
    
    func testReplace() {
        withEvery("size", in: [1, 2, 4, 8, 16]) { size in
            withLifetimeTracking { tracker in
                let template = IdentifiedList(tracker.instances(for: 0..<size))
                withEvery("start", in: 0..<size) { start in
                    withEvery("end", in: start..<size) { end in
                        withEvery("insert", in: [0, 1, 2, 3, 5, 9]) { insert in
                            var list = template
                            list.replace(start..<end, with: tracker.instances(for: 100..<100 + insert))
                            XCTAssertEqual(list.count, (template.count - (start..<end).count) + insert)
                            list.ensureValid()
                            for (i, each) in list.enumerated() {
                                XCTAssertEqual(list.offset(id: each.id), i)
                            }
                        }
                    }
                }
            }
        }
    }

}
