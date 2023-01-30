extension SummarizedTree {
    
    @inlinable
    public init() {
        self.init(root: .init())
    }

    @inlinable
    public init<C>(_ c: C) where Element == C.Element, C : Collection {
        var builder = Builder()
        builder.append(contentsOf: c)
        self = builder.build()
        context = .init(tracking: root)
    }

    @inlinable
    init(root: Node) {
        self.root = root
        self.context = .init(tracking: root)
        self.version = root.objectIdentifier.hashValue
    }

    @inlinable
    init(untracked root: Node) {
        self.root = root
        self.context = Context.nonTracking
        self.version = root.objectIdentifier.hashValue
    }

    @inlinable
    init<C>(untracked nodes: C) where Node == C.Element, C : Collection {
        self.root = nodes.first!
        self.context = Context.nonTracking
        self.version = root.objectIdentifier.hashValue
        for each in nodes[nodes.index(after: nodes.startIndex)...] {
            concat(each)
        }        
    }

}

