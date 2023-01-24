public protocol StorageDelegate {
    
    associatedtype Context: SummarizedTreeContext
    associatedtype StorageElement

    typealias Slot = Context.Slot
    typealias Header = Context.Node.Header
    typealias Summary = Context.Summary
    typealias Storage = SummarizedTree<Context>.Node.Storage<StorageElement, Self>

    @inlinable
    @inline(__always)
    static func summarize(_ element: StorageElement) -> Summary

    @inlinable
    @inline(__always)
    static func update(
        header: inout Header,
        removing: Range<Int>,
        from storage: Unmanaged<Storage>,
        buffer: UnsafeBufferPointer<StorageElement>,
        ctx: inout Context
    )
    
    @inlinable
    @inline(__always)
    static func update(
        header: inout Header,
        adding: Range<Int>,
        from storage: Unmanaged<Storage>,
        buffer: UnsafeBufferPointer<StorageElement>,
        ctx: inout Context
    )

}

extension SummarizedTree.Node {
    
    public final class Storage<StoredElement, Delegate: StorageDelegate>: ManagedBuffer<Header, StoredElement>
        where Delegate.Context == Context, Delegate.StorageElement == StoredElement
    {
        
        @usableFromInline
        struct Handle {

            @usableFromInline
            typealias HeaderPointer = UnsafeMutablePointer<Header>

            @usableFromInline
            typealias StoredElementPointer = UnsafeMutablePointer<StoredElement>

            @usableFromInline
            var storage: Unmanaged<Storage>

            @usableFromInline
            var headerPtr: HeaderPointer
            
            @usableFromInline
            var storedElementsPtr: StoredElementPointer
            
            @usableFromInline
            let isMutable: Bool
            
            @inlinable
            init(storage: Unmanaged<Storage>, header: HeaderPointer, storedElements: StoredElementPointer) {
                self.init(
                    storage: storage,
                    header: header,
                    storedElements: storedElements,
                    isMutable: false
                )
            }

            @inlinable
            init(mutating: Self) {
                self.init(
                    storage: mutating.storage,
                    header: mutating.headerPtr,
                    storedElements: mutating.storedElementsPtr,
                    isMutable: true
                )
            }
            
            @inlinable
            init(storage: Unmanaged<Storage>, header: HeaderPointer, storedElements: StoredElementPointer, isMutable: Bool) {
                self.storage = storage
                self.headerPtr = header
                self.storedElementsPtr = storedElements
                self.isMutable = isMutable
            }

        }
        
        @inlinable
        static func create(with capacity: Slot) -> Self {
            unsafeDowncast(Self.create(minimumCapacity: Int(capacity)) { storage in
                .init(slotCapacity: capacity)
            }, to: Self.self)
        }
        
        @inlinable
        static func create(with capacity: Slot, update: (Handle)->()) -> Self {
            let newStorage = Self.create(with: capacity)
            newStorage.mut { handle in
                update(handle)
            }
            return newStorage
        }

        @inlinable
        func copy() -> Self {
            withUnsafeMutablePointers { header, elements in
                Self.create(with: header.pointee.slotCapacity) { copyHandle in
                    copyHandle.headerPtr.pointee = header.pointee
                    copyHandle.storedElementsPtr.initialize(from: elements, count: Int(header.pointee.slotCount))
                }
            }
        }

        @inlinable
        deinit {
            _ = withUnsafeMutablePointers { header, elements in
                elements.deinitialize(count: Int(header.pointee.slotCount))
            }
        }
        
        @inlinable
        @inline(__always)
        func rd<R>(_ body: (Handle) throws -> R) rethrows -> R {
            try withUnsafeMutablePointers { header, storedElements in
                try body(.init(storage: .passUnretained(self), header: header, storedElements: storedElements))
            }
        }
     
        @inlinable
        @inline(__always)
        func mut<R>(_ body: (Handle) throws -> R) rethrows -> R {
            try self.rd {
                try body(Handle(mutating: $0))
            }
        }

    }
    
}

extension SummarizedTree.Node.Storage.Handle {
        
    @usableFromInline
    typealias Slot = SummarizedTree.Node.Slot
    
    @usableFromInline
    typealias Summary = SummarizedTree.Summary

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
    var buffer: UnsafeBufferPointer<StoredElement> {
        .init(start: storedElementsPtr, count: Int(slotCount))
    }

