extension SummarizedTree {
    
    @inlinable
    public init() {
        self.init(root: .init())
    }

    @inlinable
    init(root: Node) {
        self.root = root
        self.context = .init(root: root)
        self.version = root.objectIdentifier.hashValue
    }

    @inlinable
    public init<S>(_ s: S) where Element == S.Element, S : RandomAccessCollection {
        var builder = Builder()
        builder.concat(elements: s)
        self = builder.build()
    }

    @inlinable
    public init<C>(_ c: C) where Element == C.Element, C : Collection {
        var builder = Builder()
        builder.concat(elements: ContiguousArray(c))
        self = builder.build()
    }

}
