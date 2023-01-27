extension SummarizedTree.Node {
    
    @inlinable
    var unmanagedNode: UnmanagedNode {
        if isInner {
            
            return .inner(_header, .passUnretained(inner))
        } else {
            return .leaf(_header, .passUnretained(leaf))
        }
    }
    
    @usableFromInline
    enum UnmanagedNode {
        
        case inner(Header, Unmanaged<InnerStorage>)
        case leaf(Header, Unmanaged<LeafStorage>)
        
        @inlinable
        var isInner: Bool {
            if case .inner = self {
                return true
            }
            return false
        }
        
        @inlinable
        var isLeaf: Bool {
            if case .inner = self {
                return true
            }
            return false
        }
        
        @inlinable
        var header: Header {
            switch self {
            case .inner(let header, _):
                return header
            case .leaf(let header, _):
                return header
            }
        }
        
        @inlinable
        var count: Int {
            header.summary.count
        }
        
        @inlinable
        var slotCount: Slot {
            header.slotCount
        }
        
        @inlinable
        var summary: Summary {
            header.summary
        }
        
        @inlinable
        var children: InnerStorage.SubSequence {
            if case .inner(_, let inner) = self {
                return inner._withUnsafeGuaranteedRef { $0.subSequence }
            }
            fatalError()
        }
        
        @inlinable
        @inline(__always)
        func child(at slot: Slot) -> Node {
            if case .inner(_, let inner) = self {
                return inner._withUnsafeGuaranteedRef { $0.rd { $0[slot] } }
            }
            fatalError()
        }
        
        @inlinable
        @inline(__always)
        func unmanagedChild(at slot: Slot) -> UnmanagedNode {
            if case .inner(_, let inner) = self {
                return inner._withUnsafeGuaranteedRef { $0.rd { $0[slot].unmanagedNode } }
            }
            fatalError()
        }
        
        @inlinable
        @inline(__always)
        var elements: LeafStorage.SubSequence {
            if case .leaf(_, let leaf) = self {
                return leaf._withUnsafeGuaranteedRef { $0.subSequence }
            }
            fatalError()
        }
        
    }
    
}

extension SummarizedTree.Node.UnmanagedNode: Equatable {
    
    @usableFromInline
    typealias UnmanagedNode = SummarizedTree.Node.UnmanagedNode

    @inlinable
    static func ==(lhs: UnmanagedNode, rhs: UnmanagedNode) -> Bool {
        switch (lhs, rhs) {
        case (.inner(_, let lstore), .inner(_, let rstore)):
            return lstore.toOpaque() == rstore.toOpaque()
        case (.leaf(_, let lstore), .leaf(_, let rstore)):
            return lstore.toOpaque() == rstore.toOpaque()
        default:
            return false
        }
    }
    
}
