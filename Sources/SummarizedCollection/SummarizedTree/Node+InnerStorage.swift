extension SummarizedTree.Node {
    
    public typealias InnerStorage = Storage<Self, InnerStorageDelegate>
    
    public struct InnerStorageDelegate: StorageDelegate {
        
        public typealias Context = SummarizedTree.Context
        public typealias StorageElement = Node

        @inlinable
        @inline(__always)
        public static func summarize(_ element: SummarizedTree<Context>.Node.Node) -> Summary {
            element.summary
        }

        @inlinable
        @inline(__always)
        public static func update(
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
            ctx.removeChildren(buffer[removing], from: storage)
        }
        
        @inlinable
        @inline(__always)
        public static func update(
            header: inout Header,
            adding: Range<Int>,
            from storage: Unmanaged<InnerStorage>,
            buffer: UnsafeBufferPointer<StorageElement>,
            ctx: inout Context
        ) {
            header.height = buffer.isEmpty ? 1 : buffer[0].height + 1
            for each in buffer[adding] {
                header.summary += each.summary
            }
            ctx.addChildren(buffer[adding], to: storage)
        }
    }    
    
}
