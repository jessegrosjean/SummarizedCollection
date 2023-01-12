extension SummarizedTree.Node {

    @usableFromInline
    struct LeafHandle {
        
        @usableFromInline
        var storage: LeafStorage
        
        @inlinable
        init(storage: LeafStorage) {
            self.storage = storage
        }
    }
    
    @usableFromInline
    final class LeafStorage {
        
        @usableFromInline
        var header: Node.Header

        @usableFromInline
        var slots: ContiguousArray<Element>
        
        @inlinable
        init() {
            self.slots = []
            self.slots.reserveCapacity(Int(Context.leafCapacity))
            self.header = .init(slotCapacity: Context.leafCapacity)
        }
        
        @inlinable
        init(slots: ContiguousArray<Element>) {
            assert(slots.count <= Context.leafCapacity)
            self.slots = slots
            self.slots.reserveCapacity(Int(Context.leafCapacity))
            self.header = .init(
                height: 0,
                summary: .summarize(elements: slots),
                slotCount: Slot(slots.count),
                slotCapacity: Context.leafCapacity
            )
        }

        @inlinable
        init(copying storage: LeafStorage) {
            self.slots = storage.slots
            self.header = storage.header
        }
        
        @inlinable
        func rd<R>(_ body: (LeafHandle) throws -> R) rethrows -> R {
            try body(.init(storage: self))
        }

        @inlinable
        func mut<R>(_ body: (inout LeafHandle) throws -> R) rethrows -> R {
            var handle = LeafHandle(storage: self)
            return try body(&handle)
        }
    }
    
}

extension SummarizedTree.Node.LeafStorage {
    
    @inlinable
    static func create() -> Self {
        Self.init()
    }
    
    @inlinable
    func copy() -> Self {
        Self.init(copying: self)
    }

}

extension SummarizedTree.Node.LeafHandle {
        
    public typealias Slot = Context.Slot
    public typealias Node = SummarizedTree.Node
    public typealias Element = Node.Element
    public typealias Summary = Node.Summary

    @inlinable
    var header: Node.Header {
        storage.header
    }

    @inlinable
    var slotCount: Slot {
        Slot(storage.slots.count)
    }
    
    @inlinable
    var slots: ContiguousArray<Element> {
        storage.slots
    }

    subscript(_ slot: Slot) -> Element {
        get {
            assert(0 <= slot && slot < slotCount)
            return storage.slots[Int(slot)]
        }
        
        _modify {
            assert(0 <= slot && slot < slotCount)
            yield &storage.slots[Int(slot)]
        }
    }

    @inlinable
    mutating func slotSplit(at slot: Slot, ctx: inout Context) -> Node.LeafStorage {
        let split = storage.slots.split(index: Int(slot))
        didChangeSlots()
        return .init(slots: split)
    }
    
    @inlinable
    mutating func slotsAppend(_ appending: Node.LeafStorage, ctx: inout Context) {
        storage.slots.append(contentsOf: appending.slots)
        didChangeSlots()
    }

    @inlinable
    mutating func slotsAppend(_ appendingFrom: Self, ctx: inout Context) {
        storage.slots.append(contentsOf: appendingFrom.storage.slots)
        didChangeSlots()
    }

    @inlinable
    mutating func slotRemove(at slot: Slot, ctx: inout Context) {
        storage.slots.remove(at: Int(slot))
        didChangeSlots()
    }

    @inlinable
    mutating func slotsDistribute(with handle: inout Self, distribute: Distribute, ctx: inout Context) {
        let total = slotCount + handle.slotCount
        let partitionIndex = distribute.partitionIndex(
            total: total,
            capacity: header.slotCapacity
        )
        
        if partitionIndex < slotCount {
            // self to other
            handle.storage.slots.insert(contentsOf: storage.slots[Int(partitionIndex)...], at: 0)
            storage.slots.removeSubrange(Int(partitionIndex)...)
            handle.didChangeSlots()
            didChangeSlots()
        } else if partitionIndex > slotCount {
            // other to self
            let otherEnd = Int(partitionIndex - slotCount)
            storage.slots.append(contentsOf: handle.storage.slots[..<otherEnd])
            handle.storage.slots.removeSubrange(0..<otherEnd)
            handle.didChangeSlots()
            didChangeSlots()
        }
    }
    
    @inlinable
    mutating func slotsMergeOrDistribute(with handle: inout Self, distribute: Distribute, ctx: inout Context) -> Bool {
        if header.slotsAvailible < handle.slotCount {
            slotsAppend(handle, ctx: &ctx)
            return true
        } else {
            slotsDistribute(with: &handle, distribute: distribute, ctx: &ctx)
            return false
        }
    }
    
    @inlinable
    mutating func didChangeSlots() {
        storage.header.height = 0
        storage.header.summary = Summary.summarize(elements: storage.slots)
        storage.header.slotCount = Slot(storage.slots.count)
    }
        
}
