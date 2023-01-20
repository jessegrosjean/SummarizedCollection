extension SummarizedTree.Node {
    
    public typealias LeafStorage = Storage<Element, LeafHeaderUpdater>

    public struct LeafHeaderUpdater: StorageHeaderUpdater {
        
        public typealias Context = SummarizedTree.Context
        public typealias StorageElement = Element
        
        @inlinable
        public static func update(header: inout Header, buffer: UnsafeBufferPointer<StorageElement>, adding: Range<Slot>) {
            header.height = 0
            header.summary += Summary.summarize(elements: buffer[Int(adding.startIndex)..<Int(adding.endIndex)])
        }
        
        @inlinable
        public static func update(header: inout Header, buffer: UnsafeBufferPointer<StorageElement>, removing: Range<Slot>) {
            header.height = 0
            header.summary -= Summary.summarize(elements: buffer[Int(removing.startIndex)..<Int(removing.endIndex)])
        }

    }
    
}
