import SwiftUI
import ComposableArchitecture

struct DialogButtons<Action>: View {
    
    var store: Store<Void, Action>
    var secondaryButtonConfiguration: ButtonConfiguration?
    var primaryButtonConfiguration: ButtonConfiguration?
    
    struct ButtonConfiguration {
        let title: String
        let action: Action
    }
    
    init(store: Store<Void, Action>, secondary: ButtonConfiguration? = nil, primary: ButtonConfiguration?) {
        self.store = store
        self.secondaryButtonConfiguration = secondary
        self.primaryButtonConfiguration = primary
    }
    
    var body: some View {
        VStack {
            WithViewStore(store) { viewStore in
                if let secondaryButtonConfiguration = secondaryButtonConfiguration {
                    Button(secondaryButtonConfiguration.title,
                           action: { viewStore.send(secondaryButtonConfiguration.action) })
                    .buttonStyle(BundButtonStyle(isPrimary: false))
                }
                if let primaryButtonConfiguration = primaryButtonConfiguration {
                    Button(primaryButtonConfiguration.title,
                           action: { viewStore.send(primaryButtonConfiguration.action) })
                    .buttonStyle(BundButtonStyle(isPrimary: true))
                }
            }
        }
        .padding([.leading, .bottom, .trailing])
        .background(Color.white)
    }
}

enum DialogButtonsPreviewAction {
    case secondary
    case primary
}

struct DialogButtons_Previews: PreviewProvider {
    static var previews: some View {
        DialogButtons<DialogButtonsPreviewAction>(store: .empty,
                                                  secondary: .init(title: "Secondary", action: .secondary),
                                                  primary: .init(title: "Primary", action: .primary))
    }
}
