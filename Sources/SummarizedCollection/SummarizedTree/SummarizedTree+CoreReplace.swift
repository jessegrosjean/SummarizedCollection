extension SummarizedTree {
     
    @inlinable
    public mutating func replace<C>(_ subrange: Range<Int>, with newElements: C)
        where
            C: RandomAccessCollection, C.Element == Element
    {
        context.validateReplace(subrange: subrange, with: newElements, in: self)
        context.reserveCapacity((count - subrange.count) + newElements.count)
        invalidateIndices()
        
        let overflow = root.replace(
            subrange,
            with: newElements,
            ctx: &context
        )
        
        if let overflow {
            concat(overflow)
        }

        pullUpUnderflowingRoot()
    }

}

extension SummarizedTree.Node {
        
    @inlinable
    mutating func replace<C>(
        _ subrange: Range<Int>,
        with newElements: C,
        ctx: inout Context
    ) -> Node?
        where
            C: RandomAccessCollection, C.Element == Element
    {
        if isInner {
            let (startChild, endChild) = rdInner { handle in
                let startChild = handle.findChild(containing: subrange.lowerBound)
                let endChild = subrange.isEmpty ? startChild : handle.findChild(containing: subrange.upperBound)
                return (startChild, endChild)
            }
            
            if startChild.index == endChild.index {
                let localStart = subrange.lowerBound - startChild.start
                let localEnd = subrange.upperBound - endChild.start
                let overflow = mutInner(ctx: &ctx) { handle, ctx in
                    handle.innerReplaceWithOverflow(
                        at: startChild.index,
                        subrange: localStart..<localEnd,
                        with: newElements,
                        ctx: &ctx
                    )
                }
                
                if let overflow {
                    let changeInLength = (newElements.count - subrange.count) - overflow.count
                    let splitIndex = startChild.end + changeInLength
                    
                    if splitIndex < count {
                        var overflowTree = SummarizedTree(root: overflow)
                        let split = split(splitIndex, ctx: &ctx)
                        overflowTree.concat(split)
                        return overflowTree.root
                    } else {
                        return overflow
                    }
                } else {
                    return nil
                }
            } else {
                let trailing = split(subrange.upperBound, ctx: &ctx)
                _ = split(subrange.lowerBound, ctx: &ctx)
                var insert = SummarizedTree(newElements)
                
                insert.concat(trailing)

                if insert.height <= height {
                    if let overflow = concat(insert.root, ctx: &ctx) {
                        return overflow
                    } else {
                        return nil
                    }
                } else {
                    return insert.root
                }
            }
        } else {
            let subrange = Slot(subrange.lowerBound)..<Slot(subrange.upperBound)
            let overflow = mutLeaf(ctx: &ctx) { $0.leafReplaceWithOverflow(in: subrange, with: newElements, ctx: &$1) }
            return overflow
        }
    }
    
}

extension SummarizedTree.Node.Storage.Handle where StoredElement == SummarizedTree.Node {

    @usableFromInline
    typealias Node = SummarizedTree.Node

    @inlinable
    func innerReplaceWithOverflow<C>(
        at slot: Slot,
        subrange: Range<Int>,
        with newElements: C,
        ctx: inout Context
    ) -> Node?
        where
            C: RandomAccessCollection, C.Element == SummarizedTree.Element
    {
        assertMutable()
        let slotPtr = storedElementPointer(at: slot)
        let before = slotPtr.pointee.summary
        let overflow = slotPtr.pointee.replace(subrange, with: newElements, ctx: &ctx)
        let after = slotPtr.pointee.summary
        headerPtr.pointee.summary -= before
        headerPtr.pointee.summary += after
        
        if after.count == 0 {
            _ = remove(at: slot, ctx: &ctx)
        }
        
        return overflow
    }

}

extension SummarizedTree.Node.Storage.Handle where StoredElement == SummarizedTree.Element {
    
    @inlinable
    func leafReplaceWithOverflow<C>(
        in subrange: Range<Slot>,
        with newElements: C,
        ctx: inout Context
    ) -> SummarizedTree.Node?
        where
            C: RandomAccessCollection, C.Element == StoredElement
    {
        assertMutable()
        
        let start = subrange.lowerBound
        let end = subrange.upperBound
        let changeInLength = newElements.count - subrange.count
        let endLength = Int(slotCount) + changeInLength
        
        if endLength <= slotCapacity {
            replaceSubrange(start..<end, with: newElements, ctx: &ctx)
            return nil
        } else {
            let trailing = split(at: end, ctx: &ctx)
            removeSubrange(start..<slotCount, ctx: &ctx)
            let take = Swift.min(Int(slotCapacity - start), newElements.count)
            append(contentsOf: newElements.prefix(take), ctx: &ctx)

            var builder = SummarizedTree.Builder()
            builder.append(contentsOf: newElements.suffix(newElements.count - take))
            builder.append(contentsOf: trailing.subSequence)
            return builder.build().root
        }
    }
    
}
