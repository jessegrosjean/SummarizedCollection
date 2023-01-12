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
            splitTree.pullUpSingularNodes()
            pullUpSingularNodes()
            
            return splitTree
        }
    }
    
    @inlinable
    mutating func pullUpSingularNodes() {
        while !root.isLeaf && root.slotCount == 1 {
            root = root.rdInner { $0.slots[0] }
        }
    }

}

extension SummarizedTree.Node {
    
    @inlinable
    mutating func split(_ index: Int, ctx: inout Context) -> Self {
        if isInner {
            return mutInner { handle in
                let child = handle.findChild(containing: index)
                
                if index == child.start {
                    return Self(inner: handle.slotSplit(at: child.index, ctx: &ctx))
                } else if index == child.end {
                    return .init(inner: handle.slotSplit(at: child.index + 1, ctx: &ctx))
                } else {
                    let splitChildren = handle.slotSplit(at: child.index + 1, ctx: &ctx)
                    let splitNode = handle.storage.slots[Int(child.index)].split(index - child.start, ctx: &ctx)
                    
                    handle.didChangeSlots()
                    
                    splitChildren.mut { handle in
                        handle.header.height = splitNode.height + 1
                        handle.slotInsert(splitNode, at: 0, ctx: &ctx)
                    }
                    
                    return .init(inner: splitChildren)
                }
            }
        } else {
            return mutLeaf { .init(leaf: $0.slotSplit(at: Slot(index), ctx: &ctx)) }
        }
    }
    
    @discardableResult
    @inlinable
    mutating func zipFixLeft(ctx: inout Context) -> Bool {
        if isInner && slotCount > 1 {
            return mutInner { $0.zipFixLeft(ctx: &ctx) }
        } else {
            return false
        }
    }

    @discardableResult
    @inlinable
    mutating func zipFixRight(ctx: inout Context) -> Bool {
        if isInner && slotCount > 1 {
            return mutInner { $0.zipFixRight(ctx: &ctx) }
        } else {
            return false
        }
    }
    
}

extension SummarizedTree.Node.InnerHandle {

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
        var startIndex = 0
        for i in 0..<slotCount {
            let child = self[i]
            let endIndex = startIndex + child.count
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
        fatalError()
    }

    @inlinable
    mutating func zipFixLeft(ctx: inout Context) -> Bool {
        var didStuff = false
        
        while true {
            if slotCount > 1 && storage.slots[0].slotsUnderflowing {
                didStuff = slotsMergeOrDistribute(slot1: 0, slot2: 1, ctx: &ctx) || didStuff
            }
            
            if !storage.slots[0].zipFixLeft(ctx: &ctx) {
                break
            }
        }
                
        return didStuff
    }

    @inlinable
    mutating func zipFixRight(ctx: inout Context) -> Bool {
        var didStuff = false
        
        while true {
            let last = slotCount - 1
            if slotCount > 1 && storage.slots[Int(last)].slotsUnderflowing {
                didStuff = slotsMergeOrDistribute(slot1: last - 1, slot2: last, ctx: &ctx) || didStuff
            }
            
            if !storage.slots[Int(last)].zipFixRight(ctx: &ctx) {
                break
            }
        }
                
        return didStuff
    }
    
    @inlinable
    mutating func slotsMergeOrDistribute(slot1: Slot, slot2: Slot, ctx: inout Context) -> Bool {
        assert(slot1 == slot2 - 1)
        assert(slot2 < slotCount)

        //storage.slots[Int(slot1)].mutInner(with: &storage.slots[Int(slot2)], body: { h1, h2 in
            
        //})
        
        return false

        /*
        var removeSlot2 = false
        
        if header.height > 1 {
            removeSlot2 = storage.slots[Int(slot1)].mutInner(with: &storage.slots[Int(slot2)]) { h1, h2 in
                h1.slotsMergeOrDistribute(with: &h2, distribute: .even, ctx: &ctx)
            }
        } else {
            removeSlot2 = storage.slots[Int(slot1)].mutLeaf(with: &storage.slots[Int(slot2)]) { h1, h2 in
                h1.slotsMergeOrDistribute(with: &h2, distribute: .even, ctx: &ctx)
            }
        }
        
        if removeSlot2 {
            slotRemove(at: slot2, ctx: &ctx)
            return true
        } else {
            return false
        }*/
    }

}
