# SummarizedCollection: Fast and Flexible Collections for Swift Using In-Memory B+Trees

### <a name="status">Status</a>

Good test coverage and benchmarks. No documentation or real world use. Plan to use for my own projects, would love any ideas or feedback you might have.

### <a name="overview">Overview</a>

This project provides an efficient in-memory B+tree implementation in pure Swift, and two useful collection types that use B+trees for their underlying storage.

- [`List<Element>`][List] implements a random-access collection of arbitrary elements. It is like `Array` in the standard library, but lookup, insertion and removal, and copy on write all have logarithmic complexity.

- [`IdentifiedList<Element: Identifiable>`][IdentifiedList] implements the same random-access collection as `List<Element>` but using `Identifiable` elements. In addition to maintaining the list it also tracks these element ID's in a dictionary. It is able to implement `contains(id: Element.ID)` in constant time and `offset(id: Element.ID)` in logarithmic time.    

- [`SummarizedTree<Context>`][SummarizedTree] is the underlying primitive collection that serves as base storage for the above collections. It is a general b+tree that can be customized through the provided context type.
    
    The context allows you to define your own `CollectionSummary` type. The List and IdentifiedList collections only summarize element count.
    
    With a custom summary type you can index and provide logarithmic search on attributes of your choosing. For example you could build a `Rope` and the summary type might include byteCount, charCount, and lineCount. This would allow you to convert between all these values in logarithmic time.
    
    The context also allows you to store additional state in the root of the tree and receive callbacks when elements and tree nodes are added and removed from the tree. This is how the IdentifiedList can implement efficient contains and offset implementations, by tracking additional information in the context.

### <a name="what">Why B+Trees?</a>

In memory B+Trees are a good compromise between the fast contiguous memory of an Array and the logarithmic properties of a tree. In a B+Tree all elements are stored in buffers of contiguous memory in the leaf level of the tree. A small b+tree will store all elements in a single buffer, just like an array.

As more elements are inserted the tree they will eventually overflow into multiple leaf nodes. Internal nodes will be added to create a balanced tree. This splitting and tree management add overhead, but also allow for the following properties:

1. Insertion and removal take logarithmic time.
2. Split and concat take logarithmic time and space.
3. Copy on write is takes logarithmic time and space.
4. Space is used granularly as you added and remove elements
5. With a custom summary type search logarithmically on multiple attributes. 

### <a name="what">When B+Trees?</a>

Array will always be faster for a small number of elements, and "small" is likely in the 1000's. But for most operations there is eventually a crossover point where the b+tree is faster and the array starts becoming exponentially slower. [Benchmarks](https://github.com/jessegrosjean/SummarizedCollection/tree/main/Sources/SummarizedCollectionBenchmark) can give you an idea of when those crossover points happen.

### <a name="inspiration">Inspiration</a>

- [Xi Editor](https://xi-editor.io/)
- [Ropey](https://github.com/cessen/ropey)
- [BTree](https://github.com/attaswift/BTree/)
- [Swift Collections](https://github.com/apple/swift-collections)

In particular Xi Editor re-introduced me to concept and benefits of b+trees. Ropey showed how to implement things a bit faster. BTree provided examples of how this might be done in Swift, and also provided a good README template! Swift Collections showed me more low level Swift code programming examples, many of which I've copied.
