import Foundation
import Combine
import OSLog

#if !targetEnvironment(simulator)
import AusweisApp2SDKWrapper

final class EIDInteractionFlowListener: WorkflowCallbacks {
    
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
        logger.info("[aa2] onChangePinStarted")
        subject.send(.pinChangeStarted)
    }

    func onAuthenticationStarted() {
        logger.info("[aa2] onAuthenticationStarted")
        subject.send(.identificationStarted)
    }

    func onAuthenticationStartFailed(error: String) {
        logger.error("[aa2] onAuthenticationStartFailed error: \(error)")
        subject.send(completion: .failure(.frameworkError(error)))
    }

    func onAccessRights(error: String?, accessRights: AccessRights?) {
        if let error {
            logger.error("[aa2] onAccessRights error: \(error)")
        }

        guard let accessRights else {
            logger.error("[aa2] onAccessRights: access rights missing")
            subject.send(completion: .failure(.frameworkError(error, message: "Access rights missing")))
            return
        }

        guard accessRights.requiredRights == accessRights.effectiveRights else {
            workflowController.setAccessRights([])
            return
        }

        do {
            let requiredAttributes = try accessRights.requiredRights.map(EIDAttribute.init)
            let request = IdentificationRequest(requiredAttributes: requiredAttributes, transactionInfo: accessRights.transactionInfo)
            logger.info("[aa2] onAccessRights")
            subject.send(.identificationRequestConfirmationRequested(request))
        } catch EIDInteractionError.unexpectedReadAttribute(let attribute) {
            logger.error("[aa2] onAccessRights: unexpected attribute")
            subject.send(completion: .failure(.unexpectedReadAttribute(attribute)))
            return
        } catch {
            logger.error("[aa2] onAccessRights: failed to map attributes")
            subject.send(completion: .failure(.frameworkError(String(describing: error), message: "Failed to map EIDAttribute")))
            return
        }
    }

    func onApiLevel(error: String?, apiLevel: ApiLevel?) {
        logger.warning("[aa2] onApiLevel error: \(String(describing: error)), apiLevel: \(String(describing: apiLevel))")
    }

    func onInsertCard(error: String?) {
        if let error {
            logger.error("[aa2] onInsertCard error: \(error)")
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
                logger.info("[aa2] onAuthenticationCompleted: success")
                var refreshURLComponents = refreshURLOrCommunicationErrorAddressComponents
                refreshURLComponents.queryItems = queryItems
                subject.send(.identificationSucceeded(redirectURL: refreshURLComponents.url))
                subject.send(completion: .finished)
            } else if resultData.reason == "User_Cancelled" {
                logger.info("[aa2] onAuthenticationCompleted: user cancelled")
                subject.send(.identificationCancelled)
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
                logger.error("[aa2] onAuthenticationCompleted error minor: \(String(describing: resultMinor))")
                subject.send(completion: .failure(.identificationFailed(resultMajor: resultMajor,
                                                                        resultMinor: resultMinor,
                                                                        refreshURL: errorAddressComponents.url)))
            }
        } else {
            subject.send(completion: .failure(.identificationFailedWithBadRequest))
        }
    }

    func onChangePinCompleted(changePinResult: AusweisApp2SDKWrapper.ChangePinResult) {
        if changePinResult.success {
            logger.info("[aa2] onChangePinCompleted: success")
            subject.send(.pinChangeSucceeded)
            subject.send(completion: .finished)
        } else if changePinResult.reason == "User_Cancelled" {
            logger.info("[aa2] onChangePinCompleted: user cancelled")
            subject.send(.pinChangeCancelled)
            subject.send(completion: .finished)
        } else {
            logger.error("[aa2] onChangePinCompleted error: \(String(describing: changePinResult.reason))")
            subject.send(completion: .failure(.pinChangeFailed))
        }
    }

    func onWrapperError(error: AusweisApp2SDKWrapper.WrapperError) {
        logger.error("[aa2] onWrapperError: \(String(describing: error))")
        subject.send(completion: .failure(.frameworkError("\(error.msg) - \(error.error)")))
    }

    func onBadState(error: String) {
        logger.error("[aa2] onBadState error: \(error)")
        subject.send(completion: .failure(.frameworkError(error)))
    }

    func onCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
        logger.info("[aa2] onCertificate")
        subject.send(.certificateDescriptionRetrieved(.init(certificateDescription)))
    }

    func onEnterCan(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("[aa2] onEnterCan error: \(error)")
        }
        logger.info("[aa2] onEnterCan")
        subject.send(.canRequested)
    }

    func onEnterNewPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("[aa2] onEnterNewPin error: \(error)")
        }
        logger.info("[aa2] onEnterNewPin")
        subject.send(.newPINRequested)
    }

    func onEnterPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("[aa2] onEnterPin error: \(error)")
        }
        logger.info("[aa2] onEnterPin")
        subject.send(.pinRequested(remainingAttempts: reader.card?.pinRetryCounter))
    }

    func onEnterPuk(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("[aa2] onEnterPuk error: \(error)")
        }
        logger.info("[aa2] onEnterPuk")
        subject.send(.pukRequested)
    }

    func onInfo(versionInfo: AusweisApp2SDKWrapper.VersionInfo) {
        logger.warning("[aa2] onInfo: \(String(describing: versionInfo))")
    }

    func onInternalError(error: String) {
        logger.error("[aa2] onInternalError: \(error)")
        subject.send(completion: .failure(.frameworkError(error)))
    }

    func onReader(reader: AusweisApp2SDKWrapper.Reader?) {
        guard let reader else {
            // reader is nil after a flow is finished
            logger.info("[aa2] onReader: reader is nil")
            return
        }

        if let card = reader.card {
            logger.info("[aa2] onReader card: \(String(describing: card))")
            if card.deactivated {
                subject.send(completion: .failure(.cardDeactivated))
            } else {
                subject.send(.cardRecognized)
            }
        } else {
            logger.info("[aa2] onReader: card is nil")
        }
    }

    func onReaderList(readers: [AusweisApp2SDKWrapper.Reader]?) {
        logger.warning("[aa2] onReaderList: \(String(describing: readers))")
    }

    func onStatus(workflowProgress: AusweisApp2SDKWrapper.WorkflowProgress) {
        logger.warning("[aa2] onStatus: \(String(describing: workflowProgress))")
    }
}

extension CertificateDescription {
    init(_ description: AusweisApp2SDKWrapper.CertificateDescription) {
        issuerName = description.issuerName
        issuerURL = description.issuerUrl
        purpose = description.purpose
        subjectName = description.subjectName
        subjectURL = description.subjectUrl
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
