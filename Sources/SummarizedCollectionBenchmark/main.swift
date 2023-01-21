import CollectionsBenchmark
import OSLog

var benchmark = Benchmark(title: "SummarizedCollection")

struct IdentifiedItem: Identifiable {
    let id: Int
}

benchmark.addArrayBenchmarks()
benchmark.addSummarizedTreeBenchmarks()

/*
benchmark.addSimple(
  title: "IdentifiedList<IdentifiedItem> init from range",
  input: Int.self
) { size in
    blackHole(IdentifiedList((0 ..< size).map { IdentifiedItem(id: $0) }))
}

benchmark.addSimple(
  title: "Array<IdentifiedItem> init from range",
  input: Int.self
) { size in
    blackHole(Array((0 ..< size).map { IdentifiedItem(id: $0) }))
}
 */

/*
benchmark.add(
  title: "IdentifiedList<IdentifiedItem> index of",
  input: Int.self
) { size in
    return { timer in
        let size = 1000000
        var list = IdentifiedList((0 ..< size).map { IdentifiedItem(id: $0) })
        list.context.addNode(list.root)
        timer.measure {
            OSLog.pointsOfInterest.begin(name: "IdentifiedList index of")
            var count = 0
            for _ in 0..<size {
                for i in 0..<size {
                    assert(list.offset(id: i) == i)
                    count += 1
                }
            }
            assert(count == size * size)
            OSLog.pointsOfInterest.end(name: "IdentifiedList index of")
        }
        blackHole(list)
    }
}
*/

/*
benchmark.add(
  title: "Array<IdentifiedItem> index of",
  input: Int.self
) { size in
    return { timer in
        let size = size
        let array = Array((0 ..< size))
        timer.measure {
            OSLog.pointsOfInterest.begin(name: "Array index of")
            var count = 0
            for _ in 0..<size {
                for i in 0..<size {
                    assert(i == array.firstIndex { $0 == i })
                    count += 1
                }
            }
            OSLog.pointsOfInterest.end(name: "Array index of")
        }
        blackHole(array)
    }
}
*/




/*
benchmark.addSimple(
  title: "Array<Int> init from range",
  input: Int.self
) { size in
    OSLog.pointsOfInterest.begin(name: "Array<Int> init from range")
    let array = Array(0 ..< size)
    OSLog.pointsOfInterest.end(name: "Array<Int> init from range")
    blackHole(array)
}

benchmark.add(
  title: "Array<Int> splits",
  input: Int.self
) { size in
    return { timer in
        var array = Array(0 ..< size)
        timer.measure {
            OSLog.pointsOfInterest.begin(name: "Array<Int> splits")

            while array.count > 1 {
                let mid = array.count / 2
                let split = Array(array[mid...])
                array.removeSubrange(mid...)
                array = split
            }
            
            OSLog.pointsOfInterest.end(name: "Array<Int> splits")
        }
        precondition(array.count == 1)
        blackHole(array)
    }
}

benchmark.add(
  title: "Array<Int> concats",
  input: Int.self
) { size in
    return { timer in
        var array = Array(0 ..< size).map { "\($0)" }
        
        var splits: [Array<String>] = []
        while array.count > 1 {
            let mid = array.count / 2
            let split = Array(array[mid...])
            array.removeSubrange(mid...)
            splits.append(split)
        }
        
        timer.measure {
            OSLog.pointsOfInterest.begin(name: "Array<Int> concats")
            for each in splits {
                array.append(contentsOf: each)
            }
            OSLog.pointsOfInterest.end(name: "Array<Int> concats")
        }
        
        precondition(array.count == size)
        blackHole(array)
    }
}
*/


/*
benchmark.add(
  title: "List<Int> iterate with formIndex",
  input: Int.self
) { size in
    return { timer in
        let tree = List(0 ..< size)

        timer.measure {
            let end = tree.endIndex
            var i = tree.startIndex
            while i < end {
                tree.formIndex(after: &i)
            }
        }
        
        blackHole(tree)
    }
}

benchmark.add(
  title: "List<Int> iterate with iterator",
  input: Int.self
) { size in
    return { timer in
        let tree = List(0 ..< size)

        timer.measure {
            for _ in tree {
            }
        }
        
        blackHole(tree)
    }
}

benchmark.add(
  title: "List<Int>.Subsequence iterate with iterator",
  input: Int.self
) { size in
    return { timer in
        let tree = List(0 ..< size)
        
        if size > 1 {
            let sub = tree[tree.index(at: 1)..<tree.index(at: tree.count - 1)]
            var count = 0
            timer.measure {
                for _ in sub {
                    count += 1
                }
            }
            
            assert(count == size - 2)
        }
        
        blackHole(tree)
    }
}


*/

benchmark.main()
