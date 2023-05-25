import XCTest
import ComposableArchitecture
import Cuckoo

@testable import BundesIdent

class SetupDoneTests: XCTestCase {
    
    func testOpenMissingPINLetterEvent() {
        let mockReviewController = MockReviewControllerType()
        
        stub(mockReviewController) {
            $0.requestReview().thenDoNothing()
        }
        
        let store = TestStore(
            initialState: SetupDone.State(),
            reducer: SetupDone()
        )
        store.dependencies.reviewController = mockReviewController
        store.send(.onInitialAppear)
        
        verify(mockReviewController).requestReview()
    }
}
