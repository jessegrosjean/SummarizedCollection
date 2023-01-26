@testable import SummarizedCollection

struct Row: Identifiable, Equatable {
    
    let id: Int
    var line: String
    var height: Int
    
    var charCount: Int {
        line.count
    }

    var utf16Count: Int {
        line.utf16.count
    }
    
    init(line: String, height: Int) {
        self.id = .random(in: 0..<Int.max)
        self.line = line
        self.height = height
    }
    
}

func createTestOutline(count: Int = 10) -> [Row] {
    (0..<count).map {
        .init(line: "00\($0)", height: 10)
    }
}

struct OutlineSummary: CollectionSummary {
    
    typealias Element = Row

    var count: Int
    var height: HeightDimension
    var charCount: CharDimension
    var utf16Count: UTF16Dimension

    static var zero: Self = .init(
        count: 0,
        height: .zero,
        charCount: .zero,
        utf16Count: .zero
    )
    
    static func summarize<C>(elements: C) -> Self where C : BidirectionalCollection, C.Element == Self.Element {
        .init(
            count: elements.count,
            height: HeightDimension.measure(elements),
            charCount: CharDimension.measure(elements),
            utf16Count: UTF16Dimension.measure(elements)
        )
    }
    
    static func + (lhs: Self, rhs: Self) -> Self {
        .init(
            count: lhs.count + rhs.count,
            height: lhs.height + rhs.height,
            charCount: lhs.charCount + rhs.charCount,
            utf16Count: lhs.utf16Count + rhs.utf16Count
        )
    }
    
    static func - (lhs: Self, rhs: Self) -> Self {
        .init(
            count: lhs.count - rhs.count,
            height: lhs.height - rhs.height,
            charCount: lhs.charCount - rhs.charCount,
            utf16Count: lhs.utf16Count - rhs.utf16Count
        )
    }
}

struct HeightDimension: CollectionDimension {
    
    typealias Summary = OutlineSummary
    typealias Element = Row

    static func get(_ summary: Summary) -> Self {
        summary.height
    }
    
    static func measure<C>(_ elements: C) -> Self
        where
            C : BidirectionalCollection, Element == C.Element
    {
        .init(elements.reduce(0) { $0 + $1.height })
    }

    var rawValue: Int
    
    init(_ rawValue: Int) {
        self.rawValue = rawValue
    }

}

struct CharDimension: CollectionDimension {
    
    typealias Summary = OutlineSummary
    typealias Element = Row

    static func get(_ summary: Summary) -> Self {
        summary.charCount
    }

    static func measure<C>(_ elements: C) -> Self
        where
            C : BidirectionalCollection, Element == C.Element
    {
        .init(elements.reduce(0) { $0 + $1.charCount })
    }

    var rawValue: Int
    
    init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

struct UTF16Dimension: CollectionDimension {
    
    typealias Summary = OutlineSummary
    typealias Element = Row

    static func get(_ summary: Summary) -> Self {
        summary.utf16Count
    }

    static func measure<C>(_ elements: C) -> Self
        where
            C : BidirectionalCollection, Element == C.Element
    {
        .init(elements.reduce(0) { $0 + $1.utf16Count })
    }

    var rawValue: Int
    
    init(_ rawValue: Int) {
        self.rawValue = rawValue
    }

}
