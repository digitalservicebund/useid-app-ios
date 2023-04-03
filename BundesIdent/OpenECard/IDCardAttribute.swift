import Foundation
#if !targetEnvironment(simulator)
import AusweisApp2SDKWrapper
#endif

// TR-03110 (Part 4), Section 2.2.3
enum IDCardAttribute: String, Equatable, Identifiable {
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

    // TODO: Only until we have strings for all AccessRight cases
    case unknown
    
    var id: String { rawValue }

#if !targetEnvironment(simulator)
    init(_ accessRight: AccessRight) {
        switch accessRight {
        case .Address: self = .DG17
        case .BirthName: self = .DG13
        case .FamilyName: self = .DG05
        case .GivenNames: self = .DG04
        case .PlaceOfBirth: self = .DG09
        case .DateOfBirth: self = .DG08
        case .DoctoralDegree: self = .DG07
        case .ArtisticName: self = .DG06
        case .Pseudonym: self = .unknown // Spezielle Funktionen: Pseudonym / Pseudonym
        case .ValidUntil: self = .DG03
        case .Nationality: self = .DG10
        case .IssuingCountry: self = .DG02
        case .DocumentType: self = .DG01
        case .ResidencePermitI: self = .unknown
        case .ResidencePermitII: self = .unknown
        case .CommunityID: self = .unknown // DG18
        case .AddressVerification: self = .unknown // Spezielle Funktionen: Wohnortbestätigung / Address verification
        case .AgeVerification: self = .AGE_VERIFICATION // Spezielle Funktionen: Altersbestätigung / Age verification
        case .WriteAddress: self = .unknown
        case .WriteCommunityID: self = .unknown
        case .WriteResidencePermitI: self = .unknown
        case .WriteResidencePermitII: self = .unknown
        case .CanAllowed: self = .unknown
        case .PinManagement: self = .unknown
        }
    }
#endif
}

extension IDCardAttribute {
    var localizedTitle: String {
        switch self {
        case .DG01: return L10n.CardAttribute.dg01
        case .DG02: return L10n.CardAttribute.dg02
        case .DG03: return L10n.CardAttribute.dg03
        case .DG04: return L10n.CardAttribute.dg04
        case .DG05: return L10n.CardAttribute.dg05
        case .DG06: return L10n.CardAttribute.dg06
        case .DG07: return L10n.CardAttribute.dg07
        case .DG08: return L10n.CardAttribute.dg08
        case .DG09: return L10n.CardAttribute.dg09
        case .DG10: return L10n.CardAttribute.dg10
        case .DG13: return L10n.CardAttribute.dg13
        case .DG17: return L10n.CardAttribute.dg17
        case .DG19: return L10n.CardAttribute.dg19
        case .RESTRICTED_IDENTIFICATION: return L10n.CardAttribute.restrictedIdentification
        case .AGE_VERIFICATION: return L10n.CardAttribute.ageVerification

        case .unknown: return ""
        }
    }
}
