import Foundation
import Combine
import OSLog

#if !targetEnvironment(simulator)
import AusweisApp2SDKWrapper

final class IDInteractionEventHandler: WorkflowCallbacks {
    
    let subject: PassthroughSubject<EIDInteractionEvent, EIDInteractionError>

    private let workflow: Workflow
    private let workflowController: AusweisApp2SDKWrapper.WorkflowController
    private let logger: Logger

    init(workflow: Workflow, workflowController: AusweisApp2SDKWrapper.WorkflowController) {
        self.workflow = workflow
        self.workflowController = workflowController
        logger = Logger(category: String(describing: Self.self))
        subject = PassthroughSubject<EIDInteractionEvent, EIDInteractionError>()
    }

    func onStarted() {
        switch workflow {
        case .changePIN(userInfoMessages: let userInfoMessages, status: let status):
            workflowController.startChangePin(withUserInfoMessages: userInfoMessages,
                                              withStatusMsgEnabled: status)
        case .authentification(tcTokenUrl: let tcTokenUrl,
                               developerMode: let developerMode,
                               userInfoMessages: let userInfoMessages,
                               status: let status):
            workflowController.startAuthentication(
                withTcTokenUrl: tcTokenUrl,
                withDeveloperMode: developerMode,
                withUserInfoMessages: userInfoMessages,
                withStatusMsgEnabled: status
            )
        }
    }

    func onChangePinStarted() {
        subject.send(.pinChangeStarted)
    }

    func onAuthenticationStarted() {
        subject.send(.authenticationStarted)
    }

    func onAuthenticationStartFailed(error: String) {
        subject.send(completion: .failure(.frameworkError(message: "onAuthenticationStartFailed: \(error)")))
    }

    func onAccessRights(error: String?, accessRights: AccessRights?) {
        if let error {
            logger.error("onAccessRights error: \(error)")
        }

        guard let accessRights else {
            // TODO: Check when this happens
            logger.error("onAccessRights: Access rights missing.")
            subject.send(completion: .failure(.frameworkError(message: "Access rights missing. Error: \(String(describing: error))")))
            return
        }

        guard accessRights.requiredRights == accessRights.effectiveRights else {
            workflowController.setAccessRights([])
            return
        }

        do {
            let requiredRights = try accessRights.requiredRights.map(EIDAttribute.init)
            let request = AuthenticationRequest(requiredAttributes: requiredRights, transactionInfo: accessRights.transactionInfo)
            subject.send(.authenticationRequestConfirmationRequested(request))
        } catch EIDInteractionError.unexpectedReadAttribute(let attribute) {
            subject.send(completion: .failure(.unexpectedReadAttribute(attribute)))
            return
        } catch {
            subject.send(completion: .failure(.frameworkError(message: nil)))
            return
        }
    }

    func onApiLevel(error: String?, apiLevel: ApiLevel?) {
        logger.warning("onApiLevel: \(String(describing: error)), \(String(describing: apiLevel))")
    }

    func onInsertCard(error: String?) {
        if let error {
            // TODO: Remove duplicated method names from logger
            logger.error("onInsertCard: \(String(describing: error))")
        }
        subject.send(.cardInsertionRequested)
    }

    func onAuthenticationCompleted(authResult: AusweisApp2SDKWrapper.AuthResult) {
        if let resultData = authResult.result,
           let refreshURLOrCommunicationErrorAddress = authResult.url,
           let refreshURLOrCommunicationErrorAddressComponents = URLComponents(url: refreshURLOrCommunicationErrorAddress,
                                                                               resolvingAgainstBaseURL: false),
           let resultMajorSuffix = resultData.major.split(separator: "#").last {
            let resultMajor = String(resultMajorSuffix)
            var queryItems = refreshURLOrCommunicationErrorAddressComponents.queryItems ?? []
            queryItems.append(URLQueryItem(name: "ResultMajor", value: resultMajor))
            if resultMajor == "ok" {
                var refreshURLComponents = refreshURLOrCommunicationErrorAddressComponents
                refreshURLComponents.queryItems = queryItems
                subject.send(.authenticationSucceeded(redirectURL: refreshURLComponents.url))
                subject.send(completion: .finished)
            } else {
                var resultMinor: String? = nil
                if let resultMinorSuffix = resultData.minor?.split(separator: "#").last {
                    resultMinor = String(resultMinorSuffix)
                    queryItems.append(URLQueryItem(name: "ResultMinor", value: resultMinor))
                }
                if resultMinor == "trustedChannelEstablishmentFailed", let resultMessage = resultData.reason {
                    queryItems.append(URLQueryItem(name: "ResultMessage", value: resultMessage))
                }
                var errorAddressComponents = refreshURLOrCommunicationErrorAddressComponents
                errorAddressComponents.queryItems = queryItems
                subject.send(completion: .failure(.authenticationFailed(resultMajor: resultMajor,
                                                                        resultMinor: resultMinor,
                                                                        refreshURL: errorAddressComponents.url)))
            }
        } else {
            subject.send(completion: .failure(.authenticationBadRequest))
        }
    }

    func onChangePinCompleted(changePinResult: AusweisApp2SDKWrapper.ChangePinResult?) {
        if changePinResult?.success == true {
            subject.send(.pinChangeSucceeded)
            subject.send(completion: .finished)
        } else {
            subject.send(completion: .failure(.pinChangeFailed))
        }
    }

