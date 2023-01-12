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

extension Node {
    
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

extension Node.InnerHandle {

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
        
        /*
        while true {
            if slotCount > 1 && storage.slots[0].slotsUnderflowing {
                didStuff = storage.slots[0].mutInner(with: &storage.slots[1]) { h1, h2 in
                    h1.slotsMergeOrDistribute(with: &h2, distribute: .even, ctx: &ctx)
                }
            }
            
            if !storage.slots[0].zipFixLeft(ctx: &ctx) {
                break
            }
        }
        */
                
        return didStuff
    }

    @inlinable
    mutating func zipFixRight(ctx: inout Context) -> Bool {
        var didStuff = false
        
        /*
        while true {
            let last = Int(slotCount - 1)
            if slotCount > 1 && storage.slots[last].slotsUnderflowing {
                didStuff = storage.slots[last - 1].mutInner(with: &storage.slots[last]) { h1, h2 in
                    h1.slotsMergeOrDistribute(with: &h2, distribute: .even, ctx: &ctx)
                }
            }
            
            if !storage.slots[last].zipFixRight(ctx: &ctx) {
                break
            }
        }
        */
                
        return didStuff
    }

}
