public protocol SummarizedTreeContext {
    
    associatedtype Slot: FixedWidthInteger & UnsignedInteger
    associatedtype Summary: CollectionSummary
    
    typealias Element = Summary.Element
    typealias TreeNode = SummarizedTree<Self>.Node
    typealias Node = SummarizedTree<Self>.Node
    
    static var innerCapacity: Slot { get }
    static var leafCapacity: Slot { get }
    
    init()
    init(tracking: Node)

    mutating func setRoot(_ rootIdentifier: ObjectIdentifier)
    mutating func addChildren<C>(_ children: C, to inner: Unmanaged<Node.InnerStorage>) where C: Collection, C.Element == Node
    mutating func removeChildren<C>(_ children: C, from inner: Unmanaged<Node.InnerStorage>) where C: Collection, C.Element == Node
    mutating func addElements<C>(_ elements: C, to leaf: Unmanaged<Node.LeafStorage>) where C: Collection, C.Element == Element
    mutating func removeElements<C>(_ elements: C, from leaf: Unmanaged<Node.LeafStorage>) where C: Collection, C.Element == Element
    
    func validateInsert<C>(_ elements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element
    func validateReplace<C>(subrange: Range<Int>, with newElements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element

}

public protocol IdentifiedSummarizedTreeContext: SummarizedTreeContext where Element: Identifiable {

    subscript(parentOf nodeIdentifier: ObjectIdentifier) -> Unmanaged<Node.InnerStorage>? { get }
    subscript(parentOf id: Element.ID) -> Unmanaged<Node.LeafStorage>? { get }
    
}

@usableFromInline
var innerCapacityCache: [ObjectIdentifier: Any] = [:]

@usableFromInline
var leafCapacityCache: [ObjectIdentifier: Any] = [:]

@usableFromInline
var nonTrackingContextCache: [ObjectIdentifier: Any] = [:]

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

    @inlinable
    public static var nonTracking: Self {
        get {
            if let nonTracking = nonTrackingContextCache[ObjectIdentifier(Self.self)] as? Self {
                return nonTracking
            }
            let nonTracking = Self.init()
            nonTrackingContextCache[ObjectIdentifier(Self.self)] = nonTracking
            return nonTracking
        }
        set {}
    }
    
    @inlinable
    public init(tracking: Node) {
        self.init()
    }
    
    @inlinable
    public func setRoot(_ rootIdentifier: ObjectIdentifier) {}

    @inlinable
    public func addChildren<C>(_ children: C, to inner: Unmanaged<Node.InnerStorage>) where C: Collection, C.Element == Node {}

    @inlinable
    public func removeChildren<C>(_ children: C, from inner: Unmanaged<Node.InnerStorage>) where C: Collection, C.Element == Node {}

    @inlinable
    public func addElements<C>(_ elements: C, to leaf: Unmanaged<Node.LeafStorage>) where C: Collection, C.Element == Element {}

    @inlinable
    public func removeElements<C>(_ elements: C, from leaf: Unmanaged<Node.LeafStorage>) where C: Collection, C.Element == Element {}
    
    @inlinable
    public func validateInsert<C>(_ elements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element {}
    
    @inlinable
    public func validateReplace<C>(subrange: Range<Int>, with newElements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element {}

}
