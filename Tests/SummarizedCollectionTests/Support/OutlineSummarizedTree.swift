@testable import SummarizedCollection

struct OutlineContext: SummarizedTreeContext {
        
    typealias Slot = UInt16
    typealias Summary = OutlineSummary
    
    init() {}

}

typealias OutlineSummarizedTree = SummarizedTree<OutlineContext>
