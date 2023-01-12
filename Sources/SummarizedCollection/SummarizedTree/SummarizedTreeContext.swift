public protocol SummarizedTreeContext {
    
    associatedtype Slot: FixedWidthInteger & UnsignedInteger
    associatedtype Summary: CollectionSummary

    typealias Element = Summary.Element
    typealias TreeNode = SummarizedTree<Self>.Node

    init(root: TreeNode?)

    // TreeNodes are shared and immutable. If we want backpointers
    // to quickly find summarized values for a given Element.ID then
    // need to maintain backpointers in Tree.Context
    static var maintainsBackpointers: Bool { get }
    subscript(parent node: TreeNode) -> TreeNode? { get set }
    mutating func mapElements<C: Collection>(_ elements: C, to leaf: TreeNode) where C.Element == Element
    mutating func unmapElements<C: Collection>(_ elements: C, from leaf: TreeNode) where C.Element == Element

}

extension SummarizedTreeContext where Element: Identifiable {

    subscript(leafContaining id: Element.ID) -> TreeNode? {
        nil
    }

}

extension SummarizedTreeContext {

    @inlinable
    static var innerCapacity: Slot {
        #if DEBUG
            return 3
        #else
            let capacityInBytes = 16383
            return Slot(Swift.max(16, capacityInBytes / MemoryLayout<TreeNode>.stride))
        #endif
    }
    
    @inlinable
    static var leafCapacity: Slot {
        #if DEBUG
            return 3
        #else
            let capacityInBytes = 16383
            return Slot(Swift.max(16, capacityInBytes / MemoryLayout<Element>.stride))
        #endif
    }

}
