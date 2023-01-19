extension SummarizedTree.Node {

    @usableFromInline
    struct InnerHandle {
        
        @usableFromInline
        var storage: InnerStorage
        
        @inlinable
        init(storage: InnerStorage) {
            self.storage = storage
        }
    }
    
    public final class InnerStorage {

        @usableFromInline
        var header: Node.Header
        
        @usableFromInline
        var slots: ContiguousArray<Node>
        
        @inlinable
        init() {
            self.slots = []
            self.slots.reserveCapacity(Int(Context.innerCapacity))
            self.header = .init(slotCapacity: Slot(slots.capacity))
            self.header.height = 1
        }

        @inlinable
        init(slots: ContiguousArray<Node>) {
            assert(slots.count <= Context.innerCapacity)
            self.slots = slots
            self.slots.reserveCapacity(Int(Context.innerCapacity))
            self.header = .init(
                height:(slots.first?.height ?? 0) + 1,
                summary: slots.reduce(.zero) { $0 + $1.summary },
                slotCount: Slot(slots.count),
                slotCapacity: Slot(slots.capacity)
            )
        }

        @inlinable
        init(copying storage: InnerStorage) {
            self.slots = storage.slots
            self.header = storage.header
        }
                
        @inlinable
        @inline(__always)
        func rd<R>(_ body: (InnerHandle) throws -> R) rethrows -> R {
            try body(.init(storage: self))
        }

        @inlinable
        @inline(__always)
        func mut<R>(_ body: (inout InnerHandle) throws -> R) rethrows -> R {
            var handle = InnerHandle(storage: self)
            return try body(&handle)
        }

        @inlinable
        @inline(__always)
        func append(_ node: Node, ctx: inout Context) {
            mut { $0.slotAppend(node, ctx: &ctx) }
        }

        @inlinable
        @inline(__always)
        func append(_ storage: InnerStorage, ctx: inout Context) {
            mut { handle in
                storage.rd { storageHandle in
                    handle.slotsAppend(storageHandle, ctx: &ctx)
                }
            }

        }
    }
    
}

extension SummarizedTree.Node.InnerStorage {
    
    public typealias Node = SummarizedTree.Node
    
    @inlinable
    static func create() -> Self {
        Self.init()
    }
    
    @inlinable
    static func create(update: (inout Node.InnerHandle)->()) -> Self {
        let newStorage = Self.create()
        newStorage.mut { handle in
            update(&handle)
        }
        return newStorage
    }

    @inlinable
    func copy() -> Self {
        Self.init(copying: self)
    }

}

extension SummarizedTree.Node.InnerHandle {
        
    public typealias Node = SummarizedTree.Node

    @usableFromInline
    typealias Slot = Context.Slot
    
    @inlinable
    var header: Node.Header {
        get {
            storage.header
        }
        _modify {
            yield &storage.header
        }
    }

    @inlinable
    var slotCount: Slot {
        Slot(storage.slots.count)
    }
    
    @inlinable
    var slots: ContiguousArray<Node> {
        storage.slots
    }
    
    @inlinable
    subscript(_ slot: Slot) -> Node {
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
    mutating func slotSplit(at slot: Slot, ctx: inout Context) -> Node.InnerStorage {
        let split = storage.slots.split(index: Int(slot))
        didChangeSlots()
        return .init(slots: split)
    }

    @inlinable
    mutating func slotInsert(_ slotElement: Node, at slot: Slot, ctx: inout Context) {
        storage.slots.insert(slotElement, at: Int(slot))
        didChangeSlots()
    }
    
    @inlinable
    mutating func slotAppend(_ slotElement: Node, ctx: inout Context) {
        storage.slots.append(slotElement)
        didChangeSlots()
    }

    @inlinable
    mutating func slotsAppend(_ appending: Node.InnerStorage, ctx: inout Context) {
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
        if header.slotsAvailible >= handle.slotCount {
            slotsAppend(handle, ctx: &ctx)
            return true
        } else {
            slotsDistribute(with: &handle, distribute: distribute, ctx: &ctx)
            return false
        }
    }

    @inlinable
    mutating func didChangeSlots() {
        storage.header.height = (storage.slots.first?.height ?? 0) + 1
        storage.header.slotCount = Slot(storage.slots.count)
        storage.header.summary = .zero
                
        
        /*storage.slots.withUnsafeBufferPointer { p in
            for i in 0..<p.count {
                p.baseAddress!.advanced(by: i).
                let unmaned: Unmanaged<Node> = .passUnretained(p.baseAddress!.advanced(by: i).pointee)
                storage.header.summary = unmaned.takeUnretainedValue().summary
                
            }
        }*/
        
        for i in storage.slots.indices {
            storage.header.summary += storage.slots[i].summary
        }
        
        //for each in storage.slots {
        //    storage.header.summary += each.summary
        //}
    }

}

extension ContiguousArray {
    
    @inlinable
    mutating func split(index: Index) -> Self {
        let split = ContiguousArray(self[index...])
        removeSubrange(index...)
        return split
    }
        
}
