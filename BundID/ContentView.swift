//
//  ContentView.swift
//  BundID
//
//  Created by Fabio Tacke on 20.04.22.
//

import SwiftUI
import Combine
import OpenEcard

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewViewModel()
    
    var body: some View {
        Button("Identify") {
            viewModel.identify()
        }
        Button("Change PIN") {
            viewModel.changePIN()
        }
    }
}

class ContentViewViewModel: ObservableObject {
    let nfcManager = NFCManager()
    @Published var testValue = ""
    
    var cancellable: AnyCancellable? = nil
    
    func identify() {
        let tokenURL = "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%2FAutent-DemoApplication%2FRequestServlet%3Fprovider%3Ddemo_epa_20%26redirect%3Dtrue"
        
        cancellable = nfcManager.identify(tokenURL: tokenURL).sink { completion in
            switch completion {
            case .finished: print("Publisher finished.")
            case .failure(let error): print("Publisher failed with error: \(error)")
            }
        } receiveValue: { value in
            switch value {
            case .requestCardInsertion(let messageCallback):
                print("Request card insertion.")
                messageCallback("Request card insertion.")
            case .cardInteractionComplete: print("Card interaction complete.")
            case .cardRecognized: print("Card recognized.")
            case .cardRemoved: print("Card removed.")
            case .requestCAN(let canCallback): print("CAN callback not implemented.")
            case .requestPIN(let attempts, let pinCallback):
                print("Entering PIN with \(attempts ?? 3) remaining attempts.")
                pinCallback("123456")
            case .requestPINAndCAN(let pinCANCallback): print("PIN CAN callback not implemented.")
            case .requestPUK(let pukCallback): print("PUK callback not implemented.")
            case .processCompletedSuccessfully: print("Process completed successfully.")
            
            case .authenticationStarted: print("Authentication started.")
            case .requestAuthenticationRequestConfirmation(let request, let confirmationCallback):
                print("Confirm request.")
                confirmationCallback([:])
            case .authenticationSuccessful: print("Authentication successful.")
                
            default: print("Received unexpected event.")
            }
        }
    }
    
