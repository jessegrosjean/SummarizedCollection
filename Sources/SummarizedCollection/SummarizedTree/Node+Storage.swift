public protocol StorageHeaderUpdater {
    
    associatedtype Context: SummarizedTreeContext
    associatedtype StorageElement

    typealias Slot = Context.Slot

    @inlinable
    @inline(__always)
    static func update(
        header: inout SummarizedTree<Context>.Node.Header,
        buffer: UnsafeBufferPointer<StorageElement>,
        removing: Range<Slot>
    )

    @inlinable
    @inline(__always)
    static func update(
        header: inout SummarizedTree<Context>.Node.Header,
        buffer: UnsafeBufferPointer<StorageElement>,
        adding: Range<Slot>
    )
    
}

extension SummarizedTree.Node {
    
    public final class Storage<StoredElement, HeaderUpdater: StorageHeaderUpdater>: ManagedBuffer<Header, StoredElement>
        where HeaderUpdater.Context == Context, HeaderUpdater.StorageElement == StoredElement
    {
        
        public struct Handle {
            
            @usableFromInline
            typealias HeaderPointer = UnsafeMutablePointer<Header>

            @usableFromInline
            typealias StoredElementPointer = UnsafeMutablePointer<StoredElement>

            @usableFromInline
            var headerPtr: HeaderPointer
            
            @usableFromInline
            var storedElementsPtr: StoredElementPointer
            
            @usableFromInline
            let isMutable: Bool
            
            @inlinable
            init(header: HeaderPointer, storedElements: StoredElementPointer) {
                self.init(header: header, storedElements: storedElements, isMutable: false)
            }

            @inlinable
            init(mutating: Self) {
                self.init(header: mutating.headerPtr, storedElements: mutating.storedElementsPtr, isMutable: true)
            }
            
            @inlinable
            init(header: HeaderPointer, storedElements: StoredElementPointer, isMutable: Bool) {
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
                try body(.init(header: header, storedElements: storedElements))
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
        
    public typealias Slot = SummarizedTree.Node.Slot
    public typealias Summary = SummarizedTree.Summary

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

    @inlinable
    func willRemove(_ range: Range<Slot>) {
        HeaderUpdater.update(header: &headerPtr.pointee, buffer: buffer, removing: range)
    }

    @inlinable
    func didAdd(_ range: Range<Slot>) {
        HeaderUpdater.update(header: &headerPtr.pointee, buffer: buffer, adding: range)
    }

    @inlinable
    func assertMutable() {
        assert(isMutable)
    }

}

extension SummarizedTree.Node.Storage.Handle {
    
    public typealias Storage = SummarizedTree.Node.Storage<StoredElement, HeaderUpdater>
    
    public enum Distribute {

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
    func split(at index: Slot) -> Storage {
        assert(index <= slotCount)

        return Storage.create(with: slotCapacity) { handle in
            if index != slotCount {
                willRemove(index..<slotCount)
                
                moveInitializeStoredElements(
                    range: index..<slotCount,
                    to: 0,
                    of: handle
                )

                handle.slotCount = slotCount - index
                handle.didAdd(0..<Slot(handle.count))

                slotCount = index
            }
        }
    }
    
    @inlinable
    func distributeStoredElements(with handle: Self, distribute: Distribute) {
        let total = slotCount + handle.slotCount
        let partitionIndex = distribute.partitionIndex(
            total: total,
            capacity: slotCapacity
        )
        
        if partitionIndex < slotCount {
            // self to other
            handle.replaceSubrange(0..<0, with: self[partitionIndex..<slotCount])
            removeSubrange(partitionIndex..<slotCount)
        } else if partitionIndex > slotCount {
            // other to self
            let otherEnd = partitionIndex - slotCount
            replaceSubrange(slotCount..<slotCount, with: handle[0..<otherEnd])
            handle.removeSubrange(0..<otherEnd)
        }
    }
    
    @inlinable
    func mergeOrDistributeStoredElements(with handle: Self, distribute: Distribute) -> Bool {
        if slotsAvailible >= handle.slotCount {
            append(contentsOf: handle)
            return true
        } else {
            distributeStoredElements(with: handle, distribute: distribute)
            return false
        }
    }
    
}

extension SummarizedTree.Node.Storage.Handle: Collection {

    @inlinable
    public var count: Int { Int(slotCount) }

    @inlinable
    public var startIndex: Slot { 0 }
    
    @inlinable
    public var endIndex: Slot { slotCount }

    @inlinable
    public var indices: Range<Slot> { startIndex..<endIndex }
    
    @inlinable
    public func index(after i: Slot) -> Slot { i + 1 }

    @inlinable
    public subscript(_ index: Slot) -> StoredElement {
        get {
            assert(0 <= index && index < slotCount)
            return storedElementPointer(at: index).pointee
        }
        
        nonmutating _modify {
            assertMutable()
            assert(0 <= index && index < slotCount)
            willRemove(index..<index + 1)
            var value = storedElementPointer(at: index).move()
            yield &value
            storedElementPointer(at: index).initialize(to: value)
            didAdd(index..<index + 1)
        }
    }

}

extension SummarizedTree.Node.Storage.Handle: BidirectionalCollection {

    @inlinable
    public func index(before i: Slot) -> Slot { i - 1 }
    
    @inlinable
    public func index(_ i: Slot, offsetBy distance: Int) -> Slot { Slot(Int(i) + distance) }
}

extension SummarizedTree.Node.Storage.Handle: RandomAccessCollection {}

extension SummarizedTree.Node.Storage.Handle: RangeReplaceableCollection {

    public init() {
        fatalError()
    }

    @inlinable
    public func remove(at i: Slot) -> StoredElement {
        let result = storedElementPointer(at: i).pointee
        replaceSubrange(i..<i + 1, with: EmptyCollection())
        return result
    }
    
    @inlinable
    public func removeSubrange(_ subrange: Range<Slot>) {
        replaceSubrange(subrange, with: EmptyCollection())
    }

    @inlinable
    public func insert(_ newElement: StoredElement, at i: SummarizedTree<Context>.Node.Slot) {
        replaceSubrange(0..<0, with: CollectionOfOne(newElement))
    }
    
    @inlinable
    public func append(_ newElement: StoredElement) {
        storedElementsPtr.advanced(by: Int(slotCount)).initialize(to: newElement)
        slotCount += 1
        didAdd(slotCount - 1..<slotCount)
    }

    @inlinable
    public func append(contentsOf storage: Storage) {
        storage.rd { append(contentsOf: $0) }
    }

    @inlinable
    public func append(contentsOf handle: Self) {
        handle.copyInitializeStoredElements(
            range: 0..<handle.slotCount,
            to: slotCount,
            of: self
        )
        slotCount += handle.slotCount
        didAdd(slotCount - handle.slotCount..<slotCount)
    }

    @inlinable
    public func append<S>(contentsOf newElements: S) where S : Sequence, S.Element == StoredElement {
        let start = slotCount
        var ptr = storedElementsPtr.advanced(by: Int(slotCount))
        for each in newElements {
            assert(slotsAvailible > 0)
            ptr.initialize(to: each)
            ptr = ptr.advanced(by: 1)
            slotCount += 1
        }
        didAdd(start..<slotCount)
    }

    @inlinable
    public func replaceSubrange<C>(_ subrange: Range<Slot>, with newElements: C)
        where C : Collection, C.Element == StoredElement
    {
        let changeInLength = newElements.count - subrange.count
        let endLength = Slot(Int(slotCount) + changeInLength)
        
        assertMutable()
        assert(subrange.endIndex <= slotCount)
        assert(endLength <= slotCapacity)

        // Remove old
        if !subrange.isEmpty {
            willRemove(subrange.startIndex..<subrange.endIndex)
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
        
        didAdd(subrange.lowerBound..<subrange.lowerBound + Slot(newElements.count))
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
