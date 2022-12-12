import Foundation

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
    
    var id: String { rawValue }
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
        }
    }
}
