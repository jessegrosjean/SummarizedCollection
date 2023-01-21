public protocol SummarizedTreeContext {
    
    associatedtype Slot: FixedWidthInteger & UnsignedInteger
    associatedtype Summary: CollectionSummary

    typealias Element = Summary.Element
    typealias TreeNode = SummarizedTree<Self>.Node

    static var innerCapacity: Slot { get }
    static var leafCapacity: Slot { get }

    init(root: TreeNode?, maintainBackpointersIfAble: Bool)

    // TreeNodes are shared and immutable. If we want backpointers
    // to quickly find summarized values for a given Element.ID then
    // need to maintain backpointers in Tree.Context
    
    var maintainsBackpointers: Bool { get }

    subscript(parentOf nodeIdentifier: ObjectIdentifier) -> TreeNode.InnerStorage? { get set }
    mutating func addElements<C: Collection>(_ elements: C, to leaf: TreeNode.LeafStorage) where C.Element == Element
    mutating func removeElements<C: Collection>(_ elements: C, from leaf: TreeNode.LeafStorage) where C.Element == Element

}

public protocol IdentifiedSummarizedTreeContext: SummarizedTreeContext where Element: Identifiable {

    subscript(leafOf id: Element.ID) -> TreeNode.LeafStorage? { get }

}

@usableFromInline
var innerCapacityCache: [ObjectIdentifier: Any] = [:]

@usableFromInline
var leafCapacityCache: [ObjectIdentifier: Any] = [:]

extension SummarizedTreeContext {

    @inlinable
    public static var innerCapacity: Slot {
        #if DEBUG
            return 3
        #else
            if let capacity = innerCapacityCache[ObjectIdentifier(Self.self)] as? Slot {
                return capacity
            }
            
            let capacityInBytes = 1024
            let capacity =  Slot(Swift.max(16, capacityInBytes / MemoryLayout<TreeNode>.stride))
            innerCapacityCache[ObjectIdentifier(Self.self)] = capacity
            return capacity
        #endif
    }
    
    @inlinable
    public static var leafCapacity: Slot {
        #if DEBUG
            return 3
        #else
            if let capacity = leafCapacityCache[ObjectIdentifier(Self.self)] as? Slot {
                return capacity
            }

            let capacityInBytes = 1024
            let capacity = Slot(Swift.max(16, capacityInBytes / MemoryLayout<Element>.stride))
            leafCapacityCache[ObjectIdentifier(Self.self)] = capacity
            return capacity
        #endif
    }

    public subscript(parentOf identifier: ObjectIdentifier) -> TreeNode.InnerStorage? { get { nil } set {} }
    public subscript(leafOf element: Element) -> TreeNode.LeafStorage? { nil }
    public mutating func addElements<C: Collection>(_ elements: C, to leaf: TreeNode.LeafStorage) where C.Element == Element {}
    public mutating func removeElements<C: Collection>(_ elements: C, from leaf: TreeNode.LeafStorage) where C.Element == Element {}

    @inlinable
    public mutating func addNode(_ node: TreeNode) {
        guard maintainsBackpointers else {
            return
        }
        
        if node.isInner {
            for each in node.children {
                self[parentOf: each.objectIdentifier] = node.inner
                addNode(each)
            }
        } else {
            //fatalError()
            //addElements(node.elements, to: node.leaf)
        }
    }

    @inlinable
    public mutating func removeNode(_ node: TreeNode) {
        guard maintainsBackpointers else {
            return
        }

        self[parentOf: node.objectIdentifier] = nil

        if node.isInner {
            for each in node.children {
                removeNode(each)
            }
        } else {
            //fatalError()
            //removeElements(node.elements, from: node.leaf)
        }
    }

}
