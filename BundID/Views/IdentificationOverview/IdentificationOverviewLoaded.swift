import ComposableArchitecture
import SwiftUI

struct IdentificationOverviewLoaded: View {
    var store: Store<IdentificationOverviewLoadedState, TokenFetchLoadedAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HeaderView(title: L10n.Identification.Overview.Loaded.title(viewStore.request.subject),
                                   message: L10n.Identification.Overview.Loaded.body(viewStore.request.subject))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(viewStore.requiredReadAttributes) { attribute in
                                    HStack(spacing: 10) {
                                        Text("•")
                                        Text(attribute.localizedTitle)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .font(.bundBody)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue100, strokeColor: Color.blue400)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
                        .padding(.horizontal)
                        
                        NavigationLink {
                            IdentificationAbout(request: viewStore.request)
                        } label: {
                            HStack {
                                Text(L10n.Identification.Overview.Loaded.moreInfo(viewStore.request.subject))
                                    .font(.bundBody)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .accentColor(.blackish)
                        .frame(maxWidth: .infinity)
                        .background(
                            Color.gray100.cornerRadius(10)
                        )
                        .padding(.horizontal)
                    }
                }
                DialogButtons(store: store.stateless,
                              primary: .init(title: L10n.Identification.Overview.Loaded.continue, action: .continue))
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
