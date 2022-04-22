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
            // TODO: Use another typealias or even concrete type for [IDCardAttribute: Bool]
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
    // TODO: Use another typealias or even concrete type for [IDCardAttribute: Bool]
    case requestAuthenticationRequestConfirmation(EIDAuthenticationRequest, ([IDCardAttribute: Bool]) -> Void)
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
    let readAttributes: [IDCardAttribute: Bool]
}

typealias EIDInteractionPublisher = AnyPublisher<EIDInteractionEvent, IDCardInteractionError>

// TODO: Use typealias for [IDCardAttribute: Bool]
extension Array where Element == NSObjectProtocol & SelectableItemProtocol {
    func mapToAttributeRequirements() throws -> [IDCardAttribute: Bool] {
        let keyValuePairs: [(IDCardAttribute, Bool)] = try map { item in
            guard let attribute = IDCardAttribute(rawValue: item.getName()) else {
                throw IDCardInteractionError.unexpectedReadAttribute(item.getName())
            }
            return (attribute, item.isRequired())
        }
        return [IDCardAttribute: Bool](uniqueKeysWithValues: keyValuePairs)
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

// TODO: Refactor as this is not safe. Value (Bool) might apply for 'requested' as well as for 'checked'
extension Dictionary where Key == IDCardAttribute, Value == Bool {
    var selectableItems: [NSObjectProtocol & SelectableItemProtocol] {
        map { SelectableItem(attribute: $0.key.rawValue, checked: $0.value) }
    }
}

class NFCManager {
    let openEcard = OpenEcardImp()!
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        IDCardTaskExecutor(task: .eac(tokenURL: tokenURL), openEcard: openEcard).eraseToAnyPublisher()
    }
    
    func changePIN() -> EIDInteractionPublisher {
        IDCardTaskExecutor(task: .pinManagement, openEcard: openEcard).eraseToAnyPublisher()
    }
    
    private class IDCardTaskExecutor: Publisher {
        typealias Output = EIDInteractionEvent
        typealias Failure = IDCardInteractionError
        
        private let task: IDTask
        private let openEcard: OpenEcardProtocol
        private var context: ContextManagerProtocol? = nil
        
        init(task: IDTask, openEcard: OpenEcardProtocol) {
            self.task = task
            self.openEcard = openEcard
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
            
            context = openEcard.context(NFSMessageProvider())!
            context?.initializeContext(StartServiceHandler(task: task, subscriber: subscriber))
        }
        
        // TODO: Terminate context on success or failure
    }
}

// TODO: Eliminate generic constraints
// TODO: Simplify initialization (inheritance?)
class StartServiceHandler<S>: NSObject, StartServiceHandlerProtocol where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    
    private let task: IDTask
    private let subscriber: S
    private var activationController: ActivationControllerProtocol? = nil
    
    init(task: IDTask, subscriber: S) {
        self.task = task
        self.subscriber = subscriber
    }
    
    func onSuccess(_ source: (NSObjectProtocol & ActivationSourceProtocol)!) {
        let controllerCallback = ControllerCallback(subscriber: subscriber)
        switch task {
        case .eac(let tokenURL): activationController = source.eacFactory().create(tokenURL, withActivation: controllerCallback, with: EACInteraction(subscriber: subscriber))
        case .pinManagement: activationController = source.pinManagementFactory().create(controllerCallback, with: PinManagementInteraction(subscriber: subscriber))
        }
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        print("Failure: \(response.errorDescription)")
        subscriber.receive(completion: .failure(IDCardInteractionError.frameworkError(message: response.errorDescription)))
    }
}

class ControllerCallback<S>: NSObject, ControllerCallbackProtocol where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    private let subscriber: S
    
    init(subscriber: S) {
        self.subscriber = subscriber
    }
    
    func onStarted() {
        print("Started process.")
        _ = subscriber.receive(.authenticationStarted)
    }
    
    func onAuthenticationCompletion(_ result: (NSObjectProtocol & ActivationResultProtocol)!) {
        print("Process completed.")
        
        switch result.getCode() {
        case .OK, .REDIRECT:
            _ = subscriber.receive(.processCompletedSuccessfully)
            subscriber.receive(completion: .finished)
        default:
            subscriber.receive(completion: .failure(.processFailed(resultCode: result.getCode())))
        }
    }
}

