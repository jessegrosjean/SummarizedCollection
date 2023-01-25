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

    // Tracking contexts will have non-nil rootIdentifier
    var rootIdentifier: ObjectIdentifier? { get set }

    // True if the given nodeIdentifier is tracked in this context
    func isTracking(id: ObjectIdentifier) -> Bool
    mutating func reserveCapacity(_ n: Int)
    
    subscript(trackedParentOf id: ObjectIdentifier) -> Unmanaged<Node.InnerStorage>? { get set }
    subscript(trackedParentOf element: Element) -> Unmanaged<Node.LeafStorage>? { get set }
    
    func validateInsert<C>(_ elements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element
    func validateReplace<C>(subrange: Range<Int>, with newElements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element

}

public protocol IdentifiedSummarizedTreeContext: SummarizedTreeContext where Element: Identifiable {

    func contains(id: Element.ID) -> Bool
    subscript(trackedParentOf id: Element.ID) -> Unmanaged<Node.LeafStorage>? { get }
    
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
        //#if DEBUG
        //    return 3
        //#else
            if let capacity = innerCapacityCache[ObjectIdentifier(Self.self)] as? Slot {
                return capacity
            }
            
            let capacityInBytes = 1024
            let capacity =  Slot(Swift.max(16, capacityInBytes / MemoryLayout<TreeNode>.stride))
            innerCapacityCache[ObjectIdentifier(Self.self)] = capacity
            return capacity
        //#endif
    }
    
    @inlinable
    public static var leafCapacity: Slot {
        //#if DEBUG
        //    return 3
        //#else
            if let capacity = leafCapacityCache[ObjectIdentifier(Self.self)] as? Slot {
                return capacity
            }

            let capacityInBytes = 1024
            let capacity = Slot(Swift.max(16, capacityInBytes / MemoryLayout<Element>.stride))
            leafCapacityCache[ObjectIdentifier(Self.self)] = capacity
            return capacity
       // #endif
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
    
    // Default context performs no tracking.
    // Tracking is only needed for contexts that support identified items
    // and need to walk tree backwards to get offset from item.ID.
    
    @inlinable
    public init(tracking: Node) {
        self.init()
    }

    @inlinable
    public var isTracking: Bool {
        rootIdentifier != nil
    }

    @inlinable
    public var rootIdentifier: ObjectIdentifier? {
        get { nil }
        set {}
    }
    
    @inlinable
    public func isTracking(id: ObjectIdentifier) -> Bool {
        false
    }
    
    @inlinable
    public func reserveCapacity(_ n: Int) {}
    
    @inlinable
    public subscript(trackedParentOf id: ObjectIdentifier) -> Unmanaged<Node.InnerStorage>? {
        get { nil }
        set { assert(false) }
    }
    
    @inlinable
    public subscript(trackedParentOf element: Element) -> Unmanaged<Node.LeafStorage>? {
        get { nil }
        set { assert(false) }
    }
    
    @inlinable
    public func validateInsert<C>(_ elements: C, in tree: SummarizedTree<Self>) where C: Collection, C.Element == Element {}
    
    @inlinable
    public func validateReplace<C>(
        subrange: Range<Int>,
        with newElements: C,
        in tree: SummarizedTree<Self>
    ) where C: Collection, C.Element == Element {}

}
