# Benchmarks

[View Benchmarks](http://htmlpreview.github.io/?https://github.com/jessegrosjean/SummarizedCollection/blob/main/Sources/SummarizedCollectionBenchmark/results.html). These benchmarks might go out of date. Best to run them yourself if you really think you might use this collection.

## Run Benchmarks

```
swift run -c release SummarizedCollectionBenchmark run results --cycles 1
swift run -c release SummarizedCollectionBenchmark render results chart.png
swift run -c release SummarizedCollectionBenchmark library run results.json --library ./Sources/SummarizedCollectionBenchmark/SummaryTree.json --cycles 1
swift run -c release SummarizedCollectionBenchmark library render results.json --library ./Sources/SummarizedCollectionBenchmark/SummaryTree.json
```
