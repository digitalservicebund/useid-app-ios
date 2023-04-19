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
    
    func testReceiveRequestConfirmationRetrievesCertificateDescription() {
        let request = AuthenticationRequest.preview
        let handler: (FlaggedAttributes) -> Void = { attributes in }
        let store = TestStore(initialState: IdentificationOverviewLoading.State(), reducer: IdentificationOverviewLoading())
        
        let mockIDInteractionManager = MockIDInteractionManagerType()
        stub(mockIDInteractionManager) {
            $0.retrieveCertificateDescription().thenDoNothing()
        }
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.send(.idInteractionEvent(.success(.authenticationRequestConfirmationRequested(request)))) {
            $0.authenticationRequest = request
        }
        
        verify(mockIDInteractionManager).retrieveCertificateDescription()
    }
    
    func testReceiveCertificateCallsDone() {
        let request = AuthenticationRequest.preview
        let handler: (FlaggedAttributes) -> Void = { attributes in }
        let store = TestStore(initialState: IdentificationOverviewLoading.State(authenticationRequest: .preview), reducer: IdentificationOverviewLoading())
        
        let certificateDescription = CertificateDescription.preview
        store.send(.idInteractionEvent(.success(.certificateDescriptionRetrieved(certificateDescription))))
        store.receive(.done(request, certificateDescription))
    }
}
