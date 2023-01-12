extension SummarizedTree.Node {

    @usableFromInline
    enum UnmanagedStorage {
        
        case inner(Unmanaged<InnerStorage>)
        case leaf(Unmanaged<LeafStorage>)
        
        @inlinable
        init(_ node: Node) {
            if node.isInner {
                self = .inner(.passUnretained(node.inner))
            } else {
                self = .leaf(.passUnretained(node.leaf))
            }
        }
        
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
        var children: ArraySlice<Node> {
            if case .inner(let inner) = self {
                return inner._withUnsafeGuaranteedRef { $0.rd { $0.slots[...] } }
            }
            fatalError()
        }

        @inlinable
        func child(at slot: Slot) -> Node {
            if case .inner(let inner) = self {
                return inner._withUnsafeGuaranteedRef { $0.rd { $0[slot] } }
            }
            fatalError()
        }

        @inlinable
        var elements: ArraySlice<Element> {
            if case .leaf(let leaf) = self {
                return leaf._withUnsafeGuaranteedRef { $0.rd { $0.slots[...] } }
            }
            fatalError()
        }
        
        @inlinable
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
