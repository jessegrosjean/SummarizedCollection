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
            removing: Range<Int>,
            from storage: Unmanaged<LeafStorage>,
            buffer: UnsafeBufferPointer<StorageElement>,
            ctx: inout Context
        ) {
            header.height = 0
            header.summary -= Summary.summarize(elements: buffer[removing])
            ctx.removeElements(buffer[removing], from: storage)
        }
        
        @inlinable
        @inline(__always)
        public static func update(
            header: inout Header,
            adding: Range<Int>,
            from storage: Unmanaged<LeafStorage>,
            buffer: UnsafeBufferPointer<StorageElement>,
            ctx: inout Context
        ) {
            header.height = 0
            header.summary += Summary.summarize(elements: buffer[adding])
            ctx.addElements(buffer[adding], to: storage)
        }
    }
    
}
