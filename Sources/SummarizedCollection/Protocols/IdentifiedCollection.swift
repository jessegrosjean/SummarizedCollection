public protocol IdentifiedCollection: Collection where Element: Identifiable {
    
    typealias ID = Element.ID
    
    func offset(id: ID) -> Int?
    
}

extension IdentifiedCollection {

    @inlinable
    public func offset(id: ID) -> Int? {
        for (i, each) in enumerated() {
            if each.id == id {
                return i
            }
        }
        return nil
    }

}
