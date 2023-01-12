extension SummarizedTree {
    
    public struct Cursor {
        
        public typealias Element = Context.Element
        public typealias Summary = Context.Summary
        public typealias Node = SummarizedTree.Node
        public typealias IndexDimension = CollectionIndexDimension<Summary>
        
        @usableFromInline
        struct Position: Equatable {
            
            @usableFromInline
            var nodeStart: Summary
            
            @usableFromInline
            var offset: Int
            
            init() {
                self.nodeStart = .zero
                self.offset = .zero
            }
            
            @inlinable
            mutating func moveFoward(_ node: Node) {
                nodeStart += node.summary
                offset = 0
            }
            
            @inlinable
            mutating func moveBackward(_ node: Node) {
                nodeStart -= node.summary
                offset = 0
            }
        }
        
        @usableFromInline
        struct Stack {
            
            @inlinable
            static var capacity: Int8 { 8 }
            
            @usableFromInline
            var depth: Int8
            
            @usableFromInline
            var values: (
                StackItem, StackItem, StackItem, StackItem,
                StackItem, StackItem, StackItem, StackItem
            )
        }
        
        @usableFromInline
        struct StackItem {
            
            let _node: Node
            var _childIndex: UInt16
            
            init(node: Node, childIndex: Int) {
                _node = node
                _childIndex = UInt16(childIndex)
            }
            
            var node: Node {
                _node
            }
            
            var childIndex: Int {
                get {
                    Int(_childIndex)
                }
                set {
                    _childIndex = UInt16(newValue)
                }
            }
            
            mutating func nextChild() -> Node? {
                if childIndex + 1 < node.slotCount {
                    _childIndex += 1
                    return node.rdInner { $0.slots[Int(childIndex)] }
                } else {
                    return nil
                }
            }
        }
        
        enum SeekAscendingResult {
            case found
            case notFound
            case seekDescending
        }
        
        @usableFromInline
        var root: Node
        
        @usableFromInline
        var version: Int
        
        @usableFromInline
        var stack: Stack
        
        @usableFromInline
        var position: Position = .init()
        
        @usableFromInline
        var atEnd = false
        
        init(
            root: Node,
            version: Int
        ) {
            self.root = root
            self.version = version
            self.stack = .init(repeating: .init(node: root, childIndex: 0))
        }
        
        init(_ other: Self) {
            self.root = other.root
            self.version = other.version
            self.stack = other.stack
            self.position = other.position
            self.atEnd = other.atEnd
        }
    }
}

extension SummarizedTree.Cursor {
    
    public typealias Cursor = SummarizedTree.Cursor

    // MARK: Elements
    
    public mutating func element() -> Element? {
        let leaf = leaf()
        let offset = position.offset
        if offset < leaf.count {
            return leaf[offset]
        } else {
            return nil
        }
    }
    
    public mutating func prevElement() -> Element? {
        if index == 0 {
            return nil
        }
        _ = prevBoundary(IndexDimension.self)
        return element()
    }

    public mutating func nextElement() -> Element? {
        if index == root.count {
            return nil
        }
        
        let element = element()
        _ = nextBoundary(IndexDimension.self)
        return element
    }
    
    public func uncheckedElement() -> Element {
        let leaf = uncheckedLeaf()
        let offset = position.offset
        return leaf[offset]
    }
    
    // MARK: Element Boundaries
    
    public mutating func isBoundary<B>(_ type: B.Type) -> Bool where B: CollectionBoundary, B.Element == Element {
        if position.offset == 0 {
            if B.canFragment {
                if let prevLeaf = peekPrevLeaf() {
                    return B.isBoundary(at: prevLeaf.count, elements: prevLeaf)
                } else {
                    return false
                }
            } else {
                _ = leaf()
                return true
            }
        } else {
            return B.isBoundary(at: position.offset, elements: leaf())
        }
    }
    
    public mutating func prevBoundary<B>(_ type: B.Type) -> Int? where B: CollectionBoundary, B.Element == Element {
        if isAfterEnd && isBoundary(type) {
            return index
        }
        
        while !isAtStart && !isBeforeStart {
            if let prev = B.boundary(before: position.offset, elements: leaf()) {
                position.offset = prev
                atEnd = false
                return index
            } else {
                if B.canFragment && position.offset > 0 {
                    position.offset = 0
                    if isBoundary(type) {
                        return index
                    }
                }
                prevLeafEnd()
            }
        }
        
        _ = prevLeaf()
        
        return nil
    }

