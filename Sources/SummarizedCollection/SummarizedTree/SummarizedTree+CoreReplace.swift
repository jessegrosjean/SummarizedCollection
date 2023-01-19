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
    
    @usableFromInline
    typealias SubSequence = SummarizedTree.SubSequence
    
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
    public typealias SubSequence = SummarizedTree.SubSequence

    @inlinable
    mutating func replace<C>(
        slot: Slot,
        subrange: Range<Int>,
        with newElements: C,
        ctx: inout Context
    ) -> Node?
        where
            C: RandomAccessCollection, C.Element == Element
    {
        let slot = Int(slot)
        let before = storage.slots[slot].summary
        let overflow = storage.slots[slot].replace(
            subrange,
            with: newElements,
            ctx: &ctx
        )
        let after = storage.slots[slot].summary
        header.summary -= before
        header.summary += after
        return overflow
    }

}

extension SummarizedTree.Node.LeafHandle {
    
    @inlinable
    mutating func slotsReplaceSubrange<C>(
        _ subrange: Range<Slot>,
        with newElements: C,
        ctx: inout Context
    ) -> Node?
        where
            C: RandomAccessCollection, C.Element == Element
    {
        let start = Int(subrange.lowerBound)
        let end = Int(subrange.upperBound)
        let changeInLength = newElements.count - subrange.count
        let endLength = Int(slotCount) + changeInLength

        defer { didChangeSlots() }
        
        if endLength <= header.slotCapacity {
            storage.slots.replaceSubrange(start..<end, with: newElements)
            return nil
        } else {
            let trailing = storage.slots.split(index: end)
            storage.slots.removeSubrange(start...)
            let take = min((Int(storage.header.slotCapacity) - start), newElements.count)
            storage.slots.append(contentsOf: newElements.prefix(take))
            var builder = SummarizedTree.Builder()
            builder.concat(elements: newElements.suffix(newElements.count - take))
            builder.concat(elements: trailing)
            return builder.build().root
        }
    }
    
}
