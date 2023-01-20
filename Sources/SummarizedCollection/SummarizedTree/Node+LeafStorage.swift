extension SummarizedTree.Node {
    
    public final class LeafStorage: ManagedBuffer<Header, Element> {
        
        @inlinable
        static func create() -> Self {
            unsafeDowncast(LeafStorage.create(minimumCapacity: Int(Context.leafCapacity)) { storage in
                .init(slotCapacity: Slot(storage.capacity))
            }, to: Self.self)
        }
        
        @inlinable
        static func create(update: (LeafHandle)->()) -> Self {
            let newStorage = Self.create()
            newStorage.mut { handle in
                update(handle)
            }
            return newStorage
        }
 
        @inlinable
        func copy() -> Self {
            withUnsafeMutablePointers { header, elements in
                Self.create { copyHandle in
                    copyHandle.headerPtr.pointee = header.pointee
                    copyHandle.elementsPtr.initialize(from: elements, count: Int(header.pointee.slotCount))
                }
            }
        }

        deinit {
            _ = withUnsafeMutablePointers { header, elements in
                elements.deinitialize(count: Int(header.pointee.slotCount))
            }
        }
        
        @inlinable
        var elements: Slice {
            .init(count: Int(header.slotCount), buffer: self)
        }

        @inlinable
        @inline(__always)
        func rd<R>(_ body: (LeafHandle) throws -> R) rethrows -> R {
            try withUnsafeMutablePointers { header, elements in
                try body(.init(header: header, elements: elements))
            }
        }
     
        @inlinable
        @inline(__always)
        func mut<R>(_ body: (LeafHandle) throws -> R) rethrows -> R {
            try self.rd {
                try body(LeafHandle(mutating: $0))
            }
        }
        
    }

    @usableFromInline
    struct LeafHandle {
        
        @usableFromInline
        typealias HeaderPointer = UnsafeMutablePointer<Header>

        @usableFromInline
        typealias ElementPointer = UnsafeMutablePointer<Element>

        @usableFromInline
        var headerPtr: HeaderPointer
        
        @usableFromInline
        var elementsPtr: ElementPointer
        
        @usableFromInline
        let isMutable: Bool

        @inlinable
        init(header: HeaderPointer, elements: ElementPointer) {
            self.init(header: header, elements: elements, isMutable: false)
        }

        @inlinable
        init(mutating: Self) {
            self.init(header: mutating.headerPtr, elements: mutating.elementsPtr, isMutable: true)
        }
        
        @inlinable
        init(header: HeaderPointer, elements: ElementPointer, isMutable: Bool) {
            self.headerPtr = header
            self.elementsPtr = elements
            self.isMutable = isMutable
        }

    }

}

extension SummarizedTree.Node.LeafHandle {
    
    public typealias Slot = Context.Slot
    public typealias Node = SummarizedTree.Node
    public typealias Element = Node.Element
    public typealias Summary = Node.Summary

    @inlinable
    var slotCount: Slot {
        get { headerPtr.pointee.slotCount }
        nonmutating set {
            assertMutable()
            headerPtr.pointee.slotCount = newValue
        }
    }
    
    @inlinable
    var slotCapacity: Slot {
        headerPtr.pointee.slotCapacity
    }

    @inlinable
    var slotsAvailible: Slot {
        headerPtr.pointee.slotsAvailible
    }

    @inlinable
    var slotsUnderflowing: Bool {
        headerPtr.pointee.slotsUnderflowing
    }

    @inlinable
    var firstSlotElement: Element? {
        slotCount > 0 ? self[0] : nil
    }

    @inlinable
    var lastSlotElement: Element? {
        slotCount > 0 ? self[slotCount - 1] : nil
    }
    
    @inlinable
    subscript(_ slot: Slot) -> Element {
        get {
            assert(0 <= slot && slot < slotCount)
            return slotsPointer(at: slot).pointee
        }
        
        nonmutating _modify {
            assertMutable()
            assert(0 <= slot && slot < slotCount)
            var value = slotsPointer(at: slot).move()
            yield &value
            slotsPointer(at: slot).initialize(to: value)
        }
    }

    @inlinable
    subscript(_ range: Range<Slot>) -> UnsafeBufferPointer<Element> {
        get {
            assert(0 <= range.lowerBound && range.upperBound <= slotCount)
            return .init(start: elementsPtr.advanced(by: Int(range.lowerBound)), count: range.count)
        }
    }

    @inlinable
    func slotsSplit(at slot: Slot, ctx: inout Context) -> Node.LeafStorage {
        assert(slot <= slotCount)

        return Node.LeafStorage.create() { handle in
            if slot != slotCount {
                slotsMoveInitialized(
                    range: slot..<slotCount,
                    to: 0,
                    of: handle
                )
                
                handle.slotCount = slotCount - slot
                handle.didChangeSlots()
                slotCount = slot
                didChangeSlots()
            }
        }
    }
    
    @inlinable
    func slotsAppend(_ storage: Node.LeafStorage, ctx: inout Context) {
        storage.rd { handle in
            slotsAppend(handle, ctx: &ctx)
        }
    }