    public mutating func nextBoundary<B>(_ type: B.Type) -> Int? where B: CollectionBoundary, B.Element == Element {
        if isBeforeStart && isBoundary(type) {
            return index
        }
        
        while !isAtEnd && !isAfterEnd {
            let leaf = leaf()
            if let next = B.boundary(after: position.offset, elements: leaf) {
                position.offset = next
                if next == leaf.count {
                    if index == root.count {
                        atEnd = true
                    } else {
                        _ = nextLeaf()
                    }
                }
                return index
            } else {
                _ = nextLeaf()
            }
        }
        
        _ = nextLeaf()
        
        return nil
    }
    
    public mutating func atOrPrevBoundary<B>(_ type: B.Type) -> Int? where B: CollectionBoundary, B.Element == Element {
        if isBoundary(type) {
            return index
        } else {
            return prevBoundary(type)
        }
    }

    public mutating func atOrNextBoundary<B>(_ type: B.Type) -> Int? where B: CollectionBoundary, B.Element == Element {
        if isBoundary(type) {
            return index
        } else {
            return nextBoundary(type)
        }
    }
    
    func sliceToPrevBoundary<B>(_ type: B.Type) -> ArraySlice<Element>? where B: CollectionBoundary, B.Element == Element {
        fatalError()
    }

    func sliceToNextBoundary<B>(_ type: B.Type) -> ArraySlice<Element>? where B: CollectionBoundary, B.Element == Element {
        fatalError()
    }

    // MARK: Position
    
    public var index: Int {
        position.nodeStart.count + position.offset
    }

    @inlinable
    public var summary: Summary {
        if isBeforeStart {
            return .zero
        } else if isAfterEnd {
            return root.summary
        }
        
        let nodeStart = position.nodeStart
        let slice = uncheckedLeaf()[0..<position.offset]
        return nodeStart + Summary.summarize(elements: slice)
    }

    public mutating func extent<D>() -> D where D: CollectionDimension, D.Summary == Summary {
        if isAfterEnd {
            return D.get(root.summary)
        } else {
            return D.get(position.nodeStart) + D.measure(leaf()[..<position.offset])
        }
    }

    public mutating func seek<B, O>(forward point: CollectionPoint<B, O>) -> Int where B.Summary == Summary {
        if point.base != .zero {
            _ = seek(forward: point.base)
        }
        
        if point.offset != .zero {
            _ = seek(forward: point.offset)
        }
        
        return index
    }

    public mutating func seek<B, O>(to point: CollectionPoint<B, O>) -> Int where B: CollectionDimension, O: CollectionDimension, B.Summary == Summary {
        if point.base != .zero {
            _ = seek(to: point.base)
        }
        
        if point.offset != .zero {
            _ = seek(forward: point.offset)
        }
        
        return index
    }

    public mutating func seek<D>(forward dimension: D) -> Int where D: CollectionDimension, D.Summary == Summary {
        if dimension == .zero {
            return index
        }
        
        let start = D.get(position.nodeStart)
        let offset = D.measure(leaf()[..<position.offset])
        return seek(to: start + offset + dimension)
    }

    public mutating func seek<D>(to dimension: D) -> Int where D: CollectionDimension, D.Summary == Summary {
        assert(dimension >= .zero && dimension <= .get(root.summary))
        
        if dimension < .get(summary) {
            resetToStart()
            return seek(to: dimension)
        }
        
        return seek(
            contains: { startSummary, nodeSummary in
                let startD = D.get(startSummary)
                let endD = startD + D.get(nodeSummary)
                return dimension <= endD
            },
            seek: { startSummary, nodeSummary, index, elements in
                let startD = D.get(startSummary)
                let target = dimension - startD
                return D.index(to: target, summary: nodeSummary, elements: elements)
            }
        )!
    }
    
    public mutating func seekNext<D>(_ type: D.Type) -> Int? where D: CollectionDimension, D.Summary == Summary {
        if isBeforeStart && isBoundary(type) {
            return index
        }

        if isAtEnd {
            stack.removeAll()
            return nil
        }
        
        return seek(
            contains: { startSummary, nodeSummary in
                D.get(nodeSummary) != .zero
            },
            seek: { startSummary, nodeSummary, index, elements in
                D.boundary(after: index, elements: elements)
            }
        )

    }
    
