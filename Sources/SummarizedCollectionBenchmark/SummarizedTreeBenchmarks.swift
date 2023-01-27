import SummarizedCollection
import CollectionsBenchmark
import OSLog

import _CollectionsTestSupport

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
        
        add(
            title: "List<Int> sequential iteration",
            input: [Int].self
        ) { input in
            { timer in
                let list = List(input)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> sequential iteration")
                    for e in list {
                        blackHole(e)
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> sequential iteration")
                }
                blackHole(list)
            }
        }

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
            title: "List<Int> contains",
            input: ([Int], [Int]).self
        ) { input, lookups in
            { timer in
                let list = List(input)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> contains")
                    for i in lookups {
                        precondition(list.contains(i))
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> contains")
                }
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
        
        add(
            title: "List<Int> prepend",
            input: [Int].self
        ) { input in
            { timer in
                var list = List<Int>()
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> prepend")
                    for i in input {
                        list.replace(0..<0, with: CollectionOfOne(i))
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> prepend")
                }
                assert(list.count == input.count)
                blackHole(list)
            }
        }

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

        add(
            title: "List<Int> removeLast",
            input: Int.self
        ) { size in
            return { timer in
                var list = List<Int>(0..<size)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> removeLast")
                    for _ in 0..<size {
                        list.removeLast()
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> removeLast")
                }
                precondition(list.isEmpty)
                blackHole(list)
            }
        }

        add(
            title: "List<Int> removeFirst",
            input: Int.self
        ) { size in
            return { timer in
                var list = List<Int>(0..<size)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> removeFirst")
                    for _ in 0..<size {
                        list.removeFirst()
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> removeFirst")
                }
                precondition(list.isEmpty)
                blackHole(list)
            }
        }

        add(
            title: "List<Int> random remove",
            input: Insertions.self
        ) { insertions in
            let removals = insertions.values.reversed()
            return { timer in
                var list = List(0 ..< removals.count)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "List<Int> random removals")
                    for i in removals {
                        list.replace(i..<i + 1, with: EmptyCollection())
                    }
                    OSLog.pointsOfInterest.end(name: "List<Int> random removals")
                }
                precondition(list.isEmpty)
                blackHole(list)
            }
        }

        add(
            title: "List<Int> split",
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
            title: "List<Int> concat",
            input: Int.self
        ) { size in
            return { timer in
                var tree = List(0 ..< size)
                
                var splits: [List<Int>] = []
                while tree.count > 1 {
                    splits.append(tree.split(tree.count / 2))
                }
                
                splits.shuffle()
                
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
        
    }
    
}
