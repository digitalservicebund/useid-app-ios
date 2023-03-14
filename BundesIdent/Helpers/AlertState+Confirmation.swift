import ComposableArchitecture

extension AlertState {
    static func confirmEndInIdentification(_ action: Action) -> AlertState {
        AlertState(title: TextState(verbatim: L10n.Identification.ConfirmEnd.title),
                   message: TextState(verbatim: L10n.Identification.ConfirmEnd.message),
                   primaryButton: .destructive(TextState(verbatim: L10n.Identification.ConfirmEnd.confirm),
                                               action: .send(action)),
                   secondaryButton: .cancel(TextState(verbatim: L10n.Identification.ConfirmEnd.deny)))
    }
    
    static func confirmEndInSetup(_ action: Action) -> AlertState {
        AlertState(title: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.title),
                   message: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.message),
                   primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm),
                                               action: .send(action)),
                   secondaryButton: .cancel(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.deny)))
    }
}
