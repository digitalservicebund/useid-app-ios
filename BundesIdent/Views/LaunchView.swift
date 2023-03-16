import SwiftUI
import ComposableArchitecture

struct Launch: ReducerProtocol {
    typealias State = Void

    enum Action: Equatable {}

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {}
}

struct LaunchView: View {

    var store: StoreOf<Launch>

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.white)
            Asset.launchLogo.swiftUIImage
        }
        .ignoresSafeArea()
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView(store: .empty)
    }
}
