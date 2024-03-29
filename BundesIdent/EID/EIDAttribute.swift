import Foundation
#if !targetEnvironment(simulator)
import AusweisApp2SDKWrapper
#endif

// TR-03110 (Part 4), Section 2.2.3
enum EIDAttribute: String, Equatable, Identifiable {
    case documentType // DG1
    case issuingCountry // DG2
    case validUntil // DG3
    case givenNames // DG4
    case familyName // DG5
    case artisticName // DG6
    case doctoralDegree // DG7
    case dateOfBirth // DG8
    case placeOfBirth // DG9
    case nationality // DG10
    case birthName // DG13
    case address // DG17
    case communityID // DG18
    case residencePermitI // DG19
    case residencePermitII // DG20

    case addressVerification
    case ageVerification
    case pseudonym
    case writeAddress
    case writeCommunityID
    case writeResidencePermitI
    case writeResidencePermitII
    case canAllowed
    case pinManagement

    var id: String { rawValue }
}

extension EIDAttribute {
    var localizedTitle: String {
        switch self {
        case .documentType: return L10n.CardAttribute.dg01
        case .issuingCountry: return L10n.CardAttribute.dg02
        case .validUntil: return L10n.CardAttribute.dg03
        case .givenNames: return L10n.CardAttribute.dg04
        case .familyName: return L10n.CardAttribute.dg05
        case .artisticName: return L10n.CardAttribute.dg06
        case .doctoralDegree: return L10n.CardAttribute.dg07
        case .dateOfBirth: return L10n.CardAttribute.dg08
        case .placeOfBirth: return L10n.CardAttribute.dg09
        case .nationality: return L10n.CardAttribute.dg10
        case .birthName: return L10n.CardAttribute.dg13
        case .address: return L10n.CardAttribute.dg17
        case .communityID: return L10n.CardAttribute.dg18
        case .residencePermitI: return L10n.CardAttribute.dg19
        case .residencePermitII: return L10n.CardAttribute.dg20
        case .addressVerification: return L10n.CardAttribute.addressVerification
        case .ageVerification: return L10n.CardAttribute.ageVerification
        case .pseudonym: return L10n.CardAttribute.pseudonym
        case .writeAddress: return L10n.CardAttribute.Write.dg17
        case .writeCommunityID: return L10n.CardAttribute.Write.dg18
        case .writeResidencePermitI: return L10n.CardAttribute.Write.dg19
        case .writeResidencePermitII: return L10n.CardAttribute.Write.dg20
        case .canAllowed: return L10n.CardAttribute.canAllowed
        case .pinManagement: return L10n.CardAttribute.pinManagement
        }
    }
}