    public mutating func point<B, O>() -> CollectionPoint<B, O>
        where
            B: CollectionDimension,
            O: CollectionDimension, O.Summary == Summary
    {
        let leaf = leaf()
        let offset = O.measure(leaf[..<position.offset])
        var point = B.point(from: offset, summary: nil, elements: leaf)
        
        if point.base == .zero {
            var cursor = Cursor(self)
            while let leaf = cursor.prevLeaf() {
                let leafSummary = cursor.leafSummary()
                let leafB = B.get(leafSummary)
                let leafO = O.get(leafSummary)
                if leafB == .zero {
                    point.offset += leafO
                } else {
                    let leafP = B.point(from: leafO, summary: leafSummary, elements: leaf)
                    point.base += cursor.leafStart()
                    point.base += leafP.base
                    point.offset += leafP.offset
                    return point
                }
            }
        } else {
            point.base += leafStart()
        }
        
        return point
    }
    
    // MARK: Leaves

    public mutating func leaf() -> ArraySlice<Element> {
        if isBeforeStart {
            resetToStart()
        } else if isAfterEnd {
            resetToEnd()
        }
        return stack.last.node.rdLeaf { $0.slots[...] }
    }
    
    public func uncheckedLeaf() -> ArraySlice<Element> {
        assert(!isBeforeStart)
        assert(!isAfterEnd)
        return stack.last.node.rdLeaf { $0.slots[...] }
    }
    
    public var leafStartIndex: Int {
        position.nodeStart.count
    }

    public var leafStartSummary: Summary {
        position.nodeStart
    }

    public var leafIndex: Int {
        position.offset
    }

    public mutating func leafSummary() -> Summary {
        if isBeforeStart {
            assert(nextLeaf() != nil)
        }
        return stack.last.node.summary
    }

    public func leafStart<D>() -> D where D: CollectionDimension, D.Summary == Summary {
        D.get(position.nodeStart)
    }
    
    public mutating func leafEnd<D>() -> D where D: CollectionDimension, D.Summary == Summary {
        leafStart() + D.get(leafSummary())
    }
    
    public func peekPrevLeaf() -> ArraySlice<Element>? {
        if stack.depth <= 1 {
            var copy = Cursor(self)
            return copy.prevLeaf()
        } else {
            let parent = stack[stack.depth - 2]
            if parent.childIndex > 0 {
                return parent.node.rdInner { $0.slots[parent.childIndex - 1] }.rdLeaf { $0.slots[...] }
            } else {
                var copy = Cursor(self)
                return copy.prevLeaf()
            }
        }
    }
        
    public mutating func prevLeaf() -> ArraySlice<Element>? {
        if isBeforeStart {
            return nil
        } else if isAtStart {
            reset()
            return nil
        } else if isAfterEnd {
            reset()
            descendToLastLeaf(root)
            atEnd = root.count == 0
            return leaf()
        } else {
            atEnd = false
            
            while !stack.isEmpty {
                let stackItem = stack.pop()
                if stackItem.node.isInner {
                    if stackItem.childIndex > 0 {
                        let newIndex = stackItem.childIndex - 1
                        push(node: stackItem.node, childIndex: newIndex)
                        let child = stackItem.node.rdInner { $0.slots[newIndex] }
                        descendToLastLeaf(child)
                        position.moveBackward(child)
                        return leaf()
                    }
                } else {
                    position.offset = 0
                }
            }
            
            return nil
        }
    }

    public mutating func prevLeafEnd() {
        if let leaf = prevLeaf() {
            position.offset = leaf.count
        }
    }
    
    public func peakNextLeaf() -> ArraySlice<Element>? {
        if stack.depth <= 1 {
            var copy = Cursor(self)
            return copy.nextLeaf()
        } else {
            let parent = stack[stack.depth - 2]
            if parent.childIndex < parent.node.children.count + 1 {
                return parent.node.children[parent.childIndex + 1].elements[...]
            } else {
                var copy = Cursor(self)
                return copy.nextLeaf()
            }
        }
    }

    public mutating func nextLeaf() -> ArraySlice<Element>? {
        nextLeafInternal()
    }

