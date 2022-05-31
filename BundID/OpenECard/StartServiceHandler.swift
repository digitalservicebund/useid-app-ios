import Foundation
import Combine
import OpenEcard

class StartServiceHandler: NSObject {
    
    private let task: IDTask
    
    private let controllerCallback: ControllerCallback = ControllerCallback()
    private let eacInteraction: EACInteraction = EACInteraction()
    private let pinManagementInteraction: PINManagementInteraction = PINManagementInteraction()
    
    private let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
    
    private var activationController: ActivationControllerProtocol?
    
    init(task: IDTask) {
        self.task = task
    }
    
    var publisher: EIDInteractionPublisher {
        subject
            .merge(with: controllerCallback.publisher)
            .merge(with: eacInteraction.publisher)
            .merge(with: pinManagementInteraction.publisher)
            .eraseToAnyPublisher()
    }
    
    func cancel() {
        activationController?.cancelOngoingAuthentication()
    }
}

extension StartServiceHandler: StartServiceHandlerProtocol {
    
    func onSuccess(_ source: (NSObjectProtocol & ActivationSourceProtocol)!) {
        switch task {
        case .eac(let tokenURL):
            activationController = source.eacFactory().create(tokenURL,
                                                              withActivation: controllerCallback,
                                                              with: eacInteraction)
        case .pinManagement:
            activationController = source.pinManagementFactory().create(controllerCallback,
                                                                        with: pinManagementInteraction)
        }
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        print("Failure: \(response.errorDescription)")
        activationController?.cancelOngoingAuthentication()
        subject.send(completion: .failure(.frameworkError(message: response.errorDescription)))
    }
    
}
