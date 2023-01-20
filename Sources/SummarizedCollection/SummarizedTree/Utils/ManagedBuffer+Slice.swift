import Foundation

extension ManagedBuffer {
    
    public struct Slice {
        
        public var count: Int

        @usableFromInline
        var buffer: ManagedBuffer
        
        @inlinable
        init(count: Int, buffer: ManagedBuffer) {
            self.count = count
            self.buffer = buffer
        }
    }
    
}

extension ManagedBuffer.Slice: Collection {
    
    public typealias Index = Int
    public typealias Element = Element

    public var startIndex: Index { return 0 }
    public var endIndex: Index { return count }

    @inlinable
    public func index(after i: Index) -> Index {
        i + 1
    }

    @inlinable
    public func index(before i: Index) -> Index {
        i - 1
    }
    
    @inlinable
    public func index(_ i: Index, offsetBy distance: Index) -> Index {
        i + distance
    }

    @inlinable
    public subscript(index: Index) -> Element {
        get {
            buffer.withUnsafeMutablePointerToElements { elementsPtr in
                elementsPtr.advanced(by: index).pointee
            }
        }
    }
    
}

extension ManagedBuffer.Slice: BidirectionalCollection {
}

extension ManagedBuffer.Slice: RandomAccessCollection {
}

extension ManagedBuffer.Slice: Sequence {
}

extension ManagedBuffer.Slice: ContiguousBytes {
    
    @inlinable
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try buffer.withUnsafeMutablePointerToElements { elementsPtr in
            try body(UnsafeRawBufferPointer(start: elementsPtr, count: count))
        }
    }
    
}

//#if DEBUG
extension ManagedBuffer.Slice: CustomDebugStringConvertible {

    public var debugDescription: String {
        var result = "<ManagedBufer.Slice>["
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
