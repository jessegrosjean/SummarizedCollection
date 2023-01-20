extension SummarizedTree {
     
    @inlinable
    public mutating func replace<C>(_ subrange: Range<Int>, with newElements: C)
        where
            C: RandomAccessCollection, C.Element == Element
    {
        invalidateIndices()
        
        let overflow = root.replace(
            subrange,
            with: newElements
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
        with newElements: C
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
                    $0.replaceWithOverflow(
                        at: startChild.index,
                        subrange: localStart..<localEnd,
                        with: newElements
                    )
                }
                
                if let overflow {
                    let changeInLength = (newElements.count - subrange.count) - overflow.count
                    let splitIndex = startChild.end + changeInLength
                    
                    if splitIndex < count {
                        var overflowTree = SummarizedTree(root: overflow)
                        let split = split(splitIndex)
                        overflowTree.concat(split)
                        return overflowTree.root
                    } else {
                        return overflow
                    }
                } else {
                    return nil
                }
            } else {
                let trailing = split(subrange.upperBound)
                _ = split(subrange.lowerBound)
                var insert = SummarizedTree(newElements)
                
                insert.concat(trailing)

                if insert.height <= height {
                    if let overflow = concat(insert.root) {
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
            let overflow = mutLeaf { $0.replaceWithOverflow(in: subrange, with: newElements) }
            return overflow
        }
    }
    
}

extension SummarizedTree.Node.Storage.Handle where StoredElement == SummarizedTree.Node {

    public typealias Node = SummarizedTree.Node

    @inlinable
    func replaceWithOverflow<C>(
        at slot: Slot,
        subrange: Range<Int>,
        with newElements: C
    ) -> Node?
        where
            C: RandomAccessCollection, C.Element == SummarizedTree.Element
    {
        assertMutable()
        let before = storedElementPointer(at: slot).pointee.summary
        let overflow = storedElementPointer(at: slot).pointee.replace(subrange, with: newElements)
        let after = storedElementPointer(at: slot).pointee.summary
        headerPtr.pointee.summary -= before
        headerPtr.pointee.summary += after
        return overflow
    }

}

extension SummarizedTree.Node.Storage.Handle where StoredElement == SummarizedTree.Element {
    
    @inlinable
    func replaceWithOverflow<C>(
        in subrange: Range<Slot>,
        with newElements: C
    ) -> SummarizedTree.Node?
        where
            C: RandomAccessCollection, C.Element == Element
    {
        assertMutable()
        
        let start = subrange.lowerBound
        let end = subrange.upperBound
        let changeInLength = newElements.count - subrange.count
        let endLength = Int(slotCount) + changeInLength
        
        if endLength <= slotCapacity {
            replaceSubrange(start..<end, with: newElements)
            return nil
        } else {
            let trailing = split(at: end)
            removeSubrange(start..<slotCount)
            let take = Swift.min(Int(slotCapacity - start), newElements.count)
            append(contentsOf: newElements.prefix(take))

            var builder = SummarizedTree.Builder()
            builder.concat(elements: newElements.suffix(newElements.count - take))
            builder.concat(elements: trailing.subSequence)
            return builder.build().root
        }
    }
    
}
