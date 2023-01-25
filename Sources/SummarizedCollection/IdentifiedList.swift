import Foundation

public struct IdentifiedListContext<Element: Identifiable>: IdentifiedSummarizedTreeContext {
    
    public typealias Slot = UInt16
    public typealias Summary = IdentifiedListSummary<Element>

    public var rootIdentifier: ObjectIdentifier?
    
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
        self.reserveCapacity(root.count)
        if root.isInner {
            SummarizedTree<Self>.Node.InnerStorageDelegate.addChildren(root.children, to: .passUnretained(root.inner), ctx: &self)
        } else {
            SummarizedTree<Self>.Node.LeafStorageDelegate.addElements(root.elements, to: .passUnretained(root.leaf), ctx: &self)
        }
    }
    
    @inlinable
    public func isTracking(id: ObjectIdentifier) -> Bool {
        rootIdentifier != nil && (rootIdentifier == id || parents.keys.contains(id))
    }

    @inlinable
    public func contains(id: Element.ID) -> Bool {
        elementsLookup.keys.contains(id)
    }

    @inlinable
    public mutating func reserveCapacity(_ n: Int) {
        guard isTracking && elementsLookup.capacity < n else {
            return
        }
        
        // This isn't right, jesse brain to small
        
        func logN(base: Double, value: Double) -> Double {
            return log(value) / log(base)
        }
        
        let innerCapacity = Double(Self.innerCapacity)
        let leaves = (Double(n) / Double(Self.leafCapacity)).rounded(.awayFromZero)
        let height = logN(base: innerCapacity, value: leaves).rounded(.down) + 1
        let nodes = (pow(innerCapacity, height)) - 1
        let total = Int(leaves + nodes)
        
        parents.reserveCapacity(total)
        elementsLookup.reserveCapacity(n)
    }

    @inlinable
    public subscript(trackedParentOf id: ObjectIdentifier) -> Unmanaged<Node.InnerStorage>? {
        get {
            parents[id]
        }
        set {
            parents[id] = newValue
        }
    }
    
    @inlinable
    public subscript(trackedParentOf element: Element) -> Unmanaged<Node.LeafStorage>? {
        get {
            elementsLookup[element.id]
        }
        set {
            elementsLookup[element.id] = newValue
        }
    }

    @inlinable
    public subscript(trackedParentOf id: Element.ID) -> Unmanaged<Node.LeafStorage>? {
        get {
            elementsLookup[id]
        }
        set {
            elementsLookup[id] = newValue
        }
    }
    
    @inlinable
    public func validateInsert<C>(_ elements: C, in tree: SummarizedTree<Self>) where C : Collection, C.Element == Element {
        for each in elements {
            assert(!elementsLookup.keys.contains(each.id))
        }
    }
    
    @inlinable
    public func validateReplace<C>(
        subrange: Range<Int>,
        with newElements: C,
        in tree: SummarizedTree<Self>
    ) where C : Collection, C.Element == Element {
        var replacing: Set<Element.ID>?
        for each in newElements {
            if elementsLookup.keys.contains(each.id) {
                replacing = replacing ?? Set(tree[subrange].map { $0.id })
                if replacing!.contains(each.id) {
                    replacing!.remove(each.id)
                } else {
                    assert(false)
                }
            }
        }
    }
    
}

//#if DEBUG
extension IdentifiedListContext: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var result = ""
        result += "parents: {\n"
        for each in parents.keys {
            result += "  \(each): \(parents[each]!.toOpaque())\n"
        }
        result += "}\n"

        result += "elements: {\n"
        for each in elementsLookup.keys {
            result += "  \(each): \(elementsLookup[each]!.toOpaque())\n"
        }
        result += "}"

        return result
    }

}
//#endif


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
