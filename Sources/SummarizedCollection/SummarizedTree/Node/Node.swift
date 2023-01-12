public struct Node<Context: SummarizedTreeContext> {
    
    public typealias Element = Context.Element
    public typealias Summary = Context.Summary
    public typealias Slot = Context.Slot

    @usableFromInline
    struct Header {
        @usableFromInline
        var height: UInt8
        
        @usableFromInline
        var summary: Summary

        @usableFromInline
        var slotCount: Slot

        @usableFromInline
        var slotCapacity: Slot

        @inlinable
        var slotsAvailible: Slot { slotCapacity - slotCount }

        @inlinable
        var slotsUnderflowing: Bool { slotCount < (slotCapacity / 2) }
        
        @inlinable
        init(height: UInt8 = 0, summary: Summary = .zero, slotCount: Slot = .zero, slotCapacity: Slot) {
            self.height = height
            self.summary = summary
            self.slotCount = slotCount
            self.slotCapacity = slotCapacity
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
        _header = _leaf.unsafelyUnwrapped.header
    }

    @inlinable
    init(inner: ContiguousArray<Node>) {
        self.init(inner: .init(slots: inner))
    }

    @inlinable
    init(inner: InnerStorage) {
        _inner = inner
        _header = inner.header
    }

    @inlinable
    init(leaf: ContiguousArray<Element>) {
        self.init(leaf: .init(slots: leaf))
    }

    @inlinable
    init(leaf: LeafStorage) {
        _leaf = leaf
        _header = leaf.header
    }

    @inlinable
    init(combining child1: Self, and child2: Self, ctx: inout Context) {
        assert(child1.height == child2.height)
        let height = child1.height
        self.init(inner: .create() { handle in
            handle.slotAppend(child1, ctx: &ctx)
            handle.slotAppend(child2, ctx: &ctx)
            handle.header.height = height + 1
        })
    }

    @inlinable
    init(copying node: Self) {
        if node.isInner {
            _inner = node.inner.copy()
            _header = node.inner.header //.init(inner: node.inner.header, slotCount: node.slotCount)
        } else {
            _leaf = node.leaf.copy()
            _header = node.leaf.header
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
