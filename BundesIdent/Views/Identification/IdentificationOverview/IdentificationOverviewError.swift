import Foundation

struct IdentificationOverviewErrorState: Equatable {
    let error: IdentifiableError
    let canGoBackToSetupIntro: Bool
    
    init(error: IdentifiableError, canGoBackToSetupIntro: Bool = false) {
        self.error = error
        self.canGoBackToSetupIntro = canGoBackToSetupIntro
    }
}

enum IdentificationOverviewErrorAction: Equatable {
    case retry
}
