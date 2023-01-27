import SummarizedCollection
import CollectionsBenchmark
import OSLog

import _CollectionsTestSupport

extension Int: Identifiable {
    public var id: Int {
        self
    }
}

extension Benchmark {
    
    public mutating func addSummarizedTreeIdentifiedListBenchmarks() {
        
        addSimple(
            title: "IdentifiedList<Int> init from range",
            input: Int.self
        ) { size in
            OSLog.pointsOfInterest.begin(name: "IdentifiedList<Int> init from range")
            let list = IdentifiedList(0 ..< size)
            OSLog.pointsOfInterest.end(name: "IdentifiedList<Int> init from range")
            blackHole(list)
        }

        add(
            title: "IdentifiedList<Int> contains",
            input: Int.self
        ) { count in
            { timer in
                let list = IdentifiedList(0..<count)
                let shuffled = (0..<count).shuffled()[0..<count / 10]
                
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "IdentifiedList<Int> contains")
                    for i in shuffled {
                        precondition(list.contains(id: i))
                    }
                    OSLog.pointsOfInterest.end(name: "IdentifiedList<Int> contains")
                }
            }
        }

        add(
            title: "IdentifiedList<Int> offset of id",
            input: Int.self
        ) { count in
            { timer in
                let list = IdentifiedList(0..<count)
                let shuffled = (0..<count).shuffled()[0..<count / 10]
                
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "IdentifiedList<Int> offset of id")
                    for i in shuffled {
                        precondition(list.offset(id: i) == i)
                    }
                    OSLog.pointsOfInterest.end(name: "IdentifiedList<Int> offset of id")
                }
            }
        }

        add(
            title: "IdentifiedList<Int> random insertions",
            input: Insertions.self
        ) { insertions in
            return { timer in
                let insertions = insertions.values
                var list = IdentifiedList<Int>()
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> random insertions")
                    for i in insertions.indices {
                        list.replace(i..<i, with: CollectionOfOne(i))
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> random insertions")
                }
                blackHole(list)
            }
        }

    }
    
}
