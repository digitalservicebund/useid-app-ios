import SwiftUI

struct BundTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .bodyLRegular()
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lineWidth: 2)
                    .foregroundColor(.blue800)
            }
            .padding(1)
    }
}

struct BundTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(BundTextFieldStyle())
            TextField("Placeholder", text: .constant("abc@example.org"))
                .textFieldStyle(BundTextFieldStyle())
        }
        .previewLayout(.sizeThatFits)
    }
}
