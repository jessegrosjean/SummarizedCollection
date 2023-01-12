@testable import SummarizedCollection

struct OutlineContext: SummarizedTreeContext {
    
    typealias Slot = UInt16
    typealias Summary = OutlineSummary
    
    static var maintainsBackpointers: Bool { false }
    
    subscript(parent node: TreeNode) -> TreeNode? {
        get { nil }
        set { }
    }
    
    mutating func mapElements<C>(_ elements: C, to leaf: TreeNode) where C : Collection, C.Element == Summary.Element {
    }
    
    mutating func unmapElements<C>(_ elements: C, from leaf: TreeNode) where C : Collection, C.Element == Summary.Element {
    }

    public init(root: TreeNode?) {
    }

}

typealias OutlineSummarizedTree = SummarizedTree<OutlineContext>
