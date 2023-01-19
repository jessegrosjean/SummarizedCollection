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
        
            var splitTree = SummarizedTree(root: splitNode, maintainBackpointersIfAble: false)
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
                    return .init(inner: handle.slotSplit(at: child.index, ctx: &ctx))
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
        
        assert(index == header.summary.count)
        
        startIndex -= eachCount
        
        return .init(
            index: Slot(slots.count - 1),
            start: startIndex,
            end: startIndex + eachCount
        )
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
            
            if !storage.slots[storage.slots.count - 1].zipFixRight(ctx: &ctx) {
                break
            }
        }
                
        return didStuff
    }
    
    @inlinable
    mutating func slotsMergeOrDistribute(slot1: Slot, slot2: Slot, ctx: inout Context) -> Bool {
        assert(slot1 == slot2 - 1)
        assert(slot2 < slotCount)

        let removeSlot2 = storage.slots.withUnsafeMutableBufferPointer { buffer in
            let s1 = Int(slot1)
            let s2 = Int(slot2)

            if header.height > 1 {
                return buffer[s1].mutInner(with: &buffer[s2]) { h1, h2 in
                    h1.slotsMergeOrDistribute(with: &h2, distribute: .even, ctx: &ctx)
                }
            } else {
                return buffer[s1].mutLeaf(with: &buffer[s2]) { h1, h2 in
                    h1.slotsMergeOrDistribute(with: &h2, distribute: .even, ctx: &ctx)
                }
            }
        }
        
        if removeSlot2 {
            slotRemove(at: slot2, ctx: &ctx)
            return true
        } else {
            return false
        }
    }

}
