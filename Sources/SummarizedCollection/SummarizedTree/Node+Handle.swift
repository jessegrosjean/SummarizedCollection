@usableFromInline
enum Distribute {

    case even
    case compact
    
    @inlinable
    func partitionIndex<Number: BinaryInteger>(total: Number, capacity: Number) -> Number {
        switch self {
        case .even:
            return (total + 1) / 2
        case .compact:
            return capacity
        }
    }

}

extension SummarizedTree.Node {
    
    @inlinable
    @inline(__always)
    func rdInner<R>(_ body: (InnerStorage.Handle) throws -> R) rethrows -> R {
        try inner.rd { try body($0) }
    }
    
    @inlinable
    @inline(__always)
    func rdLeaf<R>(_ body: (LeafStorage.Handle) throws -> R) rethrows -> R {
        try leaf.rd { try body($0) }
    }

    @inlinable
    @inline(__always)
    mutating func mutInner<R>(
        isUnique: Bool? = nil,
        ctx: inout Context,
        body: (InnerStorage.Handle, inout Context) throws -> R
    ) rethrows -> R {
        ensureUnique(isUnique, ctx: &ctx)
        defer { updateFromStorage() }
        return try inner.mut { try body($0, &ctx) }
    }

    @inlinable
    @inline(__always)
    mutating func mutInner<R>(
        with node: inout Self,
        ctx: inout Context,
        body: (InnerStorage.Handle, InnerStorage.Handle, inout Context) throws -> R
    ) rethrows -> R {
        try mutInner(ctx: &ctx) { handle, ctx in
            try node.mutInner(ctx: &ctx) { nodeHandle, ctx in
                return try body(handle, nodeHandle, &ctx)
            }
        }
    }
    
    @inlinable
    @inline(__always)
    mutating func mutLeaf<R>(
        isUnique: Bool? = nil,
        ctx: inout Context,
        body: (LeafStorage.Handle, inout Context) throws -> R
    ) rethrows -> R {
        ensureUnique(isUnique, ctx: &ctx)
        defer { updateFromStorage() }
        return try leaf.mut { try body($0, &ctx) }
    }

    @inlinable
    @inline(__always)
    mutating func mutLeaf<R>(
        with node: inout Self,
        ctx: inout Context,
        body: (LeafStorage.Handle, LeafStorage.Handle, inout Context) throws -> R) rethrows -> R
    {
        try mutLeaf(ctx: &ctx) { handle, ctx in
            try node.mutLeaf(ctx: &ctx) { nodeHandle, ctx in
                return try body(handle, nodeHandle, &ctx)
            }
        }
    }
    
    @inlinable
    @inline(__always)
    mutating func updateFromStorage() {
        if isInner {
            _header = inner.header
        } else {
            _header = leaf.header
        }
    }
    
    @inlinable
    mutating func isUnique() -> Bool {
        if isInner {
            return isKnownUniquelyReferenced(&_inner)
        } else if isKnownUniquelyReferenced(&_leaf) {
            return true
        }
        return false
    }

    @inlinable
    mutating func ensureUnique(_ isUnique: Bool? = nil, ctx: inout Context) {
        if let isUnique = isUnique {
            if !isUnique {
                copy(ctx: &ctx)
            }
        } else if !self.isUnique() {
            copy(ctx: &ctx)
        }
    }

    //@usableFromInline
    //var rootIdentifier: ObjectIdentifier?
    
    //@usableFromInline
    //var parents: [ObjectIdentifier : Unmanaged<Node.InnerStorage>] = [:]
    
    //@usableFromInline
    //var elementsLookup: [Element.ID : Unmanaged<Node.LeafStorage>] = [:]

    
    @inlinable
    mutating func copy(ctx: inout Context) {
        let id = objectIdentifier
        let isRoot = ctx.rootIdentifier == id
        let isTracking = ctx.isTracking(id: id)
        let parent = ctx[trackedParentOf: id]
        
        self = Self(copying: self)

        if isTracking {
            // Fixup instance change in context
            
            if isRoot {
                ctx.rootIdentifier = objectIdentifier
            }
                    
            ctx[trackedParentOf: id] = nil
            ctx[trackedParentOf: objectIdentifier] = parent
            
            if isInner {
                let unmanged: Unmanaged = .passUnretained(inner)
                for each in children {
                    ctx[trackedParentOf: each.objectIdentifier] = unmanged
                }
            } else {
                let unmanged: Unmanaged = .passUnretained(leaf)
                for each in elements {
                    ctx[trackedParentOf: each] = unmanged
                }
            }
        }
        
    }
}
