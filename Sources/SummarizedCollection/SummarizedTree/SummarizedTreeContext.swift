public protocol SummarizedTreeContext {
    
    associatedtype Slot: FixedWidthInteger & UnsignedInteger
    associatedtype Summary: CollectionSummary
    
    typealias Element = Summary.Element
    typealias TrackedLeaf = SummarizedTree<Self>.TrackedLeaf
    typealias TrackedParent = SummarizedTree<Self>.TrackedParent

    static var innerCapacity: Slot { get }
    static var leafCapacity: Slot { get }
    
    init()

    var isTracking: Bool { get }
    var rootIdentifier: ObjectIdentifier? { get set }

    func isTracking(id: ObjectIdentifier) -> Bool

    mutating func reserveCapacity(_ n: Int)

    subscript(trackedLeafOf element: Element) -> TrackedLeaf? { get set }
    subscript(trackedParentOf id: ObjectIdentifier) -> TrackedParent? { get set }
    
    func validateInsert<C>(_ elements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element
    func validateReplace<C>(subrange: Range<Int>, with newElements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element

}

public protocol IdentifiedSummarizedTreeContext: SummarizedTreeContext where Element: Identifiable {

    func contains(id: Element.ID) -> Bool
    
    subscript(trackedLeafOf id: Element.ID) -> TrackedLeaf? { get }
    
}

extension SummarizedTreeContext {
    
    @usableFromInline
    typealias Node = SummarizedTree<Self>.Node

    @inlinable
    internal init(tracking root: Node) {
        self.init()
        
        self.rootIdentifier = root.objectIdentifier
        self.reserveCapacity(root.count)
        
        if isTracking {
            if root.isInner {
                SummarizedTree<Self>.Node.InnerStorageDelegate.addChildren(root.children, to: .passUnretained(root.inner), ctx: &self)
            } else {
                SummarizedTree<Self>.Node.LeafStorageDelegate.addElements(root.elements, to: .passUnretained(root.leaf), ctx: &self)
            }
        }
    }

}

extension SummarizedTree {

    public struct TrackedParent {
        @usableFromInline
        let inner: Unmanaged<Node.InnerStorage>

        @inlinable
        init(inner: Unmanaged<Node.InnerStorage>) {
            self.inner = inner
        }
        
    }

    public struct TrackedLeaf {
        @usableFromInline
        let inner: Unmanaged<Node.LeafStorage>

        @inlinable
        init(inner: Unmanaged<Node.LeafStorage>) {
            self.inner = inner
        }
    }
    
}
