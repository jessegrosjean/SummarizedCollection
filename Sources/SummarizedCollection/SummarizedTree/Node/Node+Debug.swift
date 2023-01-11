//#if DEBUG
extension Node: CustomDebugStringConvertible {
    
    static func debugNode(node: Node, indent: Int, result: inout String) {
        result.append(String(repeating: "  ", count: indent))
        
        if node.isInner {
            result.append("<Inner height: \(node.height) count: \(node.summary.count)>\n")
            node.rdInner { handle in
                for each in handle.slots {
                    debugNode(node: each, indent: indent + 1, result: &result)
                }
            }
        } else {
            result.append("<Leaf count: \(node.summary.count)>\n")
            node.rdLeaf { handle in
                result.append("\(String(repeating: "  ", count: indent + 1))\(handle.slots)\n")
            }
        }
    }
    
    public var debugDescription: String {
        var result = ""
        Node.debugNode(node: self, indent: 0, result: &result)
        return result
    }

}
//#endif

extension Node {
    
    func ensureValid(parent: Node?, ctx: Context) {
        if let parent = ctx[parent: self] {
            assert(parent.isInner)
            parent.rdInner { handle in
                assert(handle.slots.contains(self))
            }
        }

        if Context.maintainsBackpointers {
            assert(parent == ctx[parent: self])
        }
        
        if isLeaf {
            assert(height == 0)
            rdLeaf { handle in
                assert(handle.slotCount <= Context.leafCapacity)
                assert(summary == Summary.summarize(elements: handle.slots))
            }
        } else {
            assert(height > 0)
            
            if let parent {
                assert(height == parent.height - 1)
            }
            
            rdInner { handle in
                assert(handle.slotCount <= Context.innerCapacity)
                var childrenSummary: Summary = .zero
                for each in handle.slots {
                    each.ensureValid(parent: self, ctx: ctx)
                    childrenSummary += each.summary
                    if Context.maintainsBackpointers {
                        assert(ctx[parent: each] == self)
                    }
                }
                assert(summary == childrenSummary)
            }
        }
    }
    
}