    func onWrapperError(error: AusweisApp2SDKWrapper.WrapperError) {
        subject.send(completion: .failure(.frameworkError(message: "onWrapperError: \(error.msg) - \(error.error)")))
    }

    func onBadState(error: String) {
        // TODO: issueTracker instead
        subject.send(completion: .failure(.frameworkError(message: "onBadState: \(error)")))
    }

    func onCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
        subject.send(.certificateDescriptionRetrieved(.init(certificateDescription)))
    }

    func onEnterCan(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterCan error: \(error)")
        }
        subject.send(.canRequested)
    }

    func onEnterNewPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterNewPin error: \(error)")
        }
        subject.send(.newPINRequested)
    }

    func onEnterPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterPin error: \(error)")
        }
        subject.send(.pinRequested(remainingAttempts: reader.card?.pinRetryCounter))
    }

    func onEnterPuk(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterPuk error: \(error)")
        }
        subject.send(.pukRequested)
    }

    func onInfo(versionInfo: AusweisApp2SDKWrapper.VersionInfo) {
        logger.info("onInfo: \(String(describing: versionInfo))")
    }

    func onInternalError(error: String) {
        subject.send(completion: .failure(.frameworkError(message: "onInternalError error: \(error)")))
    }

    func onReader(reader: AusweisApp2SDKWrapper.Reader?) {
        guard let reader else {
            logger.error("onReader: Unknown reader")
            // reader is nil when authentication is done
            // subject.send(completion: .failure(.unknownReader))
            return
        }

        // TODO: Decide about cardRemoved being sent for initial state (before cardRecognized)
        if let card = reader.card {
            // TODO: What do we do when the card is deactivated (meaning the online ausweisfunktion is not activated)
            // Is this event the only info about that? How to tell the application?
            if card.deactivated {
                subject.send(completion: .failure(.cardDeactivated))
            } else {
                subject.send(.cardRecognized)
            }
        } else {
            subject.send(.cardRemoved)
        }
    }

    func onReaderList(readers: [AusweisApp2SDKWrapper.Reader]?) {
        logger.info("onReaderList: \(String(describing: readers))")
    }

    func onStatus(workflowProgress: AusweisApp2SDKWrapper.WorkflowProgress) {
        logger.info("onStatus: \(String(describing: workflowProgress))")
    }
}

extension CertificateDescription {
    init(_ description: AusweisApp2SDKWrapper.CertificateDescription) {
        issuerName = description.issuerName
        issuerUrl = description.issuerUrl
        purpose = description.purpose
        subjectName = description.subjectName
        subjectUrl = description.subjectUrl
        termsOfUsage = description.termsOfUsage
        effectiveDate = description.validity.effectiveDate
        expirationDate = description.validity.expirationDate
    }
}

extension EIDAttribute {
    init(_ accessRight: AccessRight) throws {
        switch accessRight {
        case .Address: self = .address
        case .BirthName: self = .birthName
        case .FamilyName: self = .familyName
        case .GivenNames: self = .givenNames
        case .PlaceOfBirth: self = .placeOfBirth
        case .DateOfBirth: self = .dateOfBirth
        case .DoctoralDegree: self = .doctoralDegree
        case .ArtisticName: self = .artisticName
        case .Pseudonym: self = .pseudonym
        case .ValidUntil: self = .validUntil
        case .Nationality: self = .nationality
        case .IssuingCountry: self = .issuingCountry
        case .DocumentType: self = .documentType
        case .ResidencePermitI: self = .residencePermitI
        case .ResidencePermitII: self = .residencePermitII
        case .CommunityID: self = .communityID
        case .AddressVerification: self = .addressVerification
        case .AgeVerification: self = .ageVerification
        case .WriteAddress: self = .writeAddress
        case .WriteCommunityID: self = .writeCommunityID
        case .WriteResidencePermitI: self = .writeResidencePermitI
        case .WriteResidencePermitII: self = .writeResidencePermitII
        case .CanAllowed: self = .canAllowed
        case .PinManagement: self = .pinManagement
        @unknown default: throw EIDInteractionError.unexpectedReadAttribute(accessRight.rawValue)
        }
    }
}

extension AusweisApp2SDKWrapper.AuxiliaryData: Equatable {
    public static func == (lhs: AuxiliaryData, rhs: AuxiliaryData) -> Bool {
        lhs.ageVerificationDate == rhs.ageVerificationDate &&
            lhs.communityId == rhs.communityId &&
            lhs.requiredAge == rhs.requiredAge &&
            lhs.validityDate == rhs.validityDate
    }
}

extension AusweisApp2SDKWrapper.AccessRights: Equatable {
    public static func == (lhs: AusweisApp2SDKWrapper.AccessRights, rhs: AusweisApp2SDKWrapper.AccessRights) -> Bool {
        lhs.effectiveRights == rhs.effectiveRights &&
            lhs.requiredRights == rhs.requiredRights &&
            lhs.optionalRights == rhs.optionalRights &&
            lhs.transactionInfo == rhs.transactionInfo &&
            lhs.auxiliaryData == rhs.auxiliaryData
    }
}

#endif
