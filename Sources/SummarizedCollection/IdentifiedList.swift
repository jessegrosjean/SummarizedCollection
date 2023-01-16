public struct IdentifiedListContext<Element: Identifiable>: IdentifiedSummarizedTreeContext {

    public typealias Slot = UInt16
    public typealias Summary = IdentifiedListSummary<Element>

    public var maintainsBackpointers: Bool

    @usableFromInline
    var parents: [ObjectIdentifier : Unmanaged<TreeNode.InnerStorage>] = [:]
    
    @usableFromInline
    var elementsLookup: [Element.ID : Unmanaged<TreeNode.LeafStorage>] = [:]

    @inlinable
    public init(root: TreeNode?, maintainBackpointersIfAble: Bool) {
        self.maintainsBackpointers = maintainBackpointersIfAble
        if let root, maintainBackpointersIfAble {
            addNode(root)
        }
    }

    @inlinable
    public subscript(parentOf nodeIdentifier: ObjectIdentifier) -> TreeNode.InnerStorage? {
        get { parents[nodeIdentifier]?.takeUnretainedValue() }
        set {
            guard maintainsBackpointers else { return }
            parents[nodeIdentifier] = newValue.map { .passUnretained($0) }
        }
    }
    
    @inlinable
    public subscript(leafOf id: Element.ID) -> TreeNode.LeafStorage? {
        elementsLookup[id]?.takeUnretainedValue()
    }
            
    @inlinable
    public mutating func addElements<C>(_ elements: C, to leaf: TreeNode.LeafStorage) where C : Collection, C.Element == Element {
        guard maintainsBackpointers else { return }
        for each in elements {
            elementsLookup[each.id] = .passUnretained(leaf)
        }
    }
    
    @inlinable
    public mutating func removeElements<C>(_ elements: C, from leaf: TreeNode.LeafStorage) where C : Collection, C.Element == Element {
        guard maintainsBackpointers else { return }
        for each in elements {
            elementsLookup[each.id] = nil
        }
    }

}

public struct IdentifiedListSummary<Element: Identifiable>: CollectionSummary {
    public var count: Int
    
    @inlinable
    init(count: Int) {
        self.count = count
    }
    
    @inlinable
    public static var zero: Self {
        .init(count: 0)
    }
    
    @inlinable
    public static func summarize<C>(elements: C) -> Self where C : BidirectionalCollection, C.Element == Element {
        .init(count: elements.count)
    }
    
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(count: lhs.count + rhs.count)
    }
    
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(count: lhs.count - rhs.count)
    }
}

public typealias IdentifiedList<Element> = SummarizedTree<IdentifiedListContext<Element>> where Element: Identifiable
