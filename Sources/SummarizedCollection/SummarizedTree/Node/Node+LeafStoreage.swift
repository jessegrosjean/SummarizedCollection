extension Node {
    
    @usableFromInline
    struct LeafHeader {
        
        @usableFromInline
        var summary: Summary

        //@usableFromInline
        //var slotCount: Slot

        @usableFromInline
        var slotCapacity: Slot
        
        @inlinable
        init(slotCapacity: Slot) {
            self.summary = .zero
            //self.slotCount = 0
            self.slotCapacity = slotCapacity
        }
    }

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
        var header: LeafHeader

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
            self.header = .init(slotCapacity: Context.leafCapacity)
            self.header.summary = .summarize(elements: slots)
            //self.header.slotCount = Slot(slots.count)
        }

        @inlinable
        init(copying storage: LeafStorage) {
            self.slots = storage.slots
            self.header = storage.header
        }
        
        @inlinable
        var slotCount: Slot {
            Slot(slots.count)
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

extension Node.LeafStorage {
    
    @inlinable
    static func create() -> Self {
        Self.init()
    }
    
    @inlinable
    func copy() -> Self {
        Self.init(copying: self)
    }

}

extension Node.LeafHandle {
        
    public typealias Slot = Context.Slot
    public typealias Element = Node.Element
    public typealias Summary = Node.Summary

    @inlinable
    var slotCount: Slot {
        Slot(storage.slots.count)
    }

    @inlinable
    var slotCapacity: Slot {
        Slot(storage.header.slotCapacity)
    }

    var slotsAvailible: Slot {
        slotCapacity - slotCount
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
    mutating func slotsDistribute(with handle: inout Self, distribute: Distribute, ctx: inout Context) {
        let total = slotCount + handle.slotCount
        let partitionIndex = distribute.partitionIndex(
            total: total,
            capacity: slotCapacity
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
    
    mutating func slotsMergeOrDistribute(with handle: inout Self, distribute: Distribute, ctx: inout Context) -> Bool {
        if slotsAvailible < handle.slotCount {
            slotsAppend(handle, ctx: &ctx)
            return true
        } else {
            slotsDistribute(with: &handle, distribute: distribute, ctx: &ctx)
            return false
        }
    }
    
    @inlinable
    mutating func didChangeSlots() {
        storage.header.summary = Summary.summarize(elements: storage.slots)
    }
        
}
