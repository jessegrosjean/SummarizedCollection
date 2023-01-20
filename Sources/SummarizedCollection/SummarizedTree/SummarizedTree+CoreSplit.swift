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
            var splitNode = root.split(index)
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
            root = root.rdInner { $0[0] }
        }
    }

}

extension SummarizedTree.Node {
    
    @inlinable
    mutating func split(_ index: Int) -> Self {
        if isInner {
            return mutInner { handle in
                let child = handle.findChild(containing: index)
                
                if index == child.start {
                    return .init(inner: handle.split(at: child.index))
                } else if index == child.end {
                    return .init(inner: handle.split(at: child.index + 1))
                } else {
                    let splitChildren = handle.split(at: child.index + 1)
                    let splitNode = handle[child.index].split(index - child.start)
                    
                    splitChildren.mut { handle in
                        handle.headerPtr.pointee.height = splitNode.height + 1
                        handle.insert(splitNode, at: 0)
                    }
                    
                    return .init(inner: splitChildren)
                }
            }
        } else {
            return mutLeaf { .init(leaf: $0.split(at: Slot(index))) }
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
                didStuff = slotsMergeOrDistribute(slot1: 0, slot2: 1) || didStuff
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
                didStuff = slotsMergeOrDistribute(slot1: last - 1, slot2: last) || didStuff
            }
            
            if !self[slotCount - 1].zipFixRight(ctx: &ctx) {
                break
            }
        }
                
        return didStuff
    }
    
    @inlinable
    func slotsMergeOrDistribute(slot1: Slot, slot2: Slot) -> Bool {
        assert(slot1 == slot2 - 1)
        assert(slot2 < slotCount)
        assertMutable()

        let removeSlot2 = {
            let s1 = slot1
            let s2 = slot2

            if headerPtr.pointee.height > 1 {
                return self[s1].mutInner(with: &self[s2]) { h1, h2 in
                    h1.mergeOrDistributeStoredElements(with: h2, distribute: .even)
                }
            } else {
                return self[s1].mutLeaf(with: &self[s2]) { h1, h2 in
                    h1.mergeOrDistributeStoredElements(with: h2, distribute: .even)
                }
            }
        }()
        
        if removeSlot2 {
            _ = remove(at: slot2)
            return true
        } else {
            return false
        }
    }

}
