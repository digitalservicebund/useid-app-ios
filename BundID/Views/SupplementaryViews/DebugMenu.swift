import SwiftUI
import ComposableArchitecture

#if PREVIEW
extension View {
    func identifyDebugMenu<Sequence, Action>(
        store: Store<[Sequence], Action>,
        action: @escaping (Sequence) -> Action
    ) -> some View where Sequence: Equatable, Sequence: Identifiable, Sequence.ID == String {
        toolbar {
            ToolbarItem(placement: .primaryAction) {
                WithViewStore(store) { viewStore in
                    Menu {
                        ForEach(viewStore.state) { sequence in
                            Button(sequence.id) {
                                viewStore.send(action(sequence))
                            }
                        }
                    } label: {
                        Label("Debug", systemImage: "wrench")
                    }
                }
            }
        }
    }
}
#endif