    mutating func nextLeafInternal() -> ArraySlice<Element>? {
        if isBeforeStart {
            resetToStart()
            return leaf()
        } else if isAtEnd || isAfterEnd {
            stack.removeAll()
            return nil
        } else {
            while !stack.isEmpty {
                let i = stack.depth - 1
                let newSubtree: Node? = {
                    if stack[i].node.isInner {
                        return stack[i].nextChild()
                    } else {
                        position.moveFoward(stack[i].node)
                        return nil
                    }
                }()
                
                if let newSubtree = newSubtree {
                    descendToFirstLeaf(newSubtree)
                    return leaf()
                } else {
                    _ = stack.pop()
                }
            }
            
            atEnd = true
            return nil
        }
    }

    public mutating func descendToFirstLeaf(_ node: Node) {
        var node = node
        while true {
            push(node: node, childIndex: 0)
            if node.isInner {
                node = node.children.first!
            } else {
                return
            }
        }
    }
        
    public mutating func descendToLastLeaf(_ node: Node) {
        var node = node
        while true {
            if node.isInner {
                let lastIndex = node.children.count - 1
                let lastChild = node.children.last!
                position.moveFoward(node)
                position.moveBackward(lastChild)
                push(node: node, childIndex: lastIndex)
                node = lastChild
            } else {
                push(node: node, childIndex: 0)
                return
            }
        }

    }

    // MARK: Seeking Internal

    public typealias ContainsClosure = (_ start: Summary, _ node: Summary) -> Bool
    public typealias SeekClosure = (_ start: Summary, _ node: Summary, Int, ArraySlice<Element>) -> Int?

    public mutating func seek(contains: ContainsClosure, seek: SeekClosure) -> Int? {
        if isAfterEnd {
            return nil
        }
        
        switch seekInternalAscending(contains: contains, seek: seek) {
        case .found:
            break
        case .notFound:
            atEnd = true
            return nil
        case .seekDescending:
            seekInternalDescending(contains: contains, seek: seek)
        }
        
        if index == root.count {
            assert(!stack.isEmpty)
            atEnd = true
        }
        
        return index
    }
    
    mutating func seekInternalAscending(contains: ContainsClosure, seek: SeekClosure) -> SeekAscendingResult {
        if isBeforeStart && contains(position.nodeStart, root.summary) {
            push(node: root, childIndex: 0)
            return .seekDescending
        }
        
        while !stack.isEmpty {
            var stackItem = stack.pop()
            if stackItem.node.isInner {
                stackItem.childIndex += 1
                for child in stackItem.node.children[stackItem.childIndex...] {
                    if contains(position.nodeStart, child.summary) {
                        stack.append(stackItem)
                        push(node: child, childIndex: 0)
                        return .seekDescending
                    } else {
                        position.moveFoward(child)
                        stackItem.childIndex += 1
                    }
                }
            } else {
                let leafSummary = stackItem.node.summary
                if contains(position.nodeStart, leafSummary) {
                    stack.append(stackItem)
                    
                    if seekInternalLeaf(
                        seek: seek,
                        start: position.nodeStart,
                        summary: leafSummary,
                        index: position.offset,
                        leaf: stackItem.node.elements[...]
                    ) {
                        return .found
                    }
                  
                    stackItem = stack.pop()
                } else {
                    stackItem.childIndex += 1
                    position.moveFoward(stackItem.node)
                }
            }
        }
        
        return .notFound
    }
    
    mutating func seekInternalDescending(contains: ContainsClosure, seek: SeekClosure) {
        var node = stack.pop().node
        
        while true {
            var nextNode: Node?
            
            if node.isInner {
                for (i, child) in node.children.enumerated() {
                    let childSummary = child.summary
                    if contains(position.nodeStart, childSummary) {
                        push(node: node, childIndex: i)
                        nextNode = child
                        break
                    } else {
                        position.moveFoward(child)
                    }
                }
            } else {
                let leafSummary = node.summary
                if contains(position.nodeStart, leafSummary) {
                    push(node: node, childIndex: 0)
                    assert(seekInternalLeaf(
                        seek: seek,
                        start: position.nodeStart,
                        summary: leafSummary,
                        index: 0,
                        leaf: node.elements[...]
                    ))
                    return
                } else {
                    position.moveFoward(node)
                }
            }
            
            if let nextNode = nextNode {
                node = nextNode
            } else {
                return
            }
        }
    }

