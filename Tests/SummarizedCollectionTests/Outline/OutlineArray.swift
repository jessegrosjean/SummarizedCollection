@testable import SummarizedCollection

// Used to test inefficient default collection protocol implementations.
// Real code should be using SummarizedTree
struct OutlineArray: SummarizedCollection, IdentifiedCollection {
    
    typealias Element = Row
    typealias Index = Int
    typealias SubSequence = Array<Element>.SubSequence
    typealias Indices = Array<Element>.Indices
    typealias Summary = OutlineSummary

    var elements: Array<Element> = []

    init<S>(inner: S) where S: Sequence, S.Element == Element {
        self.elements = Array(inner)
    }
    
    subscript(position: Int) -> Element {
        _read { yield elements[position] }
    }

    subscript(bounds: Range<Index>) -> SubSequence {
        get { elements[bounds] }
        set { elements[bounds] = newValue }
    }
    
    func index(before i: Index) -> Index {
        elements.index(before: i)
    }

    func index(after i: Index) -> Index {
        elements.index(after: i)
    }

    var indices: Array<Int>.Indices {
        elements.indices
    }
    
    var startIndex: Index {
        elements.startIndex
    }
    
    var endIndex: Index {
        elements.endIndex
    }

}
