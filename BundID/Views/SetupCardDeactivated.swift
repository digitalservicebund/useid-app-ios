import SwiftUI
import ComposableArchitecture

enum SetupCardDeactivatedAction: Equatable {
    case done
}

struct SetupCardDeactivated: View {
    
    var store: Store<Void, SetupCardDeactivatedAction>
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L10n.FirstTimeUser.CardDeactivated.title)
                        .font(.bundLargeTitle)
                        .foregroundColor(.blackish)
                        .padding(.bottom, 24)
                    Text(L10n.FirstTimeUser.CardDeactivated.body)
                        .font(.bundBody)
                        .foregroundColor(.blackish)
                    Link(L10n.FirstTimeUser.CardDeactivated.Link.title, destination: URL(string: L10n.FirstTimeUser.CardDeactivated.Link.url)!)
                        .font(.bundBody)
                }
                .padding(.horizontal)
            }
            
            DialogButtons(store: store,
                          secondary: nil,
                          primary: .init(title: L10n.FirstTimeUser.CardDeactivated.close,
                                         action: .done))
        }.navigationBarBackButtonHidden(true)
    }
}

struct SetupCardDeactivated_Previews: PreviewProvider {
    static var previews: some View {
        SetupCardDeactivated(store: .empty)
    }
}
