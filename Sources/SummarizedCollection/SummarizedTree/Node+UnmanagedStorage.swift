extension SummarizedTree.Node {

    @inlinable
    var unmanaged: UnmanagedStorage {
        if isInner {
            return .inner(.passUnretained(inner))
        } else {
            return .leaf(.passUnretained(leaf))
        }
    }
    
    @usableFromInline
    enum UnmanagedStorage {
        
        case inner(Unmanaged<InnerStorage>)
        case leaf(Unmanaged<LeafStorage>)
                
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
            case .inner(let inner):
                return inner._withUnsafeGuaranteedRef { inner in
                    return inner.header
                }
            case .leaf(let leaf):
                return leaf._withUnsafeGuaranteedRef { leaf in
                    return leaf.header
                }
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
            if case .inner(let inner) = self {
                return inner._withUnsafeGuaranteedRef { $0.subSequence }
            }
            fatalError()
        }

        @inlinable
        @inline(__always)
        func child(at slot: Slot) -> Node {
            if case .inner(let inner) = self {
                return inner._withUnsafeGuaranteedRef { $0.rd { $0[slot] } }
            }
            fatalError()
        }

        @inlinable
        @inline(__always)
        func unmanagedStorage(at slot: Slot) -> UnmanagedStorage {
            if case .inner(let inner) = self {
                return inner._withUnsafeGuaranteedRef { $0.rd { $0[slot].unmanaged } }
            }
            fatalError()
        }

        @inlinable
        @inline(__always)
        var elements: LeafStorage.SubSequence {
            if case .leaf(let leaf) = self {
                return leaf._withUnsafeGuaranteedRef { $0.subSequence }
            }
            fatalError()
        }
        
        @inlinable
        @inline(__always)
        func element(at slot: Slot) -> Element {
            if case .leaf(let leaf) = self {
                return leaf._withUnsafeGuaranteedRef { $0.rd { $0[slot] } }
            }
            fatalError()
        }
    }
}

extension SummarizedTree.Node.UnmanagedStorage: Equatable {
    
    public typealias UnmanagedStorage = SummarizedTree.Node.UnmanagedStorage

    @inlinable
    public static func ==(lhs: UnmanagedStorage, rhs: UnmanagedStorage) -> Bool {
        switch (lhs, rhs) {
        case (.inner(let lstore), .inner(let rstore)):
            return lstore.toOpaque() == rstore.toOpaque()
        case (.leaf(let lstore), .leaf(let rstore)):
            return lstore.toOpaque() == rstore.toOpaque()
        default:
            return false
        }
    }
    
}
