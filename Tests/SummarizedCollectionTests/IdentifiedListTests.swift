import XCTest
@testable import SummarizedCollection

import _CollectionsTestSupport

final class IdentifiedListTests: CollectionTestCase {
    
    struct IdentifiedItem: Identifiable {
        let id: Int
    }
    
    func testInit() {
        withEvery("size", in: 0..<100) { size in
            withLifetimeTracking { tracker in
                let list = IdentifiedList(tracker.instances(for: (0..<size).map { IdentifiedItem(id: $0) }))

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
                    var list = IdentifiedList(tracker.instances(for: (0..<size).map { IdentifiedItem(id: $0) }))
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
                    var list = IdentifiedList(tracker.instances(for: (0..<size).map { IdentifiedItem(id: $0) }))
                    let split = list.split(index)
                    var new = IdentifiedList<LifetimeTracked<IdentifiedItem>>()
                    
                    if size == 2 && index == 1 {
                        print()
                    }
                    
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
                        if new.offset(id: each.id) != i {
                            print()
                        }
                        //XCTAssertEqual(new.offset(id: each.id), i)
                    }
                    
                    expectEqual(new.count, size)
                }
            }
        }
    }

    
    func testReplace() {
        withEvery("size", in: [1, 2, 4, 8, 16]) { size in
            withLifetimeTracking { tracker in
                let template = IdentifiedList(tracker.instances(for: (0..<size).map { IdentifiedItem(id: $0) }))
                withEvery("start", in: 0..<size) { start in
                    withEvery("end", in: start..<size) { end in
                        withEvery("insert", in: [0, 1, 2, 3, 5, 9]) { insert in
                            var list = IdentifiedList(tracker.instances(for: (0..<size).map { IdentifiedItem(id: $0) }))
                            //var list = template
                            
                            if insert == 9 && size == 4 {
                                print()
                            }
                            
                            list.replace(start..<end, with: tracker.instances(for: (100..<100 + insert).map { IdentifiedItem(id: $0) }))
                            XCTAssertEqual(list.count, (template.count - (start..<end).count) + insert)
                            list.ensureValid()
                            
                            for (i, each) in list.enumerated() {
                                if list.offset(id: each.id) != i {
                                    print()
                                }
                                XCTAssertEqual(list.offset(id: each.id), i)                                
                            }
                        }
                    }
                }
            }
        }
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
