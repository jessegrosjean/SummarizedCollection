public struct Node<Context: TreeContext> {
    
    public typealias Element = Context.Element
    public typealias Summary = Context.Summary
    public typealias Slot = Context.Slot

    @usableFromInline
    struct Header {
        @usableFromInline
        let height: UInt8
        
        @usableFromInline
        let summary: Summary

        @usableFromInline
        let slotCount: Slot

        @usableFromInline
        let slotCapacity: Slot

        @inlinable
        var slotsAvailible: Slot { slotCapacity - slotCount }

        @inlinable
        var slotsUnderflowing: Bool { slotCount < (slotCapacity / 2) }
        
        @inlinable
        init(inner: InnerHeader, slotCount: Slot) {
            height = inner.height
            summary = inner.summary
            self.slotCount = slotCount // inner.slotCount
            slotCapacity = inner.slotCapacity
        }
        
        @inlinable
        init(leaf: LeafHeader, slotCount: Slot) {
            height = 0
            summary = leaf.summary
            self.slotCount = slotCount // leaf.slotCount
            slotCapacity = leaf.slotCapacity
        }
    }

    @usableFromInline
    var _header: Header

    @usableFromInline
    var _inner: InnerStorage?

    @usableFromInline
    var _leaf: LeafStorage?
 
    @inlinable
    var inner: InnerStorage { _inner.unsafelyUnwrapped }

    @inlinable
    var leaf: LeafStorage { _leaf.unsafelyUnwrapped }

    @inlinable
    var count: Int { _header.summary.count }

    @inlinable
    var summary: Summary { _header.summary }

    @inlinable
    var height: UInt8 { _header.height }

    @inlinable
    var slotCount: Slot { _header.slotCount }

    @inlinable
    var slotCapacity: Slot { _header.slotCapacity }

    @inlinable
    var slotsAvailible: Slot { _header.slotsAvailible }

    @inlinable
    var slotsUnderflowing: Bool { _header.slotsUnderflowing }

    @inlinable
    var isInner: Bool { _inner != nil }
    
    @inlinable
    var children: ArraySlice<Node> {
        rdInner { $0.slots }[...]
    }
    
    @inlinable
    var isLeaf: Bool { _leaf != nil }

    @inlinable
    var elements: ArraySlice<Element> {
        rdLeaf { $0.slots }[...]
    }

    @inlinable
    var isEmpty: Bool { summary.count == 0 }

    @inlinable
    init() {
        _leaf = .create()
        _header = .init(leaf: _leaf.unsafelyUnwrapped.header, slotCount: 0)
    }

    @inlinable
    init(inner: ContiguousArray<Node>) {
        self.init(inner: .init(slots: inner))
    }

    @inlinable
    init(inner: InnerStorage) {
        _inner = inner
        _header = .init(inner: inner.header, slotCount: inner.slotCount)
    }

    @inlinable
    init(leaf: ContiguousArray<Element>) {
        self.init(leaf: .init(slots: leaf))
    }

    @inlinable
    init(leaf: LeafStorage) {
        _leaf = leaf
        _header = .init(leaf: leaf.header, slotCount: leaf.slotCount)
    }

    @inlinable
    init(combining child1: Self, and child2: Self, ctx: inout Context) {
        assert(child1.height == child2.height)
        let height = child1.height
        self.init(inner: .create() { handle in
            handle.slotAppend(child1, ctx: &ctx)
            handle.slotAppend(child2, ctx: &ctx)
            handle.height = height + 1
        })
    }

    @inlinable
    init(copying node: Self) {
        if node.isInner {
            _inner = node.inner.copy()
            _header = .init(inner: node.inner.header, slotCount: node.slotCount)
        } else {
            _leaf = node.leaf.copy()
            _header = .init(leaf: node.leaf.header, slotCount: node.leaf.slotCount)
        }
    }

    @inlinable
    var objectIdentifier: ObjectIdentifier {
        if isInner {
            return ObjectIdentifier(inner)
        } else {
            return ObjectIdentifier(leaf)
        }
    }
    
}

extension Node: Equatable {
    
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        lhs._leaf === rhs._leaf && lhs._inner === rhs._inner
    }
    
}
