extension SummarizedTree.Node {
    
    public typealias InnerStorage = Storage<Self, InnerHeaderUpdater>
    
    public struct InnerHeaderUpdater: StorageHeaderUpdater {

        public typealias Context = SummarizedTree.Context
        public typealias StorageElement = Node
        
        @inlinable
        public static func update(header: inout Header, buffer: UnsafeBufferPointer<StorageElement>, adding: Range<Int>) {
            header.height = buffer.isEmpty ? 1 : buffer[0].height + 1
            for each in buffer[adding] {
                header.summary += each.summary
            }
        }
        
        @inlinable
        public static func update(header: inout Header, buffer: UnsafeBufferPointer<StorageElement>, removing: Range<Int>) {
            header.height = buffer.count == removing.count ? 1 : buffer[0].height + 1
            for each in buffer[removing] {
                header.summary -= each.summary
            }
        }
            
    }    
    
}
