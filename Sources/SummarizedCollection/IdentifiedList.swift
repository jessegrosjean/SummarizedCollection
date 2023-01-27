import Foundation

public typealias IdentifiedList<Element> = SummarizedTree<IdentifiedListContext<Element>> where Element: Identifiable

public struct IdentifiedListContext<Element: Identifiable>: IdentifiedSummarizedTreeContext {
    
    public typealias Slot = UInt16
    public typealias Summary = IdentifiedListSummary<Element>

    public var rootIdentifier: ObjectIdentifier?
    
    @usableFromInline
    var parents: [ObjectIdentifier : TrackedParent] = [:]
    
    @usableFromInline
    var elementsLookup: [Element.ID : TrackedLeaf] = [:]

    @inlinable
    public init() {
        rootIdentifier = nil
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
        
        // This isn't right, jesse brain too small
        
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
    public subscript(trackedParentOf id: ObjectIdentifier) -> TrackedParent? {
        get {
            parents[id]
        }
        set {
            parents[id] = newValue
        }
    }
    
    @inlinable
    public subscript(trackedLeafOf element: Element) -> TrackedLeaf? {
        get {
            elementsLookup[element.id]
        }
        set {
            elementsLookup[element.id] = newValue
        }
    }

    @inlinable
    public subscript(trackedLeafOf id: Element.ID) -> TrackedLeaf? {
        get {
            elementsLookup[id]
        }
        set {
            elementsLookup[id] = newValue
        }
    }
    
    @inlinable
    public func validateInsert<C>(_ elements: C, in _: SummarizedTree<Self>) where C : Collection, C.Element == Element {
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

#if DEBUG
extension IdentifiedListContext: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var result = ""
        result += "parents: {\n"
        for each in parents.keys {
            result += "  \(each): \(parents[each]!.inner.toOpaque())\n"
        }
        result += "}\n"

        result += "elements: {\n"
        for each in elementsLookup.keys {
            result += "  \(each): \(elementsLookup[each]!.inner.toOpaque())\n"
        }
        result += "}"

        return result
    }

}
#endif

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
