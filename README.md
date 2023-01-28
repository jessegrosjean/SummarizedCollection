# SummarizedCollection

Swift SummarizedCollection based on b+tree.

Pretty good test coverage and a start at optimization, but no documentation or real world use yet. Not good if you want a turnkey solution, but hopefully useful if you already know this is the structure you need.

Interesting features:

- Generic sum type
- Immutable, persistent, COW, etc
- Optional backpointers to implement fast index(of)
- [Benchmarks](./results.html)

There are two ready to use structures `List<Element>` and `IdentifiedList<Identifiable>`. I think `IdentifiedList<Identifiable>` is probably most unique in that it's a shared structure log(n) list that also maintains backpointers for fast index lookup by Element ID. With more work you can use the generic `Summary` to build more complex lists such as Ropes or other structures where you need to search using different dimensions.   

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
