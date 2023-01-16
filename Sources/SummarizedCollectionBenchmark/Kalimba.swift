extension Sequence {
    func kalimbaOrdered() -> [Element] {
        var kalimba: [Element] = []
        kalimba.reserveCapacity(underestimatedCount)
        var insertAtStart = false
        for element in self {
            if insertAtStart {
                kalimba.insert(element, at: 0)
            } else {
                kalimba.append(element)
            }
            insertAtStart.toggle()
        }
        return kalimba
    }
    
    func kalimbaOrdered3() -> [Element] {
        var odds: [Element] = []
        var evens: [Element] = []
        odds.reserveCapacity(underestimatedCount)
        evens.reserveCapacity(underestimatedCount / 2)
        var insertAtStart = false
        for element in self {
            if insertAtStart {
                odds.append(element)
            } else {
                evens.append(element)
            }
            insertAtStart.toggle()
        }
        odds.reverse()
        odds.append(contentsOf: evens)
        return odds
    }
    
}
