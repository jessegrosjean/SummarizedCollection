extension SummarizedTree: IdentifiedCollection where Element: Identifiable {
      
    public func index(id: ID) -> Index? {
        guard Context.maintainsBackpointers else {
            for (i, each) in enumerated() {
                if each.id == id {
                    return index(startIndex, offsetBy: i)
                }
            }
            return nil
        }
        
        guard let leaf = context[leafContaining: id] else {
            return nil
        }
        
        var offset = leaf.elements.firstIndex { $0.id == id }!
        var parent = context[parent: leaf]
        var child = leaf

        while let p = parent {
            for each in p.children {
                if each == child {
                    break
                } else {
                    offset += each.summary.count
                }
            }
            parent = context[parent: p]
            child = p
        }
        
        return index(startIndex, offsetBy: offset)
    }
}
