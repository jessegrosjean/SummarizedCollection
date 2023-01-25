extension SummarizedTree {
        
    @inlinable
    public mutating func split(_ index: Int) -> Self {
        invalidateIndices()

        if index == 0 {
            var tree = Self()
            swap(&self, &tree)
            return tree
        } else if index == count {
            return .init()
        } else {
            var splitNode = root.split(index, ctx: &context)
            root.zipFixRight(ctx: &context)
            splitNode.zipFixLeft(ctx: &context)
        
            var splitTree = SummarizedTree(root: splitNode)
            splitTree.pullUpUnderflowingRoot()
            pullUpUnderflowingRoot()
            
            return splitTree
        }
    }
    
}

extension SummarizedTree.Node {
    
    @inlinable
    mutating func split(_ index: Int, ctx: inout Context) -> Self {
        if isInner {
            return mutInner(ctx: &ctx) { handle, ctx in
                let child = handle.findChild(containing: index)
                
                if index == child.start {
                    return .init(inner: handle.split(at: child.index, ctx: &ctx))
                } else if index == child.end {
                    return .init(inner: handle.split(at: child.index + 1, ctx: &ctx))
                } else {
                    let splitChildren = handle.split(at: child.index + 1, ctx: &ctx)
                    let splitNode = handle[child.index].split(index - child.start, ctx: &ctx)
                    
                    splitChildren.mut { handle in
                        handle.headerPtr.pointee.height = splitNode.height + 1
                        handle.insert(splitNode, at: 0, ctx: &ctx)
                    }
                    
                    return .init(inner: splitChildren)
                }
            }
        } else {
            return mutLeaf(ctx: &ctx) { .init(leaf: $0.split(at: Slot(index), ctx: &$1)) }
        }
    }
    
    @inlinable
    @discardableResult
    mutating func zipFixLeft(ctx: inout Context) -> Bool {
        if isInner && slotCount > 1 {
            return mutInner(ctx: &ctx) { $0.zipFixLeft(ctx: &$1) }
        } else {
            return false
        }
    }

    @inlinable
    @discardableResult
    mutating func zipFixRight(ctx: inout Context) -> Bool {
        if isInner && slotCount > 1 {
            return mutInner(ctx: &ctx) { $0.zipFixRight(ctx: &$1) }
        } else {
            return false
        }
    }
    
}

extension SummarizedTree.Node.Storage.Handle where StoredElement == SummarizedTree.Node {

    @usableFromInline
    struct Child {

        @usableFromInline
        let index: Slot

        @usableFromInline
        let start: Int

        @usableFromInline
        let end: Int
        
        @inlinable
        init(index: Slot, start: Int, end: Int) {
            self.index = index
            self.start = start
            self.end = end
        }
    }

    @inlinable
    func findChild(containing index: Int) -> Child {
        let slotCount = slotCount
        var startIndex = 0
        var eachCount = 0
        
        for i in 0..<slotCount {
            eachCount = self[i].count
            let endIndex = startIndex + eachCount
            if index < endIndex {
                return .init(
                    index: i,
                    start: startIndex,
                    end: endIndex
                )
            } else {
                startIndex = endIndex
            }
        }
        
        assert(index == headerPtr.pointee.summary.count)
        
        startIndex -= eachCount
        
        return .init(
            index: slotCount - 1,
            start: startIndex,
            end: startIndex + eachCount
        )
    }

    @inlinable
    func zipFixLeft(ctx: inout Context) -> Bool {
        assertMutable()

        var didStuff = false
        
        while true {
            if slotCount > 1 && self[0].slotsUnderflowing {
                didStuff = mergeOrDistributeSiblingChildren(slot1: 0, slot2: 1, ctx: &ctx) || didStuff
            }
            
            if !self[0].zipFixLeft(ctx: &ctx) {
                break
            }
        }
                
        return didStuff
    }

    @inlinable
    func zipFixRight(ctx: inout Context) -> Bool {
        assertMutable()
        
        var didStuff = false
        
        while true {
            let last = slotCount - 1
            if slotCount > 1 && self[last].slotsUnderflowing {
                didStuff = mergeOrDistributeSiblingChildren(slot1: last - 1, slot2: last, ctx: &ctx) || didStuff
            }
            
            if !self[slotCount - 1].zipFixRight(ctx: &ctx) {
                break
            }
        }
                
        return didStuff
    }
    
    @inlinable
    func mergeOrDistributeSiblingChildren(slot1: Slot, slot2: Slot, ctx: inout Context) -> Bool {
        assert(slot1 == slot2 - 1)
        assert(slot2 < slotCount)
        assertMutable()

        let removeSlot2 = {
            if headerPtr.pointee.height > 1 {
                return self[slot1].mutInner(with: &self[slot2], ctx: &ctx) { h1, h2, ctx in
                    h1.mergeOrDistributeStoredElements(with: h2, distribute: .even, ctx: &ctx)
                }
            } else {
                return self[slot1].mutLeaf(with: &self[slot2], ctx: &ctx) { h1, h2, ctx in
                    h1.mergeOrDistributeStoredElements(with: h2, distribute: .even, ctx: &ctx)
                }
            }
        }()
        
        if removeSlot2 {
            _ = remove(at: slot2, ctx: &ctx)
            return true
        } else {
            return false
        }
    }

}
