extension SummarizedTree {
     
    @inlinable
    public mutating func replace<C>(_ subrange: Range<Int>, with newElements: C)
        where
            C: RandomAccessCollection, C.Element == Element
    {
        invalidateIndices()
        
        let overflow = root.replace(
            subrange,
            with: newElements,
            ctx: &context
        )
        
        if let overflow {
            concat(overflow)
        }

        pullUpSingularNodes()
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
                let overflow = mutInner {
                    $0.replace(
                        slot: startChild.index,
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
            let overflow = mutLeaf { $0.slotsReplaceSubrange(subrange, with: newElements, ctx: &ctx) }
            return overflow
        }
    }
    
}

extension SummarizedTree.Node.InnerHandle {

    public typealias Element = SummarizedTree.Element

    @inlinable
    func replace<C>(
        slot: Slot,
        subrange: Range<Int>,
        with newElements: C,
        ctx: inout Context
    ) -> Node?
        where
            C: RandomAccessCollection, C.Element == Element
    {
        assertMutable()
        
        let before = slotsPointer(at: slot).pointee.summary
        let overflow = slotsPointer(at: slot).pointee.replace(
            subrange,
            with: newElements,
            ctx: &ctx
        )
        let after = slotsPointer(at: slot).pointee.summary
        headerPtr.pointee.summary -= before
        headerPtr.pointee.summary += after
        return overflow
    }

}

extension SummarizedTree.Node.LeafHandle {
    
    @inlinable
    func slotsReplaceSubrange<C>(
        _ subrange: Range<Slot>,
        with newElements: C,
        ctx: inout Context
    ) -> Node?
        where
            C: RandomAccessCollection, C.Element == Element
    {
        assertMutable()
        
        let start = subrange.lowerBound
        let end = subrange.upperBound
        let changeInLength = newElements.count - subrange.count
        let endLength = Int(slotCount) + changeInLength
        
        if endLength <= slotCapacity {
            slotsReplaceSubrange(start..<end, with: newElements)
            return nil
        } else {
            defer { didChangeSlots() }

            let trailing = slotsSplit(at: end, ctx: &ctx)
            slotsReplaceSubrange(start..<slotCount, with: [])
            let take = min(Int(slotCapacity - start), newElements.count)
            slotsAppend(newElements.prefix(take))

            var builder = SummarizedTree.Builder()
            builder.concat(elements: newElements.suffix(newElements.count - take))
            builder.concat(elements: trailing.elements)
            //fatalError()
            return builder.build().root
        }
    }
    
}
