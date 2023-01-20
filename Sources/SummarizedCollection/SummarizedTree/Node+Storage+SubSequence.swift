extension SummarizedTree.Node.Storage {
    
    public typealias Slot = SummarizedTree.Node.Slot
    public typealias Base = SummarizedTree.Node.Storage<StoredElement, HeaderUpdater>

    public struct SubSequence {
        
        @usableFromInline
        var bounds: Range<Slot>

        @usableFromInline
        var base: Base
        
        @inlinable
        init(base: Base, bounds: Range<Slot>) {
            self.base = base
            self.bounds = bounds
        }
    }

    @inlinable
    public var subSequence: SubSequence {
        return SubSequence(base: self, bounds: 0..<header.slotCount)
    }

    @inlinable
    public subscript(bounds: Range<Slot>) -> SubSequence {
        return SubSequence(base: self, bounds: bounds)
    }

}

extension SummarizedTree.Node.Storage.SubSequence: Collection {
    
    public typealias Slot = SummarizedTree.Node.Slot
    public typealias Element = StoredElement

    @inlinable
    public var startIndex: Slot {
        bounds.startIndex
    }
    
    @inlinable
    public var endIndex: Slot {
        bounds.endIndex
    }

    @inlinable
    public var indices: Range<Slot> {
        startIndex..<endIndex
    }
    
    @inlinable
    public func index(after i: Slot) -> Slot {
        i + 1
    }

    @inlinable
    public subscript(index: Slot) -> StoredElement {
        get {
            base.withUnsafeMutablePointerToElements { elementsPtr in
                elementsPtr.advanced(by: Int(index)).pointee
            }
        }
    }
    
}

extension SummarizedTree.Node.Storage.SubSequence: BidirectionalCollection {
    
    public typealias Storage = SummarizedTree.Node.Storage

    @inlinable
    public func index(before i: Slot) -> Slot { i - 1 }
    
    @inlinable
    public func index(_ i: Slot, offsetBy distance: Int) -> Slot { Slot(Int(i) + distance) }

}

extension SummarizedTree.Node.Storage.SubSequence: RandomAccessCollection {}

extension SummarizedTree.Node.Storage.SubSequence: Sequence {}

//#if DEBUG
extension SummarizedTree.Node.Storage.SubSequence: CustomDebugStringConvertible {

    public var debugDescription: String {
        var result = "<Storage.SubSequence>["
        for i in indices {
            if i != startIndex {
                result.append(", ")
            }
            result.append("\(self[i])")
        }
        result.append("]")
        return result
    }

}
//#endif
