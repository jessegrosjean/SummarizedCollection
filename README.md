# SummarizedCollection: Flexible Collections for Swift Using In-Memory B+Trees

### <a name="status">Status</a>

Good test coverage and benchmarks. No documentation or real world use. Plan to use for my own projects. API Breaking changes likely.

Unless you are already interested in b+trees you probably don't want to use this project. At the same time I think the foundation is good and can do things that aren't possible in Swift without duplicating much of this effort.

Would love any ideas or feedback.

### <a name="overview">Overview</a>

This project provides an in memory positional (keyless) b+tree implementation in Swift. The project also includes two useful collection types that use the b+tree as their underlying storage.

- `List<Element>` implements a random-access collection of arbitrary elements. It is like Array in the standard library, but lookup, insertion and removal, and copy on write all have logarithmic complexity.

- `IdentifiedList<Element: Identifiable>` implements the same random-access collection as List<Element> but using Identifiable elements. In addition to maintaining the list it also tracks these element ID's in a dictionary. It is able to implement contains(id: Element.ID) in constant time and offset(id: Element.ID) in logarithmic time.    

- `SummarizedTree<Context>` is the underlying primitive collection that serves as base storage for the above collections. It is a general b+tree that can be customized through the provided context type.
    
    The context allows you to define your own CollectionSummary type. The List and IdentifiedList collections only summarize element count.
    
    With a custom summary type you can index and provide logarithmic search on attributes of your choosing. For example you could build a Rope and the summary type might include byteCount, charCount, and lineCount. This would allow you to convert between all these values in logarithmic time.
    
    The context also allows you to store additional state in the root of the tree and receive callbacks when elements and tree nodes are added and removed from the tree. This is how the IdentifiedList can implement efficient contains and offset implementations, by tracking additional information in the context.

### <a name="what">Why B+Trees?</a>

In memory b+trees are a compromise between the fast contiguous memory of an Array and the logarithmic properties of a tree. In a b+tree all elements are stored in buffers of contiguous memory in the tree's leaves. A small b+tree will have a single leaf and store all elements in one buffer.

As more elements are inserted the leaf will eventually overflow into multiple leaves. Internal nodes are added to create a balanced tree. This splitting and tree management add overhead, but also allow for the following properties:

1. Insertion and removal take logarithmic time.
2. Split and concat take logarithmic time and space.
3. Copy on write is takes logarithmic time and space.
4. Space is used granularly as you added and remove elements
5. With a custom summary type search logarithmically on multiple attributes. 

### <a name="what">When B+Trees?</a>

Array will always be faster for a small number of elements, and "small" is likely in the 1000's. For most mutating operations (and search) there is eventually a crossover point where the b+tree becomes faster. These [Benchmarks](http://htmlpreview.github.io/?https://github.com/jessegrosjean/SummarizedCollection/blob/main/Sources/SummarizedCollectionBenchmark/results.html) can give you an idea of when those crossover points happen.

### <a name="inspiration">Inspiration</a>

- [Xi Editor](https://xi-editor.io/)
- [Ropey](https://github.com/cessen/ropey)
- [BTree](https://github.com/attaswift/BTree/)
- [Swift Collections](https://github.com/apple/swift-collections)

### <a name="future">Future</a>

I'm hopeful that the Swift Collections ([here's a start](https://github.com/apple/swift-collections/pull/264)!) project will release a similar data structure. It will probably be better implemented, documented, and supported.

It's also likely that it won't be as tailored to my own wants as this project. My expectation is that I'll keep this project going for my own use and try to copy over any improvements from the Swift Collections code.
