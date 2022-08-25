import SwiftUI
import ComposableArchitecture

enum MissingPINLetterAction: Equatable {}

struct MissingPINLetter: View {
    let store: Store<Void, MissingPINLetterAction>
    
    var body: some View {
        DialogView(store: store,
                   title: L10n.FirstTimeUser.MissingPINLetter.title,
                   message: L10n.FirstTimeUser.MissingPINLetter.body,
                   imageMeta: ImageMeta(name: "Missing-PIN-Brief"),
                   linkMeta: LinkMeta(title: L10n.FirstTimeUser.MissingPINLetter.Link.title,
                                      url: URL(string: L10n.FirstTimeUser.MissingPINLetter.Link.url)!))
    }
}

struct MissingPINLetter_Previews: PreviewProvider {
    static var previews: some View {
        MissingPINLetter(store: Store(initialState: (),
                                      reducer: .empty,
                                      environment: AppEnvironment.preview))
    }
}
