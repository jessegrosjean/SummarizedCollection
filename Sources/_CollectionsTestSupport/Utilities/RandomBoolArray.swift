public func randomBoolArray<R: RandomNumberGenerator>(
  count: Int, using rng: inout R
) -> [Bool] {
    let wordCount = (count + UInt.bitWidth - 1) / UInt.bitWidth
    var array: [Bool] = []
    array.reserveCapacity(wordCount * UInt.bitWidth)
    for _ in 0 ..< wordCount {
        var word: UInt = rng.next()
        for _ in 0 ..< UInt.bitWidth {
            array.append(word & 1 == 1)
            word &>>= 1
        }
    }
    array.removeLast(array.count - count)
    return array
}
