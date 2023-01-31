extension SummarizedTree {
     
    @inlinable
    public mutating func replace<C>(_ subrange: Range<Int>, with newElements: C)
        where
            C: Collection, C.Element == Element
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

    // Used when balancing the tree.
    @inlinable
    mutating func takeLeadingNodes(count: Int, at height: UInt8) -> [Node]? {
        guard let index = root.offset(ofNthNode: count, at: height)?.offset else {
            return nil
        }
        
        let trailing = split(index)
        var leadingNodesAtHeight: [Node] = []
        
        func gatherNodesAtHeight(node: Node) {
            if node.height == height {
                leadingNodesAtHeight.append(node)
            } else if node.height == height + 1 {
                leadingNodesAtHeight.append(contentsOf: node.children)
            } else {
                for each in node.children {
                    gatherNodesAtHeight(node: each)
                }
            }
        }

        gatherNodesAtHeight(node: root)
        
        self = trailing
        
        return leadingNodesAtHeight
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
            C: Collection, C.Element == Element
    {
        if isInner {
            let (startChild, endChild) = rdInner { handle in
                let startChild = handle.findChild(containing: subrange.lowerBound, bias: .right)
                let endChild = subrange.isEmpty ? startChild : handle.findChild(containing: subrange.upperBound, bias: .left)
                return (startChild, endChild)
            }
            
            let childElementStart = subrange.lowerBound - startChild.start
            let childElementRange = childElementStart..<subrange.endIndex - startChild.start

            if startChild.index == endChild.index {
                return replaceInSingleChild(
                    childSlot: startChild.index,
                    childElementRange: childElementRange,
                    with: newElements,
                    ctx: &ctx
                )
            } else {
                return replaceInChildRange(
                    childSlotRange: startChild.index..<endChild.index + 1,
                    childElementRange: childElementRange,
                    with: newElements, ctx: &ctx
                )
            }
        } else {
            let subrange = Slot(subrange.lowerBound)..<Slot(subrange.upperBound)
            let overflow = mutLeaf(ctx: &ctx) { $0.leafReplaceWithUnlimitedOverflow(in: subrange, with: newElements, ctx: &$1) }
            return overflow
        }
    }

    @inlinable
    mutating func replaceInSingleChild<C>(
        childSlot: Slot,
        childElementRange: Range<Int>,
        with newElements: C,
        ctx: inout Context
    ) -> Node?
        where
            C: Collection, C.Element == Element
    {
        // 1. Perform recursive replace. Need to handle any overflow or underflow
        var (overflow, childUnderflowing) = mutInner(ctx: &ctx) { handle, ctx in
            handle.innerReplaceWithOverflow(
                at: childSlot,
                subrange: childElementRange,
                with: newElements,
                ctx: &ctx
            )
        }

        // 2. Slot where overflow will be inserted
        var overflowSlot = childSlot + 1
        
        // 3. If child is underflowing after edit remove child and combine with any overflow
        if childUnderflowing {
            overflowSlot -= 1
            
            let underflowingChildSubtree = mutInner(isUnique: true, ctx: &ctx) { handle, ctx in
                var childTree = SummarizedTree(untracked: handle.remove(at: childSlot, ctx: &ctx))
                childTree.pullUpUnderflowingRoot()
                return childTree
            }
            
            if overflow != nil {
                var tree = SummarizedTree(untracked: overflow!)
                tree.concat(underflowingChildSubtree)
                overflow = tree.root
            } else {
                overflow = underflowingChildSubtree.root
            }
        }
        
        // 4. If overflow insert and balance if needed
        if let overflow {
            if overflowSlot < slotCapacity {
                return mutInner(ctx: &ctx) { $0.insertAndBalanceNode(overflow, at: overflowSlot, ctx: &$1) }
            } else {
                return overflow
            }
        } else {
            return nil
        }
    }

    @inlinable
    mutating func replaceInChildRange<C>(
        childSlotRange: Range<Slot>,
        childElementRange: Range<Int>,
        with newElements: C,
        ctx: inout Context
    ) -> Node?
        where
            C: Collection, C.Element == Element
    {
        // 1. Extract childSlotRange subtree
        var extractedSubtree = SummarizedTree(untracked: mutInner(ctx: &ctx) { (handle, ctx) -> ContiguousArray<Node> in
            let results = ContiguousArray(handle[childSlotRange])
            handle.removeSubrange(childSlotRange, ctx: &ctx)
            return results
        })

        // 2. Perform replace in subtree
        let trailing = extractedSubtree.split(childElementRange.endIndex)
        _ = extractedSubtree.split(childElementRange.startIndex)
        extractedSubtree.append(contentsOf: newElements)
        extractedSubtree.concat(trailing)

        // 3. Re-insert updated subtree and make sure to balance since it might be underflowing or overflowing.
        return mutInner(ctx: &ctx) { $0.insertAndBalanceNode(extractedSubtree.root, at: childSlotRange.startIndex, ctx: &$1) }
    }

    @inlinable
    func offset(ofNthNode: Int, at nodeHeight: UInt8) -> (offset: Int, nodes: Int)? {
        if height < nodeHeight || ofNthNode == 0 {
            return nil
        }
        
        if height == nodeHeight {
            return (count, 1)
        } else {
            var offset = 0
            var remaining = ofNthNode
            
            for each in children {
                let (eachOffset, eachTaken) = each.offset(ofNthNode: remaining, at: nodeHeight)!
                offset += eachOffset
                remaining -= eachTaken
                if remaining == 0 {
                    break
                }
            }
            
            return (offset, ofNthNode - remaining)
        }
    }

}

extension SummarizedTree.Node.Storage.Handle where Storage == SummarizedTree.Node.Storage<SummarizedTree.Node, SummarizedTree.Node.InnerStorageDelegate> {

    @usableFromInline
    typealias Node = SummarizedTree.Node

    @inlinable
    func innerReplaceWithOverflow<C>(
        at slot: Slot,
        subrange: Range<Int>,
        with newElements: C,
        ctx: inout Context
    ) -> (Node?, Bool)
        where
            C: Collection, C.Element == SummarizedTree.Element
    {
        assertMutable()
        let slotPtr = storedElementPointer(at: slot)
        let beforeHeight = slotPtr.pointee.height
        let before = slotPtr.pointee.summary
        let overflow = slotPtr.pointee.replace(subrange, with: newElements, ctx: &ctx)
        let after = slotPtr.pointee.summary
        let afterHeight = slotPtr.pointee.height
        let underflowing = slotPtr.pointee.slotsUnderflowing
        summary -= before
        summary += after
        return (overflow, afterHeight < beforeHeight || underflowing)
    }

    // Inserts node at slot and balances that node. Node may be overflowing or underflowing.
    @inlinable func insertAndBalanceNode(_ node: Node, at slot: Slot, ctx: inout Context) -> Node? {
        assertMutable()

        if node.isEmpty {
            return nil
        }
        
        let height = height
        let insertHeight = node.height

        if insertHeight == height {
            return insertNodesWithOverflowAndBalance(Array(node.children), at: slot, ctx: &ctx)
        } else if insertHeight == height - 1 {
            return insertNodesWithOverflowAndBalance([node], at: slot, ctx: &ctx)
        } else {
            
            // Node isn't correct height. To fix build tree and:
            // 1. Concat trailing slots until nodes is proper height
            // 2. Take leading nodes at needed height to fill availible slots
            // 3. If there's anything left return as overflow.
            
            var tree = SummarizedTree(untracked: node)
            while tree.height < (height - 1) && slot < slotCount {
                tree.concat(remove(at: slot, ctx: &ctx))
            }
            
            let extracted = tree.takeLeadingNodes(count: Int(slotCapacity - slot), at: height - 1) ?? []
            let overflow = insertNodesWithOverflowAndBalance(extracted, at: slot, ctx: &ctx)
            
            if let overflow {
                var overflowTree = SummarizedTree(untracked: overflow)
                overflowTree.concat(tree)
                return overflowTree.root
            } else if !tree.isEmpty {
                return tree.root
            } else {
                return nil
            }
        }
    }
 
    @inlinable
    func insertNodesWithOverflowAndBalance(_ nodes: [Node], at slot: Slot, ctx: inout Context) -> Node? {
        let overflow = insertWithOverflow(nodes, at: slot, ctx: &ctx)
        _ = mergeOrDistribute(at: min(slotCount, slot + Slot(nodes.count)) - 1, ctx: &ctx)
        if nodes.count > 1 {
            _ = mergeOrDistribute(at: slot, ctx: &ctx)
        }
        return overflow.map { .init(inner: $0) }
    }
    
}

extension SummarizedTree.Node.Storage.Handle where StoredElement == SummarizedTree.Element {
    
    @inlinable
    func leafReplaceWithUnlimitedOverflow<C>(
        in subrange: Range<Slot>,
        with newElements: C,
        ctx: inout Context
    ) -> SummarizedTree.Node?
        where
            C: Collection, C.Element == StoredElement
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
            
            if slotsUnderflowing {
                assert(newElements.count == take)
                trailing.mut { trailingHandle in
                    mergeOrDistributeStoredElements(with: trailingHandle, distribute: .even, ctx: &ctx)
                }
            }
            
            var builder = SummarizedTree.Builder()
            builder.append(contentsOf: newElements.suffix(newElements.count - take))
            builder.append(contentsOf: trailing.subSequence)
            return builder.build().root
        }
    }
    
}
