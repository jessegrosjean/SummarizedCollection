@testable import SummarizedCollection

struct OutlineContext: SummarizedTreeContext {
    
    typealias Slot = UInt16
    typealias Summary = OutlineSummary
    
    var maintainsBackpointers: Bool { false }
    
    init(root: TreeNode?, maintainBackpointersIfAble: Bool) {
    }

}

typealias OutlineSummarizedTree = SummarizedTree<OutlineContext>
