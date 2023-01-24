extension SummarizedTree {
        
    public mutating func concat(_ tree: SummarizedTree) {
        invalidateIndices()
        concat(tree.root)
    }
    
    @inlinable
    mutating func concat(_ node: Node) {
        guard !node.isEmpty else {
            return
        }
                
        if isEmpty {
            var copy = SummarizedTree(root: node)
            swap(&self, &copy)
            return
        }

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
    mutating func concat(_ node: Self, ctx: inout Context) -> Self? {
        let height = height
        let concatHeight = node.height
        let heightDelta = height - concatHeight

        if isInner {
            let concatChildren = InnerStorage.create(with: Context.innerCapacity)
            
            if heightDelta == 0 {
                concatChildren.mut { $0.append(contentsOf: node.inner, ctx: &ctx) }
            } else if heightDelta == 1 && !node.slotsUnderflowing {
                concatChildren.mut { $0.append(node, ctx: &ctx) }
            } else {
                mutInner { handle in
                    if let overflow = handle[handle.slotCount - 1].concat(node, ctx: &ctx) {
                        concatChildren.mut { $0.append(overflow, ctx: &ctx) }
                    }
                }
            }
            
            if slotsAvailible >= concatChildren.header.slotCount {
                mutInner { $0.append(contentsOf: concatChildren, ctx: &ctx) }
            } else {
                var overflow: Node = .init(inner: concatChildren)
                mutInner(with: &overflow) { $0.distributeStoredElements(with: $1, distribute: .even, ctx: &ctx) }
                return overflow
            }
        } else {
            if slotsAvailible >= node.slotCount {
                mutLeaf { $0.append(contentsOf: node.leaf, ctx: &ctx) }
            } else if slotsUnderflowing {
                var node = node
                mutLeaf(with: &node) { $0.distributeStoredElements(with: $1, distribute: .even, ctx: &ctx) }
                return node
            } else {
                return node
            }
        }
        
        return nil
    }
    
}
