import Foundation
import Combine
import OpenEcard
import CombineSchedulers

typealias NFCConfigType = NSObjectProtocol & NFCConfigProtocol

extension OpenEcardImp: OpenEcardType {}

class IDInteractionManager: IDInteractionManagerType {
    
    private let openEcard: OpenEcardProtocol
    private let context: ContextManagerProtocol
    
    init(openEcard: OpenEcardProtocol = OpenEcardImp(), nfcMessageProvider: NFCConfigType = NFCMessageProvider()) {
        self.openEcard = openEcard
        self.context = openEcard.context(nfcMessageProvider)
    }
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .eac(tokenURL: tokenURL)))
    }
    
    func changePIN() -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .pinManagement))
    }
    
    private func start(startServiceHandler: StartServiceHandler) -> EIDInteractionPublisher {
        context.initializeContext(startServiceHandler)
        return startServiceHandler.publisher
            .handleEvents(receiveCompletion: { [context] _ in
                startServiceHandler.cancel()
                context.terminateContext(StopServiceHandler())
            }, receiveCancel: { [context] in
                startServiceHandler.cancel()
                context.terminateContext(StopServiceHandler())
            }).eraseToAnyPublisher()
    }
}

#if targetEnvironment(simulator)
class DebugIDInteractionManager: IDInteractionManagerType {
    enum DebugSequence: Equatable {
        case runSuccessfully
        case runTransportPINError(remainingAttempts: Int)
        case runNFCError
        case runCardDeactivated
        case runCardBlocked
        case runUnexpectedEvent
    }
    
    private var subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>?
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.subject = subject
        return subject.delay(for: .seconds(1), scheduler: RunLoop.main).eraseToAnyPublisher()
    }
    
    func changePIN() -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.subject = subject
        return subject.delay(for: .seconds(1), scheduler: RunLoop.main).eraseToAnyPublisher()
    }
    
    func runDebugSequence(_ debugSequence: DebugSequence) {
        switch debugSequence {
        case .runSuccessfully:
            runSuccessfully()
        case .runTransportPINError(let remainingAttempts) where remainingAttempts == 2:
            runCardSuspended()
        case .runTransportPINError(let remainingAttempts):
            runTransportPINError(remainingAttempts: remainingAttempts)
        case .runNFCError:
            runNFCError()
        case .runCardDeactivated:
            runCardDeactivated()
        case .runCardBlocked:
            runCardBlocked()
        case .runUnexpectedEvent:
            runUnexpectedEvent()
        }
    }
    
    func runSuccessfully() {
        guard let subject = subject else { fatalError() }
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.requestChangedPIN(remainingAttempts: 3, pinCallback: { _, _ in }))
        subject.send(.cardRemoved)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.processCompletedSuccessfully)
        subject.send(completion: .finished)
    }
    
    func runTransportPINError(remainingAttempts: Int) {
        guard let subject = subject else { fatalError() }
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.requestChangedPIN(remainingAttempts: remainingAttempts, pinCallback: { _, _ in }))
        subject.send(.cardRemoved)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.requestChangedPIN(remainingAttempts: remainingAttempts - 1, pinCallback: { _, _ in }))
    }
    
    func runNFCError() {
        guard let subject = subject else { fatalError() }
        subject.send(.authenticationStarted)
        subject.send(completion: .failure(.processFailed(resultCode: .INTERNAL_ERROR)))
    }
    
    func runCardDeactivated() {
        guard let subject = subject else { fatalError() }
        subject.send(.authenticationStarted)
        subject.send(completion: .failure(.cardDeactivated))
    }
    
    func runCardSuspended() {
        guard let subject = subject else { fatalError() }
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.requestCANAndChangedPIN(pinCallback: { _, _, _ in }))
    }
    
    func runCardBlocked() {
        guard let subject = subject else { fatalError() }
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.requestPUK({ _ in }))
    }
    
    func runUnexpectedEvent() {
        guard let subject = subject else { fatalError() }
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.requestPINAndCAN({ _, _ in }))
    }
}
#endif
