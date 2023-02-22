import SwiftUI

struct BackButton: View {

    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "chevron.backward").bundNavigationBarBold()
                Text(L10n.General.back).bundNavigationBar()
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
