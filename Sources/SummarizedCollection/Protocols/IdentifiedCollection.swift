public protocol IdentifiedCollection: Collection where Element: Identifiable {
    
    typealias ID = Element.ID
    
    func index(id: ID) -> Index?
    
}

extension IdentifiedCollection {

    public func index(id: ID) -> Index? {
        for (i, each) in enumerated() {
            if each.id == id {
                return index(startIndex, offsetBy: i)
            }
        }
        return nil
    }

}
