# SummarizedCollection

Swift SummarizedCollection based on b+tree.

Pretty good test coverage and a start at optimization, but no documentation or real world use yet.

Interesting features:

- Generic sum type
- Immutable, persistent, COW, etc
- Optional backpointers to implement fast index(of)
- [Benchmarks](./results.html)

Inspired by Xi Editor [tree.rs](https://github.com/xi-editor/xi-editor/blob/master/rust/rope/src/tree.rs) and [ropey](https://github.com/cessen/ropey). Also quite a bit of Swift code taken from [Swift Collections](https://github.com/apple/swift-collections).

Run and graph benchmarks:

``` 
swift run -c release SummarizedCollectionBenchmark run results --cycles 1
swift run -c release SummarizedCollectionBenchmark render results chart.png
swift run -c release SummarizedCollectionBenchmark library run results.json --library ./Sources/SummarizedCollectionBenchmark/SummaryTree.json --cycles 1
swift run -c release SummarizedCollectionBenchmark library render results.json --library ./Sources/SummarizedCollectionBenchmark/SummaryTree.json
```

Find Unused Code:

```
swift run periphery scan
```
