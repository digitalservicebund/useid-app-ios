import SwiftUI

struct SetupPersonalPINErrorView: View {
    
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            VStack {
                Text(title)
                    .font(.bundBodyBold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red900)
                Text(message)
                    .font(.bundBody)
                    .foregroundColor(.blackish)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct SetupPersonalPINErrorView_Previews: PreviewProvider {
    static var previews: some View {
        SetupPersonalPINErrorView(title: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title,
                                  message: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.body)
            .previewLayout(.sizeThatFits)
    }
}
