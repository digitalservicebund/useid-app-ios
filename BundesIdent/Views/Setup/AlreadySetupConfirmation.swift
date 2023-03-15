import SwiftUI
import ComposableArchitecture
import MarkdownUI

struct AlreadySetupConfirmation: ReducerProtocol {
    typealias State = Void
    
    enum Action: Equatable {
        case close
    }
    
    func reduce(into state: inout Void, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct AlreadySetupConfirmationView: View {
    var store: StoreOf<AlreadySetupConfirmation>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .foregroundColor(.green800)
                        .frame(width: 72, height: 72)
                        .padding(.top, 16)
                    Text(L10n.FirstTimeUser.AlreadySetupConfirmation.title)
                        .headingL()
                    Markdown(L10n.FirstTimeUser.AlreadySetupConfirmation.box)
                        .markdownTheme(.bund)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.green100)
                        .foregroundColor(.blackish)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 24)
            }
            DialogButtons(store: store,
                          primary: .init(title: L10n.FirstTimeUser.AlreadySetupConfirmation.close,
                                         action: .close))
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AlreadySetupConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AlreadySetupConfirmationView(store: .empty)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        BackButton {}
                    }
                }
        }
    }
}
