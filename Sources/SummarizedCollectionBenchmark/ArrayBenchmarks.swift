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
        
        /*
        addSimple(
            title: "Array<Int> init from unsafe buffer",
            input: [Int].self
        ) { input in
            input.withUnsafeBufferPointer { buffer in
                blackHole(Array(buffer))
            }
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
            title: "Array<Int> successful contains",
            input: ([Int], [Int]).self
        ) { input, lookups in
            for i in lookups {
                precondition(input.contains(i))
            }
        }
        
         */
        
        
        add(
            title: "Array<Int> successful contains",
            input: Int.self
        ) { count in
            { timer in
                let array = Array(0..<count)
                let shuffled = (0..<count).shuffled()[0..<count / 10]
                
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "Array<Int> successful contains")
                    for i in shuffled {
                        precondition(array.contains(i))
                    }
                    OSLog.pointsOfInterest.end(name: "Array<Int> successful contains")
                }
            }
        }

        add(
            title: "Array<Int> successful offset(id:)",
            input: Int.self
        ) { count in
            { timer in
                let array = Array(0..<count)
                let shuffled = (0..<count).shuffled()[0..<count / 10]
                
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "Array<Int> successful firstIndex(where:)")
                    for i in shuffled {
                        precondition(array.firstIndex { $0 == i } == i)
                    }
                    OSLog.pointsOfInterest.end(name: "Array<Int> successful firstIndex(where:)")
                }
            }
        }
        
        /*
        addSimple(
            title: "Array<Int> unsuccessful contains",
            input: ([Int], [Int]).self
        ) { input, lookups in
            let c = input.count
            for i in lookups {
                precondition(!input.contains(i + c))
            }
        }
         
        add(
            title: "Array<Int> mutate through subscript",
            input: ([Int], [Int]).self
        ) { input, lookups in
            return { timer in
                var array = input
                array.reserveCapacity(0) // Ensure unique storage
                timer.measure {
                    var v = 0
                    for i in lookups {
                        array[i] = v
                        v += 1
                    }
                }
                blackHole(array)
            }
        }
        
        add(
            title: "Array<Int> random swaps",
            input: [Int].self
        ) { input in
            return { timer in
                var array = Array(0 ..< input.count)
                timer.measure {
                    var v = 0
                    for i in input {
                        array.swapAt(i, v)
                        v += 1
                    }
                }
                blackHole(array)
            }
        }
        
        add(
            title: "Array<Int> partitioning around middle",
            input: [Int].self
        ) { input in
            return { timer in
                let pivot = input.count / 2
                var array = input
                array.reserveCapacity(0) // Force unique storage
                timer.measure {
                    let r = array.partition(by: { $0 >= pivot })
                    precondition(r == pivot)
                }
                blackHole(array)
            }
        }
        
        add(
            title: "Array<Int> sort",
            input: [Int].self
        ) { input in
            return { timer in
                var array = input
                array.reserveCapacity(0) // Force unique storage
                timer.measure {
                    array.sort()
                }
                precondition(array.elementsEqual(0 ..< input.count))
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
            title: "Array<Int> append, reserving capacity",
            input: [Int].self
        ) { input in
            var array: [Int] = []
            array.reserveCapacity(input.count)
            for i in input {
                array.append(i)
            }
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
        
        addSimple(
            title: "Array<Int> prepend, reserving capacity",
            input: [Int].self
        ) { input in
            var array: [Int] = []
            array.reserveCapacity(input.count)
            for i in input {
                array.insert(i, at: 0)
            }
            blackHole(array)
        }
        
        addSimple(
            title: "Array<Int> kalimba",
            input: [Int].self
        ) { input in
            blackHole(input.kalimbaOrdered())
        }
        
        addSimple(
            title: "Array<Int> kalimba fast",
            input: [Int].self
        ) { input in
            blackHole(input.kalimbaOrdered3())
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
        */
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
        /*
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
            title: "Array<Int> random removals",
            input: Insertions.self
        ) { insertions in
            let removals = Array(insertions.values.reversed())
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
         */
        
        /*
        add(
            title: "Array<Int> splits",
            input: Int.self
        ) { size in
            return { timer in
                var array = Array(0 ..< size)
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "Array<Int> splits")
                    while array.count > 1 {
                        array = array.split(array.count / 2)
                    }
                    OSLog.pointsOfInterest.end(name: "Array<Int> splits")
                }
                precondition(array.count == 1)
                blackHole(array)
            }
        }
        
        add(
            title: "Array<Int> concats",
            input: Int.self
        ) { size in
            return { timer in
                var array = Array(0 ..< size)
                
                var splits: [Array<Int>] = []
                while array.count > 1 {
                    splits.append(Array(array.split(array.count / 2)))
                }
                
                splits.shuffle()
                
                timer.measure {
                    OSLog.pointsOfInterest.begin(name: "Array<Int> concats")
                    for each in splits {
                        //array.append(contentsOf: each)
                        array.insert(contentsOf: each, at: 0)
                    }
                    OSLog.pointsOfInterest.end(name: "Array<Int> concats")
                }
                
                precondition(array.count == size)
                blackHole(array)
            }
        }*/
        
    }
    
}

extension Array {
    
    mutating func split(_ index: Index) -> Self {
        let tail = Array(self[index...])
        self.removeSubrange(index...)
        return tail
    }
    
}