    func changePIN() {
        cancellable = nfcManager.changePIN().sink { completion in
            switch completion {
            case .finished: print("Publisher finished.")
            case .failure(let error): print("Publisher failed with error: \(error)")
            }
        } receiveValue: { value in
            switch value {
            case .requestCardInsertion(let messageCallback):
                print("Request card insertion.")
                messageCallback("Request card insertion.")
            case .cardInteractionComplete: print("Card interaction complete.")
            case .cardRecognized: print("Card recognized.")
            case .cardRemoved: print("Card removed.")
            case .requestCAN(let canCallback): print("CAN callback not implemented.")
            case .requestPIN(let attempts, let pinCallback):
                print("Entering PIN with \(attempts ?? 3) remaining attempts.")
                pinCallback("123456")
            case .requestPINAndCAN(let pinCANCallback): print("PIN CAN callback not implemented.")
            case .requestPUK(let pukCallback): print("PUK callback not implemented.")
            case .processCompletedSuccessfully: print("Process completed successfully.")
            
            case .pinManagementStarted: print("PIN Management started.")
            case .requestChangedPIN(let attempts, let pinCallback):
                print("Providing changed PIN with \(attempts ?? 3) attempts.")
                pinCallback("123456", "000000")
            case .requestCANAndChangedPIN(let pinCallback): print("Providing CAN and changed PIN not implemented.")
            default: print("Received unexpected event.")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

enum EIDInteractionEvent {
    case requestCardInsertion((String) -> Void)
    case cardInteractionComplete
    case cardRecognized
    case cardRemoved
    case requestCAN((String) -> Void)
    case requestPIN(attempts: Int?, pinCallback: (String) -> Void)
    case requestPINAndCAN((String, String) -> Void)
    case requestPUK((String) -> Void)
    case processCompletedSuccessfully
    
    case authenticationStarted
    case requestAuthenticationRequestConfirmation(EIDAuthenticationRequest, (FlaggedAttributes) -> Void)
    case authenticationSuccessful
    
    case pinManagementStarted
    case requestChangedPIN(attempts: Int?, pinCallback: (String, String) -> Void)
    case requestCANAndChangedPIN(pinCallback: (String, String, String) -> Void)
}

enum IDCardInteractionError: Error {
    case frameworkError(message: String?)
    case unexpectedReadAttribute(String)
    case cardBlocked
    case cardDeactivated
    case processFailed(resultCode: ActivationResultCode)
}

enum IDTask {
    case eac(tokenURL: String)
    case pinManagement
}

// TR-03110 (Part 4), Section 2.2.3
enum IDCardAttribute: String {
    case DG01
    case DG02
    case DG03
    case DG04
    case DG05
    case DG06
    case DG07
    case DG08
    case DG09
    case DG10
    case DG13
    case DG17
    case DG19
    case RESTRICTED_IDENTIFICATION
    case AGE_VERIFICATION
}

enum AuthenticationTerms {
    case text(String)
}

struct EIDAuthenticationRequest {
    let issuer: String
    let issuerURL: String
    let subject: String
    let subjectURL: String
    let validity: String
    let terms: AuthenticationTerms
    let readAttributes: FlaggedAttributes
}

typealias EIDInteractionPublisher = AnyPublisher<EIDInteractionEvent, IDCardInteractionError>

extension Array where Element == NSObjectProtocol & SelectableItemProtocol {
    func mapToAttributeRequirements() throws -> FlaggedAttributes {
        let keyValuePairs: [(IDCardAttribute, Bool)] = try map { item in
            guard let attribute = IDCardAttribute(rawValue: item.getName()) else {
                throw IDCardInteractionError.unexpectedReadAttribute(item.getName())
            }
            return (attribute, item.isRequired())
        }
        return FlaggedAttributes(uniqueKeysWithValues: keyValuePairs)
    }
}

class SelectableItem: NSObject, SelectableItemProtocol {
    private let attribute: String
    private let checked: Bool
    
    init(attribute: String, checked: Bool) {
        self.attribute = attribute
        self.checked = checked
    }
    
    func getName() -> String! { attribute }
    func getText() -> String! { "" }
    func isChecked() -> Bool { checked }
    func setChecked(_ checked: Bool) { }
    func isRequired() -> Bool { false }
}

typealias FlaggedAttributes = [IDCardAttribute: Bool]

extension Dictionary where Key == IDCardAttribute, Value == Bool {
    var selectableItemsSettingChecked: [NSObjectProtocol & SelectableItemProtocol] {
        map { SelectableItem(attribute: $0.key.rawValue, checked: $0.value) }
    }
}

class NFCManager {
    private let context: ContextManagerProtocol
    
    init() {
        let openEcard = OpenEcardImp()!
        context = openEcard.context(NFSMessageProvider())!
    }
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        IDCardTaskPublisher(task: .eac(tokenURL: tokenURL), context: context).eraseToAnyPublisher()
    }
    
    func changePIN() -> EIDInteractionPublisher {
        IDCardTaskPublisher(task: .pinManagement, context: context).eraseToAnyPublisher()
    }
    
    private struct IDCardTaskPublisher: Publisher {
        typealias Output = EIDInteractionEvent
        typealias Failure = IDCardInteractionError
        
        let task: IDTask
        let context: ContextManagerProtocol
        
        func receive<S>(subscriber: S) where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
            let delegate = OpenECardHandlerDelegate(subscriber: subscriber, context: context)
            context.initializeContext(StartServiceHandler(task: task, delegate: delegate))
        }
    }
}

class OpenECardHandlerDelegate<S>: NSObject where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    private let subscriber: S
    private let context: ContextManagerProtocol
    private var activationController: ActivationControllerProtocol?
    
    init(subscriber: S, context: ContextManagerProtocol) {
        self.subscriber = subscriber
        self.context = context
    }
    
    func send(event: EIDInteractionEvent) {
        _ = subscriber.receive(event)
    }
    
    func finish() {
        teardown()
        subscriber.receive(completion: .finished)
    }
    
    func fail(error: IDCardInteractionError) {
        teardown()
        subscriber.receive(completion: .failure(error))
    }
    
    private func teardown() {
        activationController?.cancelOngoingAuthentication()
        context.terminateContext(StopServiceHandler())
    }
}

class OpenECardHandlerBase<S>: NSObject where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    let delegate: OpenECardHandlerDelegate<S>
    
    init(delegate: OpenECardHandlerDelegate<S>) {
        self.delegate = delegate
    }
}

class StopServiceHandler: NSObject, StopServiceHandlerProtocol {
    func onSuccess() {
        print("Service stopped successfully.")
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        print("Failed to stop service.")
    }
}

class StartServiceHandler<S>: OpenECardHandlerBase<S>, StartServiceHandlerProtocol where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    
    private let task: IDTask
    private var activationController: ActivationControllerProtocol? = nil
    
    init(task: IDTask, delegate: OpenECardHandlerDelegate<S>) {
        self.task = task
        super.init(delegate: delegate)
    }
    
    func onSuccess(_ source: (NSObjectProtocol & ActivationSourceProtocol)!) {
        let controllerCallback = ControllerCallback(delegate: delegate)
        switch task {
        case .eac(let tokenURL): activationController = source.eacFactory().create(tokenURL, withActivation: controllerCallback, with: EACInteraction(delegate: delegate))
        case .pinManagement: activationController = source.pinManagementFactory().create(controllerCallback, with: PinManagementInteraction(delegate: delegate))
        }
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        print("Failure: \(response.errorDescription)")
        delegate.fail(error: IDCardInteractionError.frameworkError(message: response.errorDescription))
        activationController?.cancelOngoingAuthentication()
    }
}

class ControllerCallback<S>: OpenECardHandlerBase<S>, ControllerCallbackProtocol where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    func onStarted() {
        delegate.send(event: .authenticationStarted)
    }
    
    func onAuthenticationCompletion(_ result: (NSObjectProtocol & ActivationResultProtocol)!) {
        switch result.getCode() {
        case .OK, .REDIRECT:
            delegate.send(event: .processCompletedSuccessfully)
            delegate.finish()
        default:
            delegate.fail(error: .processFailed(resultCode: result.getCode()))
        }
    }
}

