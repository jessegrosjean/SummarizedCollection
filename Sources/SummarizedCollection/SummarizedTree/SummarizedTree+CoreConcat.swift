extension SummarizedTree {
        
    public mutating func concat(_ tree: __owned SummarizedTree) {
        context.validateInsert(tree, in: self)
        invalidateIndices()
        concat(tree.root)
    }
    
    @inlinable
    mutating func concat(_ node: __owned Node) {
        guard !node.isEmpty else {
            return
        }
            
        if isEmpty {
            var copy = context.isTracking ? SummarizedTree(root: node) : SummarizedTree(untracked: node)
            swap(&self, &copy)
            return
        }
    
        context.reserveCapacity(count + node.count)

        let h1 = height
        let h2 = node.height
        if h1 < h2 {
            node.rdInner { handle in
                for i in 0..<handle.slotCount {
                    concat(.init(root: handle[i]))
                }
            }
        } else {
            if let overflow = root.concat(node, ctx: &context) {
                assert(root.height == overflow.height)
                pushDownOverflowingRoot(overflow: overflow)
            }
        }
    }

}

extension SummarizedTree.Node {
    
    @inlinable
    mutating func concat(_ node: __owned Self, ctx: inout Context) -> Self? {
        let height = height
        let concatHeight = node.height
        let heightDelta = height - concatHeight

        if isInner {
            let concatChildren = InnerStorage.create(with: Context.innerCapacity)
            var nonTracking = Context.nonTracking
            
            if heightDelta == 0 {
                concatChildren.mut { $0.append(contentsOf: node.inner, ctx: &nonTracking) }
            } else if heightDelta == 1 && !node.slotsUnderflowing {
                concatChildren.mut { $0.append(node, ctx: &nonTracking) }
            } else {
                mutInner(ctx: &ctx) { handle, ctx in
                    if let overflow = handle[handle.slotCount - 1].concat(node, ctx: &ctx) {
                        concatChildren.mut { $0.append(overflow, ctx: &nonTracking) }
                    }
                }
            }
            
            if slotsAvailible >= concatChildren.header.slotCount {
                mutInner(ctx: &ctx) { $0.append(contentsOf: concatChildren, ctx: &$1) }
            } else {
                var overflow: Node = .init(inner: concatChildren)
                mutInner(with: &overflow, ctx: &ctx) { $0.distributeStoredElements(with: $1, distribute: .even, ctx: &$2) }
                return overflow
            }
        } else {
            if slotsAvailible >= node.slotCount {
                mutLeaf(ctx: &ctx) { $0.append(contentsOf: node.leaf, ctx: &$1) }
            } else if slotsUnderflowing || node.slotsUnderflowing {
                var node = node
                mutLeaf(with: &node, ctx: &ctx) { $0.distributeStoredElements(with: $1, distribute: .even, ctx: &$2) }
                return node
            } else {
                return node
            }
        }
        
        return nil
    }
    
}
