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
        var _leaf: LeafStorage?
    }
    
}

extension SummarizedTree.Node {
    
    @inlinable
    @inline(__always)
    public var inner: InnerStorage { _inner.unsafelyUnwrapped }

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
    var children: InnerStorage.SubSequence {
        inner.subSequence
    }

    @inlinable
    @inline(__always)
    var isLeaf: Bool { _leaf != nil }

    @inlinable
    var elements: LeafStorage.SubSequence {
        leaf.subSequence
    }

    @inlinable
    var isEmpty: Bool { summary.count == 0 }

    @inlinable
    init() {
        _leaf = .create(with: Context.leafCapacity)
        _header = _leaf.unsafelyUnwrapped.header
    }

    @inlinable
    init<C>(inner: C) where C: Collection, C.Element == Node {
        self.init(inner: InnerStorage.create(with: Context.innerCapacity) { handle in
            handle.append(contentsOf: inner, ctx: &Context.nonTracking)
        })
    }

    @inlinable
    init(inner: InnerStorage) {
        _inner = inner
        _header = inner.header
    }

    @inlinable
    init<C>(leaf: C) where C: Collection, C.Element == Element {
        self.init(leaf: .create(with: Context.leafCapacity) { handle in
            handle.append(contentsOf: leaf, ctx: &Context.nonTracking)
        })
    }

    @inlinable
    init(leaf: LeafStorage) {
        _leaf = leaf
        _header = leaf.header
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
