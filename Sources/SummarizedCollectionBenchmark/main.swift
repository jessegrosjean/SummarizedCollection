import CollectionsBenchmark
import OSLog

var benchmark = Benchmark(title: "SummarizedCollection")

benchmark.addArrayBenchmarks()
benchmark.addSummarizedTreeBenchmarks()
benchmark.addSummarizedTreeIdentifiedListBenchmarks()

benchmark.main()
