extension SummarizedTree.Node.Storage {
    
    @usableFromInline
    typealias Slot = SummarizedTree.Node.Slot
    
    @usableFromInline
    typealias Base = SummarizedTree.Node.Storage<StoredElement, Delegate>

    @usableFromInline
    struct SubSequence {
        
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
    var subSequence: SubSequence {
        return SubSequence(base: self, bounds: 0..<header.slotCount)
    }

    @inlinable
    subscript(bounds: Range<Slot>) -> SubSequence {
        return SubSequence(base: self, bounds: bounds)
    }

}

extension SummarizedTree.Node.Storage.SubSequence: Equatable {
    
    // Pointer based equatable
    
    @usableFromInline
    typealias StorageSubSequence = SummarizedTree<Context>.Node.Storage<StoredElement, Delegate>.SubSequence
    
    @inlinable
    static func == (lhs: StorageSubSequence, rhs: StorageSubSequence) -> Bool {
        lhs.base === rhs.base && lhs.bounds == rhs.bounds
    }
    
}


extension SummarizedTree.Node.Storage.SubSequence: Collection {
    
    @usableFromInline
    typealias Slot = SummarizedTree.Node.Slot

    @usableFromInline
    typealias Element = StoredElement
    
    @usableFromInline
    typealias Index = Slot

    @inlinable
    var startIndex: Slot {
        bounds.startIndex
    }
    
    @inlinable
    var endIndex: Slot {
        bounds.endIndex
    }

    @inlinable
    var indices: Range<Slot> {
        startIndex..<endIndex
    }
    
    @inlinable
    func index(after i: Slot) -> Slot {
        i + 1
    }

    @inlinable
    subscript(index: Slot) -> StoredElement {
        get {
            base.withUnsafeMutablePointerToElements { elementsPtr in
                elementsPtr.advanced(by: Int(index)).pointee
            }
        }
    }
    
}

extension SummarizedTree.Node.Storage.SubSequence: BidirectionalCollection {
    
    typealias Storage = SummarizedTree.Node.Storage

    @inlinable
    func index(before i: Slot) -> Slot { i - 1 }
    
    @inlinable
    func index(_ i: Slot, offsetBy distance: Int) -> Slot { Slot(Int(i) + distance) }

}

extension SummarizedTree.Node.Storage.SubSequence: RandomAccessCollection {}

extension SummarizedTree.Node.Storage.SubSequence: Sequence {}

#if DEBUG

extension SummarizedTree.Node.Storage.SubSequence: CustomDebugStringConvertible {

    @usableFromInline
    var debugDescription: String {
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

#endif
