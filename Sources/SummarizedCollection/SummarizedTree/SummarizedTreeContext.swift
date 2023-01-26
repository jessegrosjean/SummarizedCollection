public protocol SummarizedTreeContext {
    
    associatedtype Slot: FixedWidthInteger & UnsignedInteger
    associatedtype Summary: CollectionSummary
    
    typealias Element = Summary.Element
    typealias TreeNode = SummarizedTree<Self>.Node
    typealias Node = SummarizedTree<Self>.Node
    
    static var innerCapacity: Slot { get }
    static var leafCapacity: Slot { get }
    
    init()
    init(tracking: Node)

    var isTracking: Bool { get }
    var rootIdentifier: ObjectIdentifier? { get set }

    func isTracking(id: ObjectIdentifier) -> Bool

    mutating func reserveCapacity(_ n: Int)

    subscript(trackedParentOf id: ObjectIdentifier) -> Unmanaged<Node.InnerStorage>? { get set }
    subscript(trackedParentOf element: Element) -> Unmanaged<Node.LeafStorage>? { get set }
    
    func validateInsert<C>(_ elements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element
    func validateReplace<C>(subrange: Range<Int>, with newElements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element

}

public protocol IdentifiedSummarizedTreeContext: SummarizedTreeContext where Element: Identifiable {

    func contains(id: Element.ID) -> Bool
    
    subscript(trackedParentOf id: Element.ID) -> Unmanaged<Node.LeafStorage>? { get }
    
}
