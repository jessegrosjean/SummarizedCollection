public struct SummarizedTree<Context: SummarizedTreeContext> {
    
    public typealias Context = Context
    public typealias Element = Context.Element
    public typealias Summary = Context.Summary
    
    @usableFromInline
    var version: Int
    
    @usableFromInline
    var context: Context
    
    @usableFromInline
    var root: Node

    @inlinable
    @inline(__always)
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

    @inlinable
    @inline(__always)
    public func index(at offset: Int) -> Index {
        index(startIndex, offsetBy: offset)
    }
    
    @inlinable
    @inline(__always)
    public func offset(of index: Index) -> Int {
        distance(from: startIndex, to: index)
    }

    @inlinable
    @inline(__always)
    public subscript(_offset offset: Int) -> Element {
        self[index(at: offset)]
    }
    
    // MARK: Cursor

    @inlinable
    public func cursor() -> Cursor {
        Cursor(root: root.unmanagedNode, version: version)
    }

    @inlinable
    public func cursor<D>(at dimension: D) -> Cursor where D: CollectionDimension, D.Summary == Summary {
        var cursor = Cursor(root: root.unmanagedNode, version: version)
        _ = cursor.seek(to: .init(base: dimension, offset: IndexDimension(0)))
        return cursor
    }

    @inlinable
    public func cursor<B, O>(at point: CollectionPoint<B, O>) -> Cursor where B.Summary == Summary {
        var cursor = Cursor(root: root.unmanagedNode, version: version)
        _ = cursor.seek(to: point)
        return cursor
    }
    
}
