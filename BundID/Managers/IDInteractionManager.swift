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

#if DEBUG
class DebugIDInteractionManager: IDInteractionManagerType {
    enum DebugSequence {
        case runSuccessfully
        case runTransportPINError
        case runNFCError
    }
    
    private let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
    
    var publisher: EIDInteractionPublisher {
        return subject.delay(for: .seconds(1), scheduler: RunLoop.main).eraseToAnyPublisher()
    }
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        return publisher
    }
    
    func changePIN() -> EIDInteractionPublisher {
        return publisher
    }
    
    func runDebugSequence(_ debugSequence: DebugSequence) {
        switch debugSequence {
        case .runSuccessfully:
            runSuccessfully()
        case .runTransportPINError:
            runTransportPINError()
        case .runNFCError:
            runNFCError()
        }
    }
    
    func runSuccessfully() {
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
    
    func runTransportPINError() {
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.requestChangedPIN(remainingAttempts: 3, pinCallback: { _, _ in }))
        subject.send(.cardRemoved)
        subject.send(.requestCardInsertion({ _ in }))
        subject.send(.cardRecognized)
        subject.send(.cardInteractionComplete)
        subject.send(.requestChangedPIN(remainingAttempts: 2, pinCallback: { _, _ in }))
    }
    
    func runNFCError() {
        subject.send(.authenticationStarted)
        subject.send(.requestChangedPIN(remainingAttempts: nil, pinCallback: { _, _ in }))
    }
}
#endif
