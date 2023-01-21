import SummarizedCollection
import CollectionsBenchmark

extension Benchmark {
    
    public mutating func addSummarizedTreeBenchmarks() {
        
        addSimple(
            title: "List<Int> init from range",
            input: Int.self
        ) { size in
            OSLog.pointsOfInterest.begin(name: "List<Int> init from range")
            let list = List(0 ..< size)
            OSLog.pointsOfInterest.end(name: "List<Int> init from range")
            blackHole(list)
        }
        
        /*
        add(
            title: "List<Int> sequential iteration",
            input: [Int].self
        ) { input in
            { timer in
                let list = List(input)
                timer.measure {
                    let end = list.endIndex
                    var i = list.startIndex
                    OSLog.pointsOfInterest.begin(name: "List<Int> sequential iteration")
                    while i != end {
                        list.formIndex(after: &i)
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> sequential iteration")
                }
                blackHole(list)
            }
        }
         */
        add(
            title: "List<Int> for each",
            input: [Int].self
        ) { input in
            { timer in
                let list = List(input)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> for each")
                    for _ in list {
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> for each")
                }
                blackHole(list)
            }
        }
        /*
        add(
            title: "List<Int> subscript get, random offsets",
            input: ([Int], [Int]).self
        ) { input, lookups in
            { timer in
                let list = List(input)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> subscript get, random offsets")
                    for i in lookups {
                        blackHole(list[list.index(at: i)])
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> subscript get, random offsets")
                }
                blackHole(list)
            }
        }
        
        add(
            title: "List<Int> prepend",
            input: [Int].self
        ) { input in
            { timer in
                var list = List<Int>()
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> prepend")
                    for i in input {
                        list.insert(i, at: list.startIndex)
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> prepend")
                }
                assert(list.count == input.count)
                blackHole(list)
            }
        }

        add(
            title: "List<Int> append",
            input: [Int].self
        ) { input in
            { timer in
                var list = List<Int>()
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> append")
                    for i in input {
                        list.append(i)
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> append")
                }
                assert(list.count == input.count)
                blackHole(list)
            }
        }
        */

        add(
            title: "List<Int> random insertions",
            input: Insertions.self
        ) { insertions in
            return { timer in
                let insertions = insertions.values
                var list = List<Int>()
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

        /*
        add(
            title: "List<Int> endIndex",
            input: Int.self
        ) { size in
            { timer in
                let list = List<Int>(0..<size)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> endIndex")
                    for _ in 0..<10000 {
                        _ = list.endIndex
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> endIndex")
                }
                blackHole(list)
            }
        }

        add(
            title: "List<Int> splits",
            input: Int.self
        ) { size in
            return { timer in
                var tree = List(0 ..< size)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> splits")
                    while tree.count > 1 {
                        tree = tree.split(tree.count / 2)
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> splits")
                }
                precondition(tree.count == 1)
                blackHole(tree)
            }
        }
        
        add(
            title: "List<Int> concats",
            input: Int.self
        ) { size in
            return { timer in
                var tree = List(0 ..< size)
                
                var splits: [List<Int>] = []
                while tree.count > 1 {
                    splits.append(tree.split(tree.count / 2))
                }
                
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> concats")
                    for each in splits {
                        tree.concat(each)
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> concats")
                }
                
                precondition(tree.count == size)
                blackHole(tree)
            }
        }
         */
    }
    
}
