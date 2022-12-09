import Analytics
import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators

@testable import BundesIdent

final class IdentificationOverviewLoadingTests: XCTestCase {
    
    func testOnAppearCallsIdentifiy() {
        let store = TestStore(initialState: IdentificationOverviewLoading.State(), reducer: IdentificationOverviewLoading())
        store.send(.onAppear) {
            $0.onAppearCalled = true
        }
        store.receive(.identify)
    }
    
    func testOnAppearWhenAlreadyCallsIsIgnored() {
        let store = TestStore(initialState: IdentificationOverviewLoading.State(onAppearCalled: true), reducer: IdentificationOverviewLoading())
        store.send(.onAppear)
    }
    
    func testRecievedRequestConfirmationCallsDone() {
        let request = EIDAuthenticationRequest.preview
        let handler: (FlaggedAttributes) -> Void = { attributes in }
        let store = TestStore(initialState: IdentificationOverviewLoading.State(), reducer: IdentificationOverviewLoading())
        store.dependencies.uuid = .constant(.zero)
        store.send(.idInteractionEvent(.success(.requestAuthenticationRequestConfirmation(request, handler))))
        store.receive(.done(request, IdentifiableCallback(id: .zero, callback: handler)))
    }
}