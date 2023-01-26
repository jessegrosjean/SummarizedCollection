extension SummarizedTree: IdentifiedCollection where Element: Identifiable, Context: IdentifiedSummarizedTreeContext {
    
    @inlinable
    public func contains(id: Element.ID) -> Bool {
        if context.isTracking {
            return context.contains(id: id)
        } else {
            return offset(id: id) != nil
        }        
    }
    
    @inlinable
    public func offset(id: Element.ID) -> Int? {
        guard context.isTracking else {
            for (i, each) in enumerated() {
                if each.id == id {
                    return i
                }
            }
            return nil
        }
        
        guard let leaf = context[trackedParentOf: id]?.takeUnretainedValue() else {
            return nil
        }
        
        let leafId = ObjectIdentifier(leaf)
        var offset = leaf.rd { $0.buffer.firstIndex { $0.id == id }! }
        var parent = context[trackedParentOf: leafId]
        var child = leafId

        while let p = parent?.takeUnretainedValue() {
            /*for each in p.subSequence {
                if each.objectIdentifier == child {
                    break
                } else {
                    offset += each.summary.count
                }
            }*/
            
            p.rd { handle in
                let buffer = handle.buffer
                for each in buffer {
                    if each.objectIdentifier == child {
                        return
                    } else {
                        offset += each.summary.count
                    }
                }
            }

            
            let pId = ObjectIdentifier(p)            
            parent = context[trackedParentOf: pId]
            child = pId
        }
        
        return offset
    }
    
}
