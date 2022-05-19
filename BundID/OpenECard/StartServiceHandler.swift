import Foundation
import Combine
import OpenEcard

class StartServiceHandler<S>: OpenECardHandlerBase<S>, StartServiceHandlerProtocol where S: Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    
    private let task: IDTask
    private var activationController: ActivationControllerProtocol?
    
    init(task: IDTask, delegate: OpenECardHandlerDelegate<S>) {
        self.task = task
        super.init(delegate: delegate)
    }
    
    func onSuccess(_ source: (NSObjectProtocol & ActivationSourceProtocol)!) {
        let controllerCallback = ControllerCallback(delegate: delegate)
        switch task {
        case .eac(let tokenURL): activationController = source.eacFactory().create(tokenURL, withActivation: controllerCallback, with: EACInteraction(delegate: delegate))
        case .pinManagement: activationController = source.pinManagementFactory().create(controllerCallback, with: PINManagementInteraction(delegate: delegate))
        }
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        print("Failure: \(response.errorDescription)")
        delegate.fail(error: IDCardInteractionError.frameworkError(message: response.errorDescription))
        activationController?.cancelOngoingAuthentication()
    }
}
