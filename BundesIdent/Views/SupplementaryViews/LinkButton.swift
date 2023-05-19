import SwiftUI

struct LinkButton: View {
    let text: String
    let action: () -> Void

    init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .underline()
        }
        .buttonStyle(BundLinkButtonStyle())
    }
}

struct LinkButton_Previews: PreviewProvider {
    static var previews: some View {
        LinkButton("Link text") {}
    }
}

private struct BundLinkButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bodyLBold(color: color(configuration: configuration))
    }

    private func color(configuration: Configuration) -> Color {
        guard isEnabled else {
            return .neutral900
        }
        return configuration.isPressed ? .blue600 : .blue800
    }
}
