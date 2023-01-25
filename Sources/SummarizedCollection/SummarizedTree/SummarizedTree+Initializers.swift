extension SummarizedTree {
    
    @inlinable
    public init() {
        self.init(root: .init())
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
    public init<S>(_ s: S) where Element == S.Element, S : RandomAccessCollection {
        var builder = Builder()
        builder.append(contentsOf: s)
        self = builder.build()
        context = .init(tracking: root)
    }

    @inlinable
    public init<C>(_ c: C) where Element == C.Element, C : Collection {
        var builder = Builder()
        builder.append(contentsOf: ContiguousArray(c))
        self = builder.build()
        context = .init(tracking: root)
    }

}

