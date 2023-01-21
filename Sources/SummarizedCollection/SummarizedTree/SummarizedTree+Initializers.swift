extension SummarizedTree {
    
    @inlinable
    public init() {
        self.init(root: .init(), maintainBackpointersIfAble: true)
    }

    @inlinable
    init(root: Node, maintainBackpointersIfAble: Bool = false) {
        self.root = root
        self.context = .init(root: root, maintainBackpointersIfAble: maintainBackpointersIfAble)
        self.version = root.objectIdentifier.hashValue
    }

    @inlinable
    public init<S>(_ s: S) where Element == S.Element, S : RandomAccessCollection {
        var builder = Builder()
        builder.append(contentsOf: s)
        self = builder.build()
        self.context.addNode(root)
    }

    @inlinable
    public init<C>(_ c: C) where Element == C.Element, C : Collection {
        var builder = Builder()
        builder.append(contentsOf: ContiguousArray(c))
        self = builder.build()
        self.context.addNode(root)
    }

}

