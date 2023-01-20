extension SummarizedTree.Node {
    
    public typealias InnerStorage2 = Storage<Self>

    @inlinable
    @inline(__always)
    func rdInner2<R>(_ body: (InnerStorage2.Handle) throws -> R) rethrows -> R {
        try inner2.rd { try body($0) }
    }
    
    @inlinable
    @inline(__always)
    mutating func mutInner2<R>(
        isUnique: Bool? = nil,
        body: (InnerStorage2.Handle) throws -> R
    ) rethrows -> R {
        ensureUnique(isUnique)
        defer { updateFromStorage() }
        return try inner2.mut { try body($0) }
    }

    @inlinable
    @inline(__always)
    mutating func mutInner2<R>(with node: inout Self, body: (InnerStorage2.Handle, InnerStorage2.Handle) throws -> R) rethrows -> R {
        try mutInner2 { handle in
            try node.mutInner2 { nodeHandle in
                return try body(handle, nodeHandle)
            }
        }
    }

}

/*
extension SummarizedTree.Node.Storage.Handle where StoredElement == SummarizedTree.Node {

    public typealias Node = SummarizedTree.Node
    
    @inlinable
    func replace<C>(
        slot: Slot,
        subrange: Range<Int>,
        with newElements: C
    ) -> Node?
        where
            C: RandomAccessCollection, C.Element == StoredElement
    {
        assertMutable()
        
        let before = storedElementPointer(at: slot).pointee.summary
        
        replaceSubrange(slot..<slot, with: newElements)
        
        let after = storedElementPointer(at: slot).pointee.summary
        headerPtr.pointee.summary -= before
        headerPtr.pointee.summary += after
        return overflow
    }

}
*/
