import Analytics
import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators

@testable import BundesIdent

final class IdentificationOverviewTests: XCTestCase {
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    var mockIDInteractionManager: MockIDInteractionManagerType!
    
    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        mockIDInteractionManager = MockIDInteractionManagerType()
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }

    func testLoadingFailure() {
        let error = IdentifiableError(NSError(domain: "", code: 0))
        let store = TestStore(
            initialState: IdentificationOverview.State.loading(.init()),
            reducer: IdentificationOverview()
        )
        store.dependencies.analytics = mockAnalyticsClient
        store.send(IdentificationOverview.Action.loading(.failure(error))) {
            $0 = .error(IdentificationOverviewErrorState(error: error))
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "loadingFailed",
                                                                name: "attributes"))
    }
    
    func testLoadingSuccess() {
        let store = TestStore(
            initialState: IdentificationOverview.State.loading(.init()),
            reducer: IdentificationOverview()
        )
        store.dependencies.uuid = .incrementing
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        let request = AuthenticationRequest.preview
        let certificateDescription = CertificateDescription.preview
        
        stub(mockIDInteractionManager) {
            $0.retrieveCertificateDescription().thenDoNothing()
        }
        
        store.send(IdentificationOverview.Action.loading(.idInteractionEvent(.success(.authenticationRequestConfirmationRequested(request))))) {
            guard case .loading(var loadingState) = $0 else { return XCTFail("Invalid state") }
            loadingState.authenticationRequest = request
            $0 = .loading(loadingState)
        }
        
        verify(mockIDInteractionManager).retrieveCertificateDescription()
        
        store.send(.loading(.idInteractionEvent(.success(.certificateDescriptionRetrieved(certificateDescription)))))
        
        store.receive(.loading(.done(request, certificateDescription))) {
            $0 = .loaded(.init(id: UUID(number: 0),
                               authenticationInformation: AuthenticationInformation(request: request, certificateDescription: certificateDescription)))
        }
    }
    
    func testLoadedConfirm() {
        let authenticationInformation = AuthenticationInformation.preview
        
        let loadedState = IdentificationOverviewLoaded.State(id: UUID(number: 0), authenticationInformation: authenticationInformation)
        let store = TestStore(
            initialState: IdentificationOverview.State.loaded(loadedState),
            reducer: IdentificationOverview()
        )
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.send(IdentificationOverview.Action.loaded(.confirm(authenticationInformation)))
        
        // mockIDInteractionManager.acceptAccessRights() is called later
    }
    
    func testCallingPINHandlerWhenConfirming() {
        let authenticationInformation = AuthenticationInformation.preview
        
        let callback: (FlaggedAttributes) -> Void = { attributes in
            XCTFail("Should not be called")
        }
        
        let identifiableCallback = IdentifiableCallback(id: UUID(number: 0), callback: callback)
        
        let pinCallback: (String) -> Void = { _ in }
        let identifiablePINCallback = PINCallback(id: UUID(number: 0), callback: pinCallback)
        
        let loadedState = IdentificationOverviewLoaded.State(
            id: UUID(number: 0),
            authenticationInformation: authenticationInformation
        )
        let store = TestStore(
            initialState: IdentificationOverview.State.loaded(loadedState),
            reducer: IdentificationOverview()
        )
        
        store.send(IdentificationOverview.Action.loaded(.confirm(authenticationInformation)))
        
        // TODO: Receive call on stub
    }
}
