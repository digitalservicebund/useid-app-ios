import ComposableArchitecture
import SwiftUI

struct IdentificationOverviewLoading: View {
    var store: Store<Void, TokenFetchLoadingAction>
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                .scaleEffect(3)
                .frame(maxWidth: .infinity)
                .padding(50)
            Text(L10n.Identification.Overview.loading)
                .font(.bundBody)
                .foregroundColor(.blackish)
                .padding(.bottom, 50)
        }
    }
}