    @inlinable
    subscript(_ range: Range<Slot>) -> UnsafeBufferPointer<StoredElement> {
        assert(0 <= range.lowerBound && range.upperBound <= slotCount)
        return .init(start: storedElementsPtr.advanced(by: Int(range.lowerBound)), count: range.count)
    }

    @inlinable
    subscript(_ range: Range<Slot>) -> UnsafeRawBufferPointer {
        assert(0 <= range.lowerBound && range.upperBound <= slotCount)
        return .init(start: storedElementsPtr.advanced(by: Int(range.lowerBound)), count: range.count)
    }

}

extension SummarizedTree.Node.Storage.Handle {
    
    @usableFromInline
    typealias Storage = SummarizedTree.Node.Storage<StoredElement, Delegate>
    
    @usableFromInline
    enum Distribute {

        case even
        case compact
        
        @inlinable
        func partitionIndex(total: Slot, capacity: Slot) -> Slot {
            switch self {
            case .even:
                return (total + 1) / 2
            case .compact:
                return capacity
            }
        }

    }

    @inlinable
    public subscript(_ index: Slot) -> StoredElement {
        get {
            assert(0 <= index && index < slotCount)
            return storedElementPointer(at: index).pointee
        }
        
        nonmutating _modify {
            assertMutable()
            assert(0 <= index && index < slotCount)
            var value = storedElementPointer(at: index).move()
            headerPtr.pointee.summary -= Delegate.summarize(value)
            yield &value
            headerPtr.pointee.summary += Delegate.summarize(value)
            storedElementPointer(at: index).initialize(to: value)
        }
    }

    @inlinable
    func split(at index: Slot, ctx: inout Context) -> Storage {
        assert(index <= slotCount)

        return Storage.create(with: slotCapacity) { handle in
            if index != slotCount {
                willRemove(index..<slotCount, ctx: &ctx)
                
                moveInitializeStoredElements(
                    range: index..<slotCount,
                    to: 0,
                    of: handle
                )

                handle.slotCount = slotCount - index
                handle.didAdd(0..<handle.slotCount, ctx: &ctx)

                slotCount = index
            }
        }
    }
    
    @inlinable
    func distributeStoredElements(with handle: Self, distribute: Distribute, ctx: inout Context) {
        let total = slotCount + handle.slotCount
        let partitionIndex = distribute.partitionIndex(
            total: total,
            capacity: slotCapacity
        )
        
        if partitionIndex < slotCount {
            // self to other
            handle.replaceSubrange(0..<0, with: self[partitionIndex..<slotCount], ctx: &ctx)
            removeSubrange(partitionIndex..<slotCount, ctx: &ctx)
        } else if partitionIndex > slotCount {
            // other to self
            let otherEnd = partitionIndex - slotCount
            replaceSubrange(slotCount..<slotCount, with: handle[0..<otherEnd], ctx: &ctx)
            handle.removeSubrange(0..<otherEnd, ctx: &ctx)
        }
    }
    
    @inlinable
    func mergeOrDistributeStoredElements(with handle: Self, distribute: Distribute, ctx: inout Context) -> Bool {
        if slotsAvailible >= handle.slotCount {
            append(contentsOf: handle, ctx: &ctx)
            return true
        } else {
            distributeStoredElements(with: handle, distribute: distribute, ctx: &ctx)
            return false
        }
    }
    
    @inlinable
    func remove(at i: Slot, ctx: inout Context) -> StoredElement {
        let result = storedElementPointer(at: i).pointee
        replaceSubrange(i..<i + 1, with: EmptyCollection(), ctx: &ctx)
        return result
    }
    
    @inlinable
    func removeSubrange(_ subrange: Range<Slot>, ctx: inout Context) {
        replaceSubrange(subrange, with: EmptyCollection(), ctx: &ctx)
    }

    @inlinable
    func insert(_ newElement: StoredElement, at i: Slot, ctx: inout Context) {
        replaceSubrange(0..<0, with: CollectionOfOne(newElement), ctx: &ctx)
    }
    
    @inlinable
    func append(_ newElement: StoredElement, ctx: inout Context) {
        storedElementsPtr.advanced(by: Int(slotCount)).initialize(to: newElement)
        slotCount += 1
        didAdd(slotCount - 1..<slotCount, ctx: &ctx)
    }

    @inlinable
    func append(contentsOf storage: Storage, ctx: inout Context) {
        storage.rd { append(contentsOf: $0, ctx: &ctx) }
    }

