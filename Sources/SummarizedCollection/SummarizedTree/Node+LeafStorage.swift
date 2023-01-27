extension SummarizedTree.Node {
    
    @usableFromInline
    typealias LeafStorage = Storage<Element, LeafStorageDelegate>

    @usableFromInline
    struct LeafStorageDelegate: StorageDelegate {
        
        @usableFromInline
        typealias Context = SummarizedTree.Context

        @usableFromInline
        typealias StorageElement = Element
        
        @inlinable
        @inline(__always)
        static func summarize(_ element: SummarizedTree<Context>.Node.Element) -> Summary {
            Summary.summarize(element: element)
        }
        
        @inlinable
        @inline(__always)
        static func update(
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
                ctx[trackedLeafOf: each] = .init(inner: leaf)
            }
        }
        
        @inlinable
        @inline(__always)
        static func update(
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
                ctx[trackedLeafOf: each] = nil
            }
        }

    }
    
}