class EACInteraction<S>: NSObject, EacInteractionProtocol where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    private let subscriber: S
    
    init(subscriber: S) {
        self.subscriber = subscriber
    }
    
    func onCanRequest(_ enterCan: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        print("Requesting CAN.")
        _ = subscriber.receive(.requestCAN(enterCan.confirmPassword))
    }
    
    func onPinRequest(_ enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        print("Requesting PIN without attempts.")
        onGeneralPINRequest(attempts: nil, enterPin: enterPin)
    }
    
    func onPinRequest(_ attempt: Int32, withEnterPin enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        print("Requesting PIN with attempts.")
        onGeneralPINRequest(attempts: Int(attempt), enterPin: enterPin)
    }
    
    private func onGeneralPINRequest(attempts: Int?, enterPin: ConfirmPasswordOperationProtocol) {
        _ = subscriber.receive(.requestPIN(attempts: attempts, pinCallback: enterPin.confirmPassword))
    }
    
    func onPinCanRequest(_ enterPinCan: (NSObjectProtocol & ConfirmPinCanOperationProtocol)!) {
        print("Requesting PIN and CAN.")
        _ = subscriber.receive(.requestPINAndCAN(enterPinCan.confirmPassword))
    }
    
    func onCardBlocked() {
        print("Card blocked.")
        subscriber.receive(completion: .failure(.cardBlocked))
    }
    
    func onCardDeactivated() {
        print("Card deactivated.")
        subscriber.receive(completion: .failure(.cardDeactivated))
    }
    
    func onServerData(_ data: (NSObjectProtocol & ServerDataProtocol)!, withTransactionData transactionData: String!, withSelectReadWrite selectReadWrite: (NSObjectProtocol & ConfirmAttributeSelectionOperationProtocol)!) {
        print("Requesting to confirm server data.")
        
        let readAttributes: [IDCardAttribute: Bool]
        do {
            readAttributes = try data.getReadAccessAttributes()!.mapToAttributeRequirements()
        } catch IDCardInteractionError.unexpectedReadAttribute(let attribute) {
            subscriber.receive(completion: .failure(IDCardInteractionError.unexpectedReadAttribute(attribute)))
            return
        } catch {
            subscriber.receive(completion: .failure(.frameworkError(message: nil)))
            return
        }
        
        let eidServerData = EIDAuthenticationRequest(issuer: data.getIssuer(), issuerURL: data.getIssuerUrl(), subject: data.getSubject(), subjectURL: data.getSubjectUrl(), validity: data.getValidity(), terms: .text(data.getTermsOfUsage().getDataString()), readAttributes: readAttributes)
        
        let confirmationCallback: ([IDCardAttribute: Bool]) -> Void = { selectReadWrite.enterAttributeSelection($0.selectableItems, withWrite: []) }
        
        _ = subscriber.receive(.requestAuthenticationRequestConfirmation(eidServerData, confirmationCallback))
    }
    
    func onCardAuthenticationSuccessful() {
        print("Card authentication successful.")
        _ = subscriber.receive(.authenticationSuccessful)
    }
    
    func requestCardInsertion() {
        print("Requesting card insertion without overlay message handler not implemented.")
        subscriber.receive(completion: .failure(.frameworkError(message: nil)))
    }
    
    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
        print("Requesting card insertion with overlay message handler.")
        _ = subscriber.receive(.requestCardInsertion(msgHandler.setText))
    }
    
    func onCardInteractionComplete() {
        print("Card interaction complete.")
        _ = subscriber.receive(.cardInteractionComplete)
    }
    
    func onCardRecognized() {
        print("Card recognized.")
        _ = subscriber.receive(.cardRecognized)
    }
    
    func onCardRemoved() {
        print("Card removed")
        _ = subscriber.receive(.cardRemoved)
    }
}

class PinManagementInteraction<S>: NSObject, PinManagementInteractionProtocol where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    private let subscriber: S
    
    init(subscriber: S) {
        self.subscriber = subscriber
    }
    
    func onPinChangeable(_ enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        print("Request old and new PIN without attempts.")
        onGeneralPINChangeable(attempts: nil, enterOldAndNewPIN: enterOldNewPins)
    }
    
    func onPinChangeable(_ attempts: Int32, withEnterOldNewPins enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        print("Request old and new PIN with \(attempts) attempts.")
        onGeneralPINChangeable(attempts: Int(attempts), enterOldAndNewPIN: enterOldNewPins)
    }
    
    private func onGeneralPINChangeable(attempts: Int?, enterOldAndNewPIN: ConfirmOldSetNewPasswordOperationProtocol) {
        _ = subscriber.receive(.requestChangedPIN(attempts: attempts, pinCallback: enterOldAndNewPIN.confirmPassword))
    }
    
    func onPinCanNewPinRequired(_ enterPinCanNewPin: (NSObjectProtocol & ConfirmPinCanNewPinOperationProtocol)!) {
        print("Request CAN and old and new PIN.")
        _ = subscriber.receive(.requestCANAndChangedPIN(pinCallback: enterPinCanNewPin.confirmChangePassword))
    }
    
    func onPinBlocked(_ unblockWithPuk: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        print("Request PUK.")
        _ = subscriber.receive(.requestPUK(unblockWithPuk.confirmPassword))
    }
    
    func onCardPukBlocked() {
        print("Card blocked.")
        subscriber.receive(completion: .failure(.cardBlocked))
    }
    
    func onCardDeactivated() {
        print("Card deactivated.")
        subscriber.receive(completion: .failure(.cardDeactivated))
    }
    
    func requestCardInsertion() {
        print("Requesting card insertion without overlay message handler not implemented.")
        subscriber.receive(completion: .failure(.frameworkError(message: nil)))
    }
    
    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
        print("Requesting card insertion with overlay message handler.")
        _ = subscriber.receive(.requestCardInsertion(msgHandler.setText))
    }
    
    func onCardInteractionComplete() {
        print("Card interaction complete.")
        _ = subscriber.receive(.cardInteractionComplete)
    }
    
    func onCardRecognized() {
        print("Card recognized.")
        _ = subscriber.receive(.cardRecognized)
    }
    
    func onCardRemoved() {
        print("Card removed")
        _ = subscriber.receive(.cardRemoved)
    }
}
