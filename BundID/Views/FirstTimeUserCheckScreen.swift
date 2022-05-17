import SwiftUI

struct FirstTimeUserCheckScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                HeaderView(titleKey: L10n.FirstTimeUser.Intro.title,
                           bodyKey: L10n.FirstTimeUser.Intro.body,
                           imageMeta: ImageMeta(name: "eIDs"))
            }
            VStack {
                Button {
                    
                } label: {
                    Text(L10n.FirstTimeUser.Intro.yes)
                }
                .buttonStyle(BundButtonStyle(isPrimary: false))
                NavigationLink {
                    FirstTimeUserPINLetterScreen()
                } label: {
                    Text(L10n.FirstTimeUser.Intro.no)
                }
                .buttonStyle(BundButtonStyle(isPrimary: true))
                
            }
            .padding([.leading, .bottom, .trailing])
            .background(Color.white)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstTimeUserCheckScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserCheckScreen()
        }
            .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserCheckScreen()
        }
            .previewDevice("iPhone 12")
    }
}
