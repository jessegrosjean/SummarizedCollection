extension SummarizedTree.Node {
    
    public typealias LeafStorage = Storage<Element, LeafStorageDelegate>

    public struct LeafStorageDelegate: StorageDelegate {
        
        public typealias Context = SummarizedTree.Context
        public typealias StorageElement = Element
        
        @inlinable
        @inline(__always)
        public static func summarize(_ element: SummarizedTree<Context>.Node.Element) -> Summary {
            Summary.summarize(element: element)
        }
        
        @inlinable
        @inline(__always)
        public static func update(
            header: inout Header,
            adding: Range<Int>,
            to storage: Unmanaged<LeafStorage>,
            buffer: UnsafeBufferPointer<StorageElement>,
            ctx: inout Context
        ) {
            header.height = 0
            header.summary += Summary.summarize(elements: buffer[adding])
            
            if ctx.isTracking(id: ObjectIdentifier(storage.takeUnretainedValue())) {
                addElements(buffer[adding], to: storage, ctx: &ctx)
            }
        }
        
        @inlinable
        static func addElements<C>(_ elements: C, to leaf: Unmanaged<Node.LeafStorage>, ctx: inout Context) where C: Collection, C.Element == Element {
            for each in elements {
                ctx[trackedParentOf: each] = leaf
            }
        }
        
        @inlinable
        @inline(__always)
        public static func update(
            header: inout Header,
            removing: Range<Int>,
            from storage: Unmanaged<LeafStorage>,
            buffer: UnsafeBufferPointer<StorageElement>,
            ctx: inout Context
        ) {
            header.height = 0
            header.summary -= Summary.summarize(elements: buffer[removing])
            
            if ctx.isTracking(id: ObjectIdentifier(storage.takeUnretainedValue())) {
                removeElements(buffer[removing], from: storage, ctx: &ctx)
            }
        }
        
        @inlinable
        static func removeElements<C>(_ elements: C, from _: Unmanaged<Node.LeafStorage>, ctx: inout Context) where C: Collection, C.Element == Element {
            for each in elements {
                ctx[trackedParentOf: each] = nil
            }
        }

    }
    
}
