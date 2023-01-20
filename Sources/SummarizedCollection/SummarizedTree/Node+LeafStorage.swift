extension SummarizedTree.Node {
    
    public typealias LeafStorage = Storage<Element, LeafHeaderUpdater>

    public struct LeafHeaderUpdater: StorageHeaderUpdater {
        
        public typealias Context = SummarizedTree.Context
        public typealias StorageElement = Element
        
        @inlinable
        public static func update(header: inout Header, buffer: UnsafeBufferPointer<StorageElement>, adding: Range<Int>) {
            header.height = 0
            header.summary += Summary.summarize(elements: buffer[adding])
        }
        
        @inlinable
        public static func update(header: inout Header, buffer: UnsafeBufferPointer<StorageElement>, removing: Range<Int>) {
            header.height = 0
            header.summary -= Summary.summarize(elements: buffer[removing])
        }

    }
    
}
