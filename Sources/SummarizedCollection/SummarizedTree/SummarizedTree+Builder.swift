extension SummarizedTree {

    public struct Builder {
        
        @usableFromInline
        var root: SummarizedTree

        @usableFromInline
        var leafCapacity = Int(Context.leafCapacity)

        @usableFromInline
        var innerCapacity = Int(Context.innerCapacity)

        @inlinable
        public init() {
            root = .init(root: .init(), maintainBackpointersIfAble: false)
        }
        
        @inlinable
        public mutating func concat(node: Node) {
            root.concat(node)
        }
                
        @inlinable
        public mutating func concat<C>(elements: C) where C: Collection, C.Element == Element {
            if elements.count <= leafCapacity {
                root.append(contentsOf: elements)
                return
            }

            var stack: [ContiguousArray<Node>] = []
            let count = elements.count
            var i = 0

            while i < count {
                let j = Swift.min(i + leafCapacity, count)
                let startIndex = elements.index(elements.startIndex, offsetBy: i)
                let endIndex = elements.index(startIndex, offsetBy: j - i)

                var node: Node = .init(leaf: .create(update: { handle in
                    handle.slotsAppend(elements[startIndex..<endIndex])
                }))
                
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
                }
                
                i = j
            }
            
            for siblings in stack {
                for node in siblings {
                    concat(node: node)
                }
            }
        }
        
        public mutating func build() -> SummarizedTree<Context> {
            let result = root
            root = .init(root: .init(), maintainBackpointersIfAble: false)
            return result
        }

    }

}
