import SwiftUI
import ComposableArchitecture

enum MissingPINLetterAction: Equatable {}

struct MissingPINLetter: View {
    let store: Store<Void, MissingPINLetterAction>
    
    var body: some View {
        DialogView(store: store,
                   title: L10n.FirstTimeUser.MissingPINLetter.title,
                   message: L10n.FirstTimeUser.MissingPINLetter.body,
                   imageMeta: ImageMeta(asset: Asset.missingPINBrief))
    }
}

struct MissingPINLetter_Previews: PreviewProvider {
    static var previews: some View {
        MissingPINLetter(store: Store(initialState: (),
                                      reducer: .empty,
                                      environment: AppEnvironment.preview))
    }
}
