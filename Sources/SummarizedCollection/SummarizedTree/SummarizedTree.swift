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
    public func index(at offset: Int) -> Index {
        index(startIndex, offsetBy: offset)
    }

    @inlinable
    @inline(__always)
    public func indexRange(from offsetRange: Range<Int>) -> Range<Index> {
        let startIndex = index(at: offsetRange.startIndex)
        if offsetRange.isEmpty {
            return startIndex..<startIndex
        } else {
            let endIndex = index(startIndex, offsetBy: offsetRange.count)
            return startIndex..<endIndex
        }
    }

    @inlinable
    @inline(__always)
    public func offsetRange(from indexRange: Range<Index>) -> Range<Int> {
        let startIndex = indexRange.lowerBound.offset
        if indexRange.isEmpty {
            return startIndex..<startIndex
        } else {
            let endIndex = indexRange.upperBound.offset
            return startIndex..<endIndex
        }
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
    
    // MARK: Package

    @inlinable
    @inline(__always)
    var height: UInt8 {
        root.height
    }
    
    @inlinable
    func ensureValid() {
        root.ensureValid(parent: nil, ctx: context)
    }

    @inlinable
    mutating func invalidateIndices() {
        version &+= 1
    }

    @inlinable
    mutating func pullUpUnderflowingRoot() {
        while !root.isLeaf && root.slotCount == 1 {
            root = root.rdInner { handle in
                let child = handle[0]
                
                if context.isTracking {
                    let childId = child.objectIdentifier
                    context[trackedParentOf: childId] = nil
                    context.rootIdentifier = child.objectIdentifier
                }

                return child
            }
        }
    }

    @inlinable
    mutating func pushDownOverflowingRoot(overflow: Node) {
        assert(root.height == overflow.height)
        let pushed = root
        
        root = .init(inner: .create(with: Context.innerCapacity))
        
        if context.isTracking {
            context.rootIdentifier = root.objectIdentifier
        }
        
        root.mutInner(isUnique: true, ctx: &context) { handle, ctx in
            handle.append(pushed, ctx: &ctx)
            handle.append(overflow, ctx: &ctx)
        }
    }
        
}

#if DEBUG
extension SummarizedTree: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var result = ""
        result.append(root.debugDescription)
        result.append("\(context)")
        return result
    }

}
#endif