    @inlinable
    func append(contentsOf handle: Self, ctx: inout Context) {
        handle.copyInitializeStoredElements(
            range: 0..<handle.slotCount,
            to: slotCount,
            of: self
        )
        slotCount += handle.slotCount
        didAdd(slotCount - handle.slotCount..<slotCount, ctx: &ctx)
    }

    @inlinable
    func append<S>(contentsOf newElements: S, ctx: inout Context) where S : Sequence, S.Element == StoredElement {
        let start = slotCount
        var ptr = storedElementsPtr.advanced(by: Int(slotCount))
        for each in newElements {
            assert(slotsAvailible > 0)
            ptr.initialize(to: each)
            ptr = ptr.advanced(by: 1)
            slotCount += 1
        }
        didAdd(start..<slotCount, ctx: &ctx)
    }

    @inlinable
    func replaceSubrange<C>(_ subrange: Range<Slot>, with newElements: C, ctx: inout Context)
        where C : Collection, C.Element == StoredElement
    {
        let changeInLength = newElements.count - subrange.count
        let endLength = Slot(Int(slotCount) + changeInLength)
        
        assertMutable()
        assert(subrange.endIndex <= slotCount)
        assert(endLength <= slotCapacity)

        // Remove old
        if !subrange.isEmpty {
            willRemove(subrange.startIndex..<subrange.endIndex, ctx: &ctx)
            storedElementPointer(at: subrange.lowerBound).deinitialize(count: subrange.count)
        }

        // Move tail
        let tailCount = slotCount - subrange.upperBound
        if tailCount > 0 {
            let newTailStart = Int(subrange.upperBound) + changeInLength
            let newTailStartPtr = storedElementsPtr.advanced(by: newTailStart)
            newTailStartPtr.moveInitialize(
                from: storedElementPointer(at: subrange.upperBound),
                count: Int(tailCount)
            )
        }
        
        // Insert new
        if !newElements.isEmpty {
            var ptr = storedElementsPtr.advanced(by: Int(subrange.lowerBound))
            for each in newElements {
                ptr.initialize(to: each)
                ptr = ptr.advanced(by: 1)
            }
        }
        
        slotCount -= Slot(subrange.count)
        slotCount += Slot(newElements.count)
        
        didAdd(subrange.lowerBound..<subrange.lowerBound + Slot(newElements.count), ctx: &ctx)
    }
    
    @inlinable
    @inline(__always)
    func willRemove(_ range: Range<Slot>, ctx: inout Context) {
        Delegate.update(
            header: &headerPtr.pointee,
            removing: Int(range.startIndex)..<Int(range.endIndex),
            from: storage,
            buffer: buffer,
            ctx: &ctx
        )
    }

    @inlinable
    @inline(__always)
    func didAdd(_ range: Range<Slot>, ctx: inout Context) {
        Delegate.update(
            header: &headerPtr.pointee,
            adding: Int(range.startIndex)..<Int(range.endIndex),
            from: storage,
            buffer: buffer,
            ctx: &ctx
        )
    }

    @inlinable
    func assertMutable() {
        assert(isMutable)
    }

}

extension SummarizedTree.Node.Storage.Handle {

    @inlinable
    func storedElementPointer(at index: Slot) -> UnsafeMutablePointer<StoredElement> {
        assert(0 <= index && index < slotCount)
        return storedElementsPtr.advanced(by: Int(index))
    }

    @inlinable
    func moveStoredElement(at index: Slot) -> StoredElement {
        assertMutable()
        assert(0 <= index && index < slotCount)
        return storedElementsPtr.advanced(by: Int(index)).move()
    }

    @inlinable
    func moveInitializeStoredElements(range: Range<Slot>, to index: Slot, of target: Self) {
        assert(range.upperBound <= slotCapacity)
        assert(index + Slot(range.count) <= target.slotCapacity)
        assertMutable()
        target.assertMutable()
        target.storedElementsPtr
            .advanced(by: Int(index))
            .moveInitialize(
                from: storedElementsPtr.advanced(by: Int(range.startIndex)),
                count: range.count
            )
    }

    @inlinable
    func copyInitializeStoredElements(range: Range<Slot>, to index: Slot, of target: Self) {
        assert(range.upperBound <= slotCapacity)
        assert(index + Slot(range.count) <= target.slotCapacity)
        target.assertMutable()
        target.storedElementsPtr
            .advanced(by: Int(index))
            .initialize(
                from: storedElementsPtr.advanced(by: Int(range.startIndex)),
                count: range.count
            )
    }
    
}