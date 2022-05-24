import SwiftUI

public struct PINEntryView: View {
    
    @Binding var pin: String
    var maxDigits: Int
    var groupEvery: Int?
    var showPIN = true
    var label: String = ""
    @Binding var shouldBeFocused: Bool
    var doneConfiguration: DoneConfiguration?
    
    public var body: some View {
        VStack(spacing: 10) {
            ZStack {
                textField
                pinCharacter
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
    }
    
    @ViewBuilder
    private var pinCharacter: some View {
        HStack(spacing: 20) {
            Spacer()
            ForEach(0..<maxDigits, id: \.self) { index in
                VStack(spacing: 0) {
                    if showPIN {
                        Text(pinCharacter(at: index))
                            .font(.custom("BundesSans", size: 26).bold())
                            .foregroundColor(.blackish)
                            .animation(.none)
                    } else {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .padding(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                            .foregroundColor(.blackish)
                            .opacity(index >= pin.count ? 0.0 : 1.0)
                            .animation(.linear(duration: 0.05))
                    }
                    Rectangle()
                        .foregroundColor(.blackish)
                        .frame(height: 1)
                }
                if let groupEvery = groupEvery, (index + 1) % groupEvery == 0, (index + 1) < maxDigits {
                    Spacer(minLength: 8)
                }
            }
            Spacer()
        }
        .padding()
        .accessibilityHidden(true)
        .accessibilityElement(children: .ignore)
    }
    
    @ViewBuilder
    private var textField: some View {
        PINTextField(text: $pin,
                     maxLength: maxDigits,
                     showPIN: showPIN,
                     isFirstResponder: $shouldBeFocused,
                     doneConfiguration: doneConfiguration)
            .accentColor(.clear)
            .foregroundColor(.clear)
            .keyboardType(.numberPad)
            .accessibilityLabel(label)
            .accessibilityValue(pin.map(String.init).joined(separator: " "))
    }
    
    private func pinCharacter(at index: Int) -> String {
        guard index < self.pin.count else {
            return " "
        }
        return String(self.pin[self.pin.index(self.pin.startIndex, offsetBy: index)])
    }
}
