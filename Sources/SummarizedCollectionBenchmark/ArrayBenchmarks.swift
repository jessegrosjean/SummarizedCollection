import CollectionsBenchmark
import SummarizedCollection
import OSLog

import _CollectionsUtilities

extension Benchmark {
    
    public mutating func addArrayBenchmarks() {

        addSimple(
            title: "Array<Int> init from range",
            input: Int.self
        ) { size in
            blackHole(Array(0 ..< size))
        }
        

        addSimple(
            title: "Array<Int> sequential iteration",
            input: [Int].self
        ) { input in
            for i in input {
                blackHole(i)
            }
        }

        addSimple(
            title: "Array<Int> subscript get, random offsets",
            input: ([Int], [Int]).self
        ) { input, lookups in
            for i in lookups {
                blackHole(input[i])
            }
        }
        
        addSimple(
            title: "Array<Int> contains",
            input: ([Int], [Int]).self
        ) { input, lookups in
            for i in lookups {
                precondition(input.contains(i))
            }
        }

        addSimple(
            title: "Array<Int> offset of id",
            input: ([Int], [Int]).self
        ) { input, lookups in
            for i in lookups {
                _ = input.firstIndex(of: i)!
            }
        }

        addSimple(
            title: "Array<Int> append",
            input: [Int].self
        ) { input in
            var array: [Int] = []
            for i in input {
                array.append(i)
            }
            precondition(array.count == input.count)
            blackHole(array)
        }
        
        addSimple(
            title: "Array<Int> prepend",
            input: [Int].self
        ) { input in
            var array: [Int] = []
            for i in input {
                array.insert(i, at: 0)
            }
            blackHole(array)
        }
        
        add(
            title: "Array<Int> random insertions",
            input: Insertions.self
        ) { insertions in
            return { timer in
                let insertions = insertions.values
                var array: [Int] = []
                timer.measure {
                    for i in insertions.indices {
                        array.insert(i, at: insertions[i])
                    }
                }
                blackHole(array)
            }
        }
        
        add(
            title: "Array<Int> removeLast",
            input: Int.self
        ) { size in
            return { timer in
                var array = Array(0 ..< size)
                timer.measure {
                    for _ in 0 ..< size {
                        array.removeLast()
                    }
                }
                precondition(array.isEmpty)
                blackHole(array)
            }
        }
        
        add(
            title: "Array<Int> removeFirst",
            input: Int.self
        ) { size in
            return { timer in
                var array = Array(0 ..< size)
                timer.measure {
                    for _ in 0 ..< size {
                        array.removeFirst()
                    }
                }
                precondition(array.isEmpty)
                blackHole(array)
            }
        }
        
        add(
            title: "Array<Int> random remove",
            input: Insertions.self
        ) { insertions in
            let removals = insertions.values.reversed()
            return { timer in
                var array = Array(0 ..< removals.count)
                timer.measure {
                    for i in removals {
                        array.remove(at: i)
                    }
                }
                blackHole(array)
            }
        }
        
    }
    
}
