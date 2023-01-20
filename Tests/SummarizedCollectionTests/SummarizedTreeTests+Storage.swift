import XCTest
@testable import SummarizedCollection

import _CollectionsTestSupport

extension SummarizedTreeTests {

    /*
    func testStorageHandleBidirectionalCollection() {
        var rng = RepeatableRandomNumberGenerator(seed: 0)
        withEvery("count", in: [0, 1, 2, 13, 31, 32, 33]) { count in
            let reference = randomBoolArray(count: count, using: &rng)
            
            let storage = List<Int>.Node.Storage<Bool>.create(with: 64) { handle in
                handle.append(contentsOf: reference)
            }
            
            storage.rd { handle in
                checkBidirectionalCollection(handle, expectedContents: reference, maxSamples: 100)
            }
        }
    }

    func testStorageSubsequenceBidirectionalCollection() {
        var rng = RepeatableRandomNumberGenerator(seed: 0)
        withEvery("count", in: [0, 1, 2, 13, 31, 32, 33]) { count in
            let reference = randomBoolArray(count: count, using: &rng)
            
            let storage = List<Int>.Node.Storage<Bool>.create(with: 64) { handle in
                handle.append(contentsOf: reference)
            }

            checkBidirectionalCollection(storage.subSequence, expectedContents: reference, maxSamples: 100)
        }
    }*/

}
