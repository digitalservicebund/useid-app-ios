import SwiftUI

struct BackButton: View {

    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: "chevron.backward").bodyLBold(color: .accentColor)
                Text(L10n.General.back).bodyLRegular(color: .accentColor)
            }
            .padding(.leading, -8)
        }
    }
}

struct BackButton_Previews: PreviewProvider {
    static var previews: some View {
        BackButton {}
    }
}
