// Entire purpose of backpointers is to suppoert finding element index by id.
// Current approach of trying to maintain these is to do it in concert with tree
// modifications. This causes problems, because often we don't need to maintain
// those pointers. Better approach is caching pull model.
//
// 1. When offset(id) is called fill needed caches
// 2. When tree is modified invalidate caches

extension SummarizedTree: IdentifiedCollection where Element: Identifiable, Context: IdentifiedSummarizedTreeContext {
        
    typealias UnmanagedNode = Node.UnmanagedNode
    
    /*
    func buildIndex(node: UnmanagedNode, map: inout [Element.ID : UnmanagedNode]) {
        if node.isInner {
            for i in 0..<node.slotCount {
                buildIndex(node: node.unmanagedChild(at: i), map: &map)
            }
        } else {
            for e in node.elements {
                map[e.id] = node
            }
        }
    }*/
    
    @inline(never)
    public func offset(id: Element.ID) -> Int? {
        /*
        var map: [Element.ID : UnmanagedNode] = [:]
        buildIndex(node: root.unmanagedNode, map: &map)
        return nil
        */
        
        guard context.maintainsBackpointers else {
            for (i, each) in enumerated() {
                if each.id == id {
                    return i
                }
            }
            return nil
        }
        
        guard let leaf = context[leafOf: id] else {
            return nil
        }
        
        var offset = Int(leaf.subSequence.firstIndex { $0.id == id }!)
        var parent = context[parentOf: ObjectIdentifier(leaf)]
        var child = ObjectIdentifier(leaf)

        while let p = parent {
            for each in p.subSequence {
                if each.objectIdentifier == child {
                    break
                } else {
                    offset += each.summary.count
                }
            }
            parent = context[parentOf: ObjectIdentifier(p)]
            child = ObjectIdentifier(p)
        }
        
        return offset
    }
    
}
