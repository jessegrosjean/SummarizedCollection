extension SummarizedTree {

    public struct ElementsBuffer {

        @usableFromInline
        let inner: Node.LeafStorage.SubSequence
        
        @inlinable
        init(inner: Node.LeafStorage.SubSequence) {
            self.inner = inner
        }
        
    }

}

extension SummarizedTree.ElementsBuffer: Equatable {
        
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.inner == rhs.inner
    }
    
}

extension SummarizedTree.ElementsBuffer: Collection {
    
    public typealias Slot = Context.Slot
    public typealias Element = SummarizedTree.Element
    public typealias Index = Slot

    @inlinable
    public var startIndex: Slot {
        inner.startIndex
    }
    
    @inlinable
    public var endIndex: Slot {
        inner.endIndex
    }

    @inlinable
    public var indices: Range<Slot> {
        inner.indices
    }
    
    @inlinable
    public func index(after i: Slot) -> Slot {
        inner.index(after: i)
    }

    @inlinable
    public subscript(index: Slot) -> Element {
        inner[index]
    }
    
}

extension SummarizedTree.ElementsBuffer: BidirectionalCollection {
    
    @inlinable
    public func index(before i: Slot) -> Slot {
        inner.index(before: i)
    }
    
    @inlinable
    public func index(_ i: Slot, offsetBy distance: Int) -> Slot {
        inner.index(i, offsetBy: distance)
    }

}

extension SummarizedTree.ElementsBuffer: RandomAccessCollection {}

extension SummarizedTree.ElementsBuffer: Sequence {}