    mutating func seekInternalLeaf(
        seek: SeekClosure,
        start: Summary,
        summary: Summary,
        index: Int,
        leaf: ArraySlice<Element>
    ) -> Bool {
        if let found = seek(start, summary, index, leaf) {
            position.offset = found
            
            if found == leaf.count {
                let end = position.nodeStart.count + position.offset
                if end < root.count {
                    _ = nextLeaf()!
                }
            }
            return true
        } else {
            return false
        }
    }
    
    // MARK: Util
    
    public var isSeeking: Bool {
        !stack.isEmpty
    }
    
    public var isBeforeStart: Bool {
        !isSeeking && !atEnd
    }

    public var isAtStart: Bool {
        isSeeking && index == 0 && !atEnd
    }

    public var isAtEnd: Bool {
        isSeeking && index == root.count && atEnd
    }

    public var isAfterEnd: Bool {
        !isSeeking && index == root.count && atEnd
    }
    
    public mutating func reset() {
        stack.removeAll()
        position = .init()
        atEnd = false
    }

    public mutating func resetToEnd() {
        reset()
        descendToLastLeaf(root)
        position.offset = leafSummary().count
        atEnd = true
    }

    public mutating func resetToStart() {
        reset()
        descendToFirstLeaf(root)
        atEnd = root.isEmpty
    }

    mutating func push(node: Node, childIndex: Int) {
        stack.append(.init(node: node, childIndex: childIndex))
    }

    public func ensureValid(for root: Node, version: Int) {
        precondition(self.root == root && self.version == version)
    }
    
    public func ensureValid(with cursor: Cursor) {
        precondition(root == cursor.root && version == cursor.version)
    }

}

extension SummarizedTree.Cursor: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.ensureValid(with: rhs)
        return lhs.index < rhs.index
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.ensureValid(with: rhs)
        return lhs.index == rhs.index
    }

}

extension SummarizedTree.Cursor.Stack {
    
    @usableFromInline
    typealias Cursor = SummarizedTree.Cursor
    
    @usableFromInline
    typealias StackItem = Cursor.StackItem
    
    init(repeating initialValue: StackItem, depth: Int8 = 0) {
        self.depth = depth
        self.values = (
            initialValue, initialValue, initialValue, initialValue,
            initialValue, initialValue, initialValue, initialValue
        )
    }
    
    var isEmpty: Bool { depth == 0 }

    mutating func append(_ value: __owned StackItem) {
        assert(depth < Self.capacity, "Out of bounds access in fixed sized array.")
        defer { self.depth &+= 1 }
        self[self.depth] = value
    }
    
    @inlinable
    mutating func pop() -> StackItem {
        assert(depth > 0, "Cannot pop empty fixed sized array")
        self.depth &-= 1
        return self[self.depth]
    }
     
    mutating func removeAll() {
        depth = 0
    }
    
    var last: StackItem {
        get {
            assert(depth > 0, "Out of bounds access in fixed sized array")
            return self[depth &- 1]
        }
        
        _modify {
            assert(depth > 0, "Out of bounds access in fixed sized array")
            yield &self[depth &- 1]
        }
    }
    
    @inlinable
    subscript(_ position: Int8) -> StackItem {
        get {
            assert(position <= depth && depth <= Self.capacity, "Out of bounds access in fixed sized array.")
            return withUnsafeBytes(of: values) { values in
                let p = values.baseAddress!.assumingMemoryBound(to: StackItem.self)
                return p.advanced(by: Int(position)).pointee
            }
        }
        
        _modify {
            assert(position <= depth && depth <= Self.capacity, "Out of bounds access in fixed sized array.")
            let ptr: UnsafeMutablePointer<StackItem> =
            withUnsafeMutableBytes(of: &self.values) { values in
                let p = values.baseAddress!.assumingMemoryBound(to: StackItem.self)
                return p.advanced(by: Int(position))
            }
            
            var value = ptr.move()
            defer { ptr.initialize(to: value) }
            yield &value
        }
    }
}

#if DEBUG
extension SummarizedTree.Cursor.Stack: CustomDebugStringConvertible {

    public var debugDescription: String {
        var result = "["
        
        for i in 0..<depth {
            if i != 0 {
                result += ", "
            }
            debugPrint(self[i], terminator: "", to: &result)
        }
        
        result += "]"
        return result
    }

}
#endif
