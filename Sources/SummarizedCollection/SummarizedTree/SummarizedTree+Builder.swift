extension SummarizedTree {

    public struct Builder {
        
        @usableFromInline
        var root: SummarizedTree

        @usableFromInline
        var leafSize = Int(Context.leafCapacity)

        @usableFromInline
        var innerSize = Int(Context.innerCapacity)

        @inlinable
        public init() {
            root = .init(root: .init(), maintainBackpointersIfAble: false)
        }
        
        @inlinable
        public mutating func concat(node: Node) {
            root.concat(node)
        }
        
        @inlinable
        public mutating func concat<C>(elements: C) where C: RandomAccessCollection, C.Element == Element {
            concat(elements: ContiguousArray(elements[...]))
        }
        
        @inlinable
        public mutating func concat(elements: ContiguousArray<Element>) {
            var stack: [ContiguousArray<Node>] = []
            let count = elements.count
            var i = 0

            while i < count {
                let j = Swift.min(i + leafSize, count)
                
                var node: Node = .init(leaf: .init(elements[i..<j]))
                while true {
                    if stack.last?.last?.height != node.height {
                        stack.append([])
                        stack[stack.count - 1].reserveCapacity(innerSize)
                    }
                    
                    stack[stack.count - 1].append(node)
                    if stack.last!.count < innerSize {
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