    @inlinable
    func slotsAppend(_ handle: Self, ctx: inout Context) {
        handle.slotsCopyInitialized(
            range: 0..<handle.slotCount,
            to: slotCount,
            of: self
        )

        slotCount += handle.slotCount
        didChangeSlots()
    }

    @inlinable
    func slotsAppend<C>(_ elements: C)
        where C: Collection, Element == C.Element
    {
        slotsReplaceSubrange(slotCount..<slotCount, with: elements)
    }

    @inlinable
    func slotsReplaceSubrange<C>(_ subrange: Range<Slot>, with newElements: C)
        where C: Collection, Element == C.Element
    {
        let changeInLength = newElements.count - subrange.count
        
        assertMutable()
        assert(subrange.endIndex <= slotCount)
        assert((Int(slotCount) + changeInLength) <= Int(slotCapacity))

        // Remove old
        if !subrange.isEmpty {
            slotsPointer(at: subrange.lowerBound).deinitialize(count: subrange.count)
        }

        // Move tail
        let tailCount = Int(slotCount - subrange.upperBound)
        if tailCount > 0, !subrange.isEmpty {
            let newTailStart = Int(subrange.upperBound) + changeInLength
            let newTailStartPtr = elementsPtr.advanced(by: newTailStart)
            newTailStartPtr.moveInitialize(
                from: slotsPointer(at: subrange.upperBound),
                count: tailCount
            )
        }
        
        // Insert new
        if !newElements.isEmpty {
            var ptr = elementsPtr.advanced(by: Int(subrange.lowerBound))
            for each in newElements {
                ptr.initialize(to: each)
                ptr = ptr.advanced(by: 1)
            }
        }
        
        slotCount -= Slot(subrange.count)
        slotCount += Slot(newElements.count)
        
        didChangeSlots()
    }
        
    @inlinable
    func slotsDistribute(with handle: Self, distribute: Distribute, ctx: inout Context) {
        let total = slotCount + handle.slotCount
        let partitionIndex = distribute.partitionIndex(
            total: total,
            capacity: slotCapacity
        )
        
        if partitionIndex < slotCount {
            // self to other
            handle.slotsReplaceSubrange(0..<0, with: self[partitionIndex..<slotCount])
            slotsReplaceSubrange(partitionIndex..<slotCount, with: [])
        } else if partitionIndex > slotCount {
            // other to self
            let otherEnd = partitionIndex - slotCount
            slotsReplaceSubrange(slotCount..<slotCount, with: handle[0..<otherEnd])
            handle.slotsReplaceSubrange(0..<otherEnd, with: [])
        }
    }
    
    @inlinable
    func slotsMergeOrDistribute(with handle: Self, distribute: Distribute, ctx: inout Context) -> Bool {
        if slotsAvailible >= handle.slotCount {
            slotsAppend(handle, ctx: &ctx)
            return true
        } else {
            slotsDistribute(with: handle, distribute: distribute, ctx: &ctx)
            return false
        }
    }

    @inlinable
    func assertMutable() {
        assert(isMutable)
    }

    @inlinable
    func didChangeSlots() {
        headerPtr.pointee.height = 0
        headerPtr.pointee.summary = Summary.summarize(elements: UnsafeBufferPointer(start: elementsPtr, count: Int(slotCount)))
    }

    @inlinable
    func slotsPointer(at slot: Slot) -> UnsafeMutablePointer<Element> {
        assert(0 <= slot && slot < slotCount)
        return elementsPtr.advanced(by: Int(slot))
    }

    @inlinable
    func slotsMoveInitialized(range: Range<Slot>, to slot: Slot, of target: Self) {
        assert(range.upperBound <= slotCapacity, "Cannot move elements beyond source buffer capacity.")
        assert(slot + Slot(range.count) <= target.slotCapacity, "Cannot move elements beyond destination buffer capacity.")
      
        assertMutable()
        target.assertMutable()
      
        target.elementsPtr
            .advanced(by: Int(slot))
            .moveInitialize(
                from: elementsPtr.advanced(by: Int(range.startIndex)),
                count: Int(range.count)
            )
    }

    @inlinable
    func slotsCopyInitialized(range: Range<Slot>, to slot: Slot, of target: Self) {
        assert(range.upperBound <= slotCapacity, "Cannot move elements beyond source buffer capacity.")
        assert(slot + Slot(range.count) <= target.slotCapacity, "Cannot move elements beyond destination buffer capacity.")
      
        target.assertMutable()
      
        target.elementsPtr
            .advanced(by: Int(slot))
            .initialize(
                from: elementsPtr.advanced(by: Int(range.startIndex)),
                count: Int(range.count)
            )
    }

}

//#if DEBUG
extension SummarizedTree.Node.LeafHandle: CustomDebugStringConvertible {

    public var debugDescription: String {
        var result = "<LeafHandle>["
        for s in 0..<slotCount {
            if s != 0 {
                result.append(", ")
            }
            result.append("\(self[s])")
        }
        result.append("]")
        return result
    }

}
//#endif
