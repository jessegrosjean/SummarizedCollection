public struct IdentifiedListContext<Element: Identifiable>: IdentifiedSummarizedTreeContext {
    
    public typealias Slot = UInt16
    public typealias Summary = IdentifiedListSummary<Element>

    @usableFromInline
    var rootIdentifier: ObjectIdentifier?
    
    @usableFromInline
    var parents: [ObjectIdentifier : Unmanaged<Node.InnerStorage>] = [:]
    
    @usableFromInline
    var elementsLookup: [Element.ID : Unmanaged<Node.LeafStorage>] = [:]

    @inlinable
    public init() {
        rootIdentifier = nil
    }

    @inlinable
    public init(tracking root: Node) {
        self.rootIdentifier = root.objectIdentifier
        if root.isInner {
            addChildren(root.children, to: .passUnretained(root.inner))
        } else {
            addElements(root.elements, to: .passUnretained(root.leaf))
        }
    }

    @inlinable
    public subscript(parentOf nodeIdentifier: ObjectIdentifier) -> Unmanaged<Node.InnerStorage>? {
        parents[nodeIdentifier]
    }
    
    @inlinable
    public subscript(parentOf id: Element.ID) -> Unmanaged<Node.LeafStorage>? {
        elementsLookup[id]
    }
    
    @inlinable
    public mutating func changed(rootIdentifier: ObjectIdentifier) {
        self.rootIdentifier = rootIdentifier
    }

    @inlinable
    public mutating func addChildren<C>(_ children: C, to inner: Unmanaged<Node.InnerStorage>) where C: Collection, C.Element == Node {
        let parentIdentifier = ObjectIdentifier(inner.takeUnretainedValue())
        
        guard isTrackedInContext(objectIdentifier: parentIdentifier) else {
            return
        }

        for each in children {
            parents[each.objectIdentifier] = inner
            
            if each.isInner {
                addChildren(each.children, to: .passUnretained(each.inner))
            } else {
                addElements(each.elements, to: .passUnretained(each.leaf))
            }
        }
    }
    
    @inlinable
    public mutating func removeChildren<C>(_ children: C, from inner: Unmanaged<Node.InnerStorage>) where C: Collection, C.Element == Node {
        let parentIdentifier = ObjectIdentifier(inner.takeUnretainedValue())
        
        guard isTrackedInContext(objectIdentifier: parentIdentifier) else {
            return
        }

        for each in children {
            parents[each.objectIdentifier] = nil
            
            if each.isInner {
                removeChildren(each.children, from: .passUnretained(each.inner))
            } else {
                removeElements(each.elements, from: .passUnretained(each.leaf))
            }
        }
    }
    
    @inlinable
    public mutating func addElements<C>(_ elements: C, to leaf: Unmanaged<Node.LeafStorage>) where C: Collection, C.Element == Element {
        let leafIdentifier = ObjectIdentifier(leaf.takeUnretainedValue())
        
        guard isTrackedInContext(objectIdentifier: leafIdentifier) else {
            return
        }

        for each in elements {
            elementsLookup[each.id] = leaf
        }
    }
    
    @inlinable
    public mutating func removeElements<C>(_ elements: C, from leaf: Unmanaged<Node.LeafStorage>) where C: Collection, C.Element == Element {
        let leafIdentifier = ObjectIdentifier(leaf.takeUnretainedValue())
        
        guard isTrackedInContext(objectIdentifier: leafIdentifier) else {
            return
        }
        
        for each in elements {
            elementsLookup[each.id] = nil
        }
    }

    @inlinable
    func isTrackedInContext(objectIdentifier: ObjectIdentifier) -> Bool {
        return objectIdentifier == rootIdentifier || parents.keys.contains(objectIdentifier)
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
