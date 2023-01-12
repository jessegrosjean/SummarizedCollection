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
    func rdInner<R>(_ body: (InnerHandle) throws -> R) rethrows -> R {
        try inner.rd { try body($0) }
    }
    
    @inlinable
    func rdLeaf<R>(_ body: (LeafHandle) throws -> R) rethrows -> R {
        try leaf.rd { try body($0) }
    }

    @inlinable
    mutating func mutInner<R>(
        isUnique: Bool? = nil,
        body: (inout InnerHandle) throws -> R
    ) rethrows -> R {
        ensureUnique(isUnique)
        defer { updateFromStorage() }
        return try inner.mut { try body(&$0) }
    }

    @inlinable
    mutating func mutInner<R>(with node: inout Self, body: (inout InnerHandle, inout InnerHandle) throws -> R) rethrows -> R {
        try mutInner { handle in
            try node.mutInner { nodeHandle in
                return try body(&handle, &nodeHandle)
            }
        }
    }
    
    @inlinable
    mutating func mutLeaf<R>(
        isUnique: Bool? = nil,
        body: (inout LeafHandle) throws -> R
    ) rethrows -> R {
        ensureUnique(isUnique)
        defer { updateFromStorage() }
        return try leaf.mut { try body(&$0) }
    }

    @inlinable
    mutating func mutLeaf<R>(with node: inout Self, body: (inout LeafHandle, inout LeafHandle) throws -> R) rethrows -> R {
        try mutLeaf { handle in
            try node.mutLeaf { nodeHandle in
                return try body(&handle, &nodeHandle)
            }
        }
    }
    
    @inlinable
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
    mutating func ensureUnique(_ isUnique: Bool? = nil) {
        if let isUnique = isUnique {
            if !isUnique {
                self = Self(copying: self)
            }
        } else if !self.isUnique() {
            self = Self(copying: self)
        }
    }
    
}
