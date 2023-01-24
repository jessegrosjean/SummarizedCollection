//#if DEBUG
extension SummarizedTree.Node: CustomDebugStringConvertible {
    
    static func debugNode(node: Node, indent: Int, result: inout String) {
        result.append(String(repeating: "  ", count: indent))
        
        if node.isInner {
            result.append("<Inner height: \(node.height) count: \(node.summary.count)>\n")
            for each in node.children {
                debugNode(node: each, indent: indent + 1, result: &result)
            }
        } else {
            result.append("<Leaf count: \(node.summary.count)>\n")
            result.append("\(String(repeating: "  ", count: indent + 1))\(node.leaf.subSequence)\n")
        }
    }
    
    public var debugDescription: String {
        var result = ""
        Node.debugNode(node: self, indent: 0, result: &result)
        return result
    }

}
//#endif

extension SummarizedTree.Node {
    
    @inlinable
    func ensureValid(parent: Node?, ctx: Context) {
        if isLeaf {
            assert(height == 0)
            assert(summary == Summary.summarize(elements: leaf.subSequence))
        } else {
            assert(height > 0)
            
            if let parent {
                assert(height == parent.height - 1)
            }
            
            assert(inner.header.slotCount <= Context.innerCapacity)
            var childrenSummary: Summary = .zero
            for each in inner.subSequence {
                each.ensureValid(parent: self, ctx: ctx)
                childrenSummary += each.summary
            }
            assert(inner.header.summary == childrenSummary)
        }
    }
    
}
