extension SummarizedTree.Node {
    
    @usableFromInline
    typealias InnerStorage = Storage<Self, InnerStorageDelegate>
    
    @usableFromInline
    struct InnerStorageDelegate: StorageDelegate {
        
        @usableFromInline
        typealias Context = SummarizedTree.Context

        @usableFromInline
        typealias StorageElement = Node

        @inlinable
        @inline(__always)
        static func header(with capacity: Context.Slot) -> Header {
            .init(height: 1, summary: .zero, slotCount: 0, slotCapacity: capacity)
        }
        
        @inlinable
        @inline(__always)
        static func summarize(_ element: SummarizedTree<Context>.Node.Node) -> Summary {
            element.summary
        }
        
        @inlinable
        @inline(__always)
        static func update(
            header: inout Header,
            adding: Range<Int>,
            to storage: Unmanaged<InnerStorage>,
            buffer: UnsafeBufferPointer<StorageElement>,
            ctx: inout Context
        ) {
            header.height = buffer.isEmpty ? 1 : buffer[0].height + 1
            
            for each in buffer[adding] {
                header.summary += each.summary
            }
            
            if ctx.isTracking(id: ObjectIdentifier(storage.takeUnretainedValue())) {
                addChildren(buffer[adding], to: storage, ctx: &ctx)
            }
        }
        
        @inlinable
        static func addChildren<C>(_ children: C, to inner: Unmanaged<Node.InnerStorage>, ctx: inout Context) where C: Collection, C.Element == Node {
            for each in children {
                ctx[trackedParentOf: each.objectIdentifier] = .init(inner: inner)
                
                if each.isInner {
                    addChildren(each.children, to: .passUnretained(each.inner), ctx: &ctx)
                } else {
                    LeafStorageDelegate.addElements(each.elements, to: .passUnretained(each.leaf), ctx: &ctx)
                }
            }
        }

        @inlinable
        @inline(__always)
        static func update(
            header: inout Header,
            removing: Range<Int>,
            from storage: Unmanaged<InnerStorage>,
            buffer: UnsafeBufferPointer<StorageElement>,
            ctx: inout Context
        ) {
            header.height = buffer.count - removing.count == 0 ? 1 : buffer[0].height + 1
            
            for each in buffer[removing] {
                header.summary -= each.summary
            }
            
            if ctx.isTracking(id: ObjectIdentifier(storage.takeUnretainedValue())) {
                removeChildren(buffer[removing], from: storage, ctx: &ctx)
            }
        }
        
        @inlinable
        static func removeChildren<C>(_ children: C, from _: Unmanaged<Node.InnerStorage>, ctx: inout Context) where C: Collection, C.Element == Node {
            for each in children {
                ctx[trackedParentOf: each.objectIdentifier] = nil
                
                if each.isInner {
                    removeChildren(each.children, from: .passUnretained(each.inner), ctx: &ctx)
                } else {
                    LeafStorageDelegate.removeElements(each.elements, from: .passUnretained(each.leaf), ctx: &ctx)
                }
            }
        }
        
    }    
    
}
