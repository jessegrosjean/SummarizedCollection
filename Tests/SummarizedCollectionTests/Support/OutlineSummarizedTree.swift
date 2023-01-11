@testable import SummarizedCollection

struct OutlineContext: TreeContext {
    
    typealias Slot = UInt16
    typealias Summary = OutlineSummary
    
    static var maintainsBackpointers: Bool { false }
    
    subscript(parent node: ContextNode) -> ContextNode? {
        get { nil }
        set { }
    }
    
    mutating func mapElements<C>(_ elements: C, to leaf: ContextNode) where C : Collection, C.Element == Summary.Element {
    }
    
    mutating func unmapElements<C>(_ elements: C, from leaf: ContextNode) where C : Collection, C.Element == Summary.Element {
    }

    public init(root: ContextNode?) {
    }

}

typealias OutlineSummarizedTree = SummarizedTree<OutlineContext>
