extension SummarizedTree {

    public struct Builder {
        
        public typealias Slot = Context.Slot
        
        @usableFromInline
        typealias LeafStorage = SummarizedTree.Node.LeafStorage

        @usableFromInline
        var root: SummarizedTree

        @usableFromInline
        var leafCapacity = Int(Context.leafCapacity)

        @usableFromInline
        var innerCapacity = Int(Context.innerCapacity)

        @inlinable
        public init() {
            root = .init(root: .init())
            root.context = .nonTracking
        }
        
        @inlinable
        mutating func append(_ node: __owned Node) {
            root.concat(node)
        }
                
        @inlinable
        public mutating func append<C>(contentsOf elements: __owned C) where C: Collection, C.Element == Element {
            if elements.count <= leafCapacity {
                root.append(contentsOf: elements)
                return
            }
            
            root.reserveCapacity(root.count + elements.count)

            var nonTracking = Context.nonTracking
            var stack: [ContiguousArray<Node>] = []
            let count = elements.count
            var i = 0

            while i < count {
                let j = Swift.min(i + leafCapacity, count)
                let startIndex = elements.index(elements.startIndex, offsetBy: i)
                let endIndex = elements.index(startIndex, offsetBy: j - i)

                var node: Node = .init(leaf: .create(with: Slot(leafCapacity)) { handle in
                    handle.append(
                        contentsOf: elements[startIndex..<endIndex],
                        ctx: &nonTracking
                    )
                })
                
                while true {
                    if stack.last?.last?.height != node.height {
                        stack.append([])
                        stack[stack.count - 1].reserveCapacity(innerCapacity)
                    }
                    
                    stack[stack.count - 1].append(node)
                    
                    if stack.last!.count < innerCapacity {
                        break
                    }
                    
                    node = .init(inner: stack.popLast()!)
                    _ = node.mutInner(ctx: &nonTracking) { handle, ctx in
                        handle.mergeOrDistribute(at: handle.slotCount - 1, ctx: &ctx)
                    }
                }
                
                i = j
            }
            
            for siblings in stack {
                for node in siblings {
                    append(node)
                }
            }
        }
        
        public mutating func build() -> SummarizedTree<Context> {
            let result = root
            root = .init(root: .init())
            root.context = .nonTracking
            return result
        }

    }

}
