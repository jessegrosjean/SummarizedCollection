import CollectionsBenchmark
import SummarizedCollection

var benchmark = Benchmark(title: "SummarizedCollection")

benchmark.addSimple(
  title: "TreeList<Int> init from range",
  input: Int.self
) { size in
    blackHole(List(0 ..< size))
}

benchmark.add(
  title: "TreeList<Int> splits",
  input: Int.self
) { size in
    return { timer in
        var tree = List(0 ..< size)
        timer.measure {
            while tree.count > 1 {
                tree = tree.split(tree.count / 2)
            }
        }
        precondition(tree.count == 1)
        blackHole(tree)
    }
}

benchmark.add(
  title: "TreeList<Int> concats",
  input: Int.self
) { size in
    return { timer in
        var tree = List(0 ..< size)

        var splits: [List<Int>] = []
        while tree.count > 1 {
            splits.append(tree.split(tree.count / 2))
        }

        timer.measure {
            for each in splits {
                tree.concat(each)
            }
        }
        
        precondition(tree.count == size)
        blackHole(tree)
    }
}

benchmark.add(
  title: "TreeList<Int> iterate",
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




/*
benchmark.add(
  title: "Array<Int> splits",
  input: Int.self
) { size in
    return { timer in
        var array = Array(0 ..< size)
        timer.measure {
            while array.count > 1 {
                let mid = array.count / 2
                let split = Array(array[mid...])
                array.removeSubrange(mid...)
                array = split
            }
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
            for each in splits {
                array.append(contentsOf: each)
            }
        }
        
        precondition(array.count == size)
        blackHole(array)
    }
}
*/

benchmark.main()
