extension SummarizedTree {

    public struct Node {
        
        public typealias Element = Context.Element
        public typealias Summary = Context.Summary
        public typealias Slot = Context.Slot
        
        public struct Header {
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
        var _inner2: InnerStorage2?

        @usableFromInline
        var _leaf: LeafStorage?
    }
    
}

extension SummarizedTree.Node {
    
    @inlinable
    @inline(__always)
    public var inner: InnerStorage { _inner.unsafelyUnwrapped }

    @inlinable
    @inline(__always)
    public var inner2: InnerStorage2 { _inner2.unsafelyUnwrapped }

    @inlinable
    @inline(__always)
    public var leaf: LeafStorage { _leaf.unsafelyUnwrapped }

    @inlinable
    @inline(__always)
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
    @inline(__always)
    var isInner: Bool { _inner != nil }
    
    @inlinable
    var children: InnerStorage.Slice {
        inner.elements
    }

    @inlinable
    @inline(__always)
    var isLeaf: Bool { _leaf != nil }

    @inlinable
    var elements: LeafStorage.Slice {
        leaf.elements
    }

    @inlinable
    var isEmpty: Bool { summary.count == 0 }

    @inlinable
    init() {
        _leaf = .create()
        _header = _leaf.unsafelyUnwrapped.header
    }

    @inlinable
    init<C>(inner: C) where C: Collection, C.Element == Node {
        self.init(inner: InnerStorage.create { handle in
            handle.slotsAppend(inner)
        })
    }

    @inlinable
    init(inner: InnerStorage) {
        _inner = inner
        _header = inner.header
    }

    @inlinable
    init<C>(leaf: C) where C: Collection, C.Element == Element {
        self.init(leaf: .create(update: { handle in
            handle.slotsAppend(leaf)
        }))
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
        self.init(inner: InnerStorage.create { handle in
            handle.slotsAppend(child1, ctx: &ctx)
            handle.slotsAppend(child2, ctx: &ctx)
            handle.headerPtr.pointee.height = height + 1
        })
    }

    @inlinable
    init(copying node: Self) {
        if node.isInner {
            _inner = node.inner.copy()
            _header = node.inner.header
        } else {
            _leaf = node.leaf.copy()
            _header = node.leaf.header
        }
    }

    @inlinable
    @inline(__always)
    var objectIdentifier: ObjectIdentifier {
        if isInner {
            return ObjectIdentifier(inner)
        } else {
            return ObjectIdentifier(leaf)
        }
    }
    
}

extension SummarizedTree.Node: Equatable {
    
    public typealias Node = SummarizedTree.Node

    @inlinable
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        lhs._leaf === rhs._leaf && lhs._inner === rhs._inner
    }
    
}