class EACInteraction<S>: OpenECardHandlerBase<S>, EacInteractionProtocol where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    func onCanRequest(_ enterCan: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        delegate.send(event: .requestCAN(enterCan.confirmPassword))
    }
    
    func onPinRequest(_ enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        onGeneralPINRequest(attempts: nil, enterPin: enterPin)
    }
    
    func onPinRequest(_ attempt: Int32, withEnterPin enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        onGeneralPINRequest(attempts: Int(attempt), enterPin: enterPin)
    }
    
    private func onGeneralPINRequest(attempts: Int?, enterPin: ConfirmPasswordOperationProtocol) {
        delegate.send(event: .requestPIN(attempts: attempts, pinCallback: enterPin.confirmPassword))
    }
    
    func onPinCanRequest(_ enterPinCan: (NSObjectProtocol & ConfirmPinCanOperationProtocol)!) {
        delegate.send(event: .requestPINAndCAN(enterPinCan.confirmPassword))
    }
    
    func onCardBlocked() {
        delegate.fail(error: .cardBlocked)
    }
    
    func onCardDeactivated() {
        delegate.fail(error: .cardDeactivated)
    }
    
    func onServerData(_ data: (NSObjectProtocol & ServerDataProtocol)!, withTransactionData transactionData: String!, withSelectReadWrite selectReadWrite: (NSObjectProtocol & ConfirmAttributeSelectionOperationProtocol)!) {
        let readAttributes: FlaggedAttributes
        do {
            readAttributes = try data.getReadAccessAttributes()!.mapToAttributeRequirements()
        } catch IDCardInteractionError.unexpectedReadAttribute(let attribute) {
            delegate.fail(error: IDCardInteractionError.unexpectedReadAttribute(attribute))
            return
        } catch {
            delegate.fail(error: .frameworkError(message: nil))
            return
        }
        
        let eidServerData = EIDAuthenticationRequest(issuer: data.getIssuer(), issuerURL: data.getIssuerUrl(), subject: data.getSubject(), subjectURL: data.getSubjectUrl(), validity: data.getValidity(), terms: .text(data.getTermsOfUsage().getDataString()), readAttributes: readAttributes)
        
        let confirmationCallback: (FlaggedAttributes) -> Void = { selectReadWrite.enterAttributeSelection($0.selectableItemsSettingChecked, withWrite: []) }
        
        delegate.send(event: .requestAuthenticationRequestConfirmation(eidServerData, confirmationCallback))
    }
    
    func onCardAuthenticationSuccessful() {
        delegate.send(event: .authenticationSuccessful)
    }
    
    func requestCardInsertion() {
        delegate.fail(error: .frameworkError(message: nil))
    }
    
    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
        delegate.send(event: .requestCardInsertion(msgHandler.setText))
    }
    
    func onCardInteractionComplete() {
        delegate.send(event: .cardInteractionComplete)
    }
    
    func onCardRecognized() {
        delegate.send(event: .cardRecognized)
    }
    
    func onCardRemoved() {
        delegate.send(event: .cardRemoved)
    }
}

class PinManagementInteraction<S>: OpenECardHandlerBase<S>, PinManagementInteractionProtocol where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    func onPinChangeable(_ enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        onGeneralPINChangeable(attempts: nil, enterOldAndNewPIN: enterOldNewPins)
    }
    
    func onPinChangeable(_ attempts: Int32, withEnterOldNewPins enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        onGeneralPINChangeable(attempts: Int(attempts), enterOldAndNewPIN: enterOldNewPins)
    }
    
    private func onGeneralPINChangeable(attempts: Int?, enterOldAndNewPIN: ConfirmOldSetNewPasswordOperationProtocol) {
        delegate.send(event: .requestChangedPIN(attempts: attempts, pinCallback: enterOldAndNewPIN.confirmPassword))
    }
    
    func onPinCanNewPinRequired(_ enterPinCanNewPin: (NSObjectProtocol & ConfirmPinCanNewPinOperationProtocol)!) {
        delegate.send(event: .requestCANAndChangedPIN(pinCallback: enterPinCanNewPin.confirmChangePassword))
    }
    
    func onPinBlocked(_ unblockWithPuk: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        delegate.send(event: .requestPUK(unblockWithPuk.confirmPassword))
    }
    
    func onCardPukBlocked() {
        delegate.fail(error: .cardBlocked)
    }
    
    func onCardDeactivated() {
        delegate.fail(error: .cardDeactivated)
    }
    
    func requestCardInsertion() {
        delegate.fail(error: .frameworkError(message: nil))
    }
    
    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
        delegate.send(event: .requestCardInsertion(msgHandler.setText))
    }
    
    func onCardInteractionComplete() {
        delegate.send(event: .cardInteractionComplete)
    }
    
    func onCardRecognized() {
        delegate.send(event: .cardRecognized)
    }
    
    func onCardRemoved() {
        delegate.send(event: .cardRemoved)
    }
}
