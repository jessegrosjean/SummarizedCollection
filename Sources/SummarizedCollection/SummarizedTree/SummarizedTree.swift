public struct SummarizedTree<Context: SummarizedTreeContext> {
    
    public typealias Context = Context
    public typealias Element = Context.Element
    public typealias Summary = Context.Summary
    
    @usableFromInline
    var version: Int
    
    @usableFromInline
    var context: Context
    
    @usableFromInline
    var root: Node<Context>

    @inlinable
    public var isEmpty: Bool {
        root.summary.count == 0
    }

    @inlinable
    public var height: UInt8 {
        root.height
    }

    @inlinable
    mutating func invalidateIndices() {
        version &+= 1
    }
    
    public func ensureValid() {
        root.ensureValid(parent: nil, ctx: context)
    }

    // MARK: Cursor

    public func cursor() -> Cursor {
        Cursor(root: root, version: version)
    }

    public func cursor<D>(at dimension: D) -> Cursor where D: CollectionDimension, D.Summary == Summary {
        var cursor = Cursor(root: root, version: version)
        _ = cursor.seek(to: .init(base: dimension, offset: IndexDimension(0)))
        return cursor
    }

    public func cursor<B, O>(at point: CollectionPoint<B, O>) -> Cursor where B.Summary == Summary {
        var cursor = Cursor(root: root, version: version)
        _ = cursor.seek(to: point)
        return cursor
    }
    
}
