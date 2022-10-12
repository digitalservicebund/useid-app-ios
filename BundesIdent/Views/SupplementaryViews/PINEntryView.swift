import SwiftUI

public struct PINEntryView: View {
    
    @Binding var pin: String
    var maxDigits: Int
    var groupEvery: Int?
    var showPIN = true
    var label: String = ""
    @Binding var shouldBeFocused: Bool
    var backgroundColor: Color = .clear
    var doneConfiguration: DoneConfiguration?
    
    public var body: some View {
        ZStack {
            textField
            pinCharacter
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    private var pinCharacter: some View {
        HStack(spacing: 0) {
            Spacer()
            
            ForEach(0..<maxDigits, id: \.self) { index in
                CharacterView(showPIN: showPIN, pin: pin, index: index)
                    .background(VStack {
                        Spacer()
                        Rectangle()
                            .foregroundColor(.blackish)
                            .frame(height: 1)
                            .frame(minWidth: 28)
                    })
                    .frame(maxWidth: .infinity)
                
                if let groupEvery = groupEvery, (index + 1) % groupEvery == 0, (index + 1) < maxDigits {
                    Spacer(minLength: 8)
                }
            }
            
            Spacer()
        }
        .padding(.vertical)
        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(backgroundColor))
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
        .frame(height: 1)
    }
}

private struct CharacterView: View {
    var showPIN: Bool
    var pin: String
    var index: Int
    
    var body: some View {
        if showPIN {
            Text(pinCharacter(at: index))
                .font(.bundLargeTitle)
                .foregroundColor(.blackish)
                .animation(.none)
        } else {
            Image(systemName: "circle.fill")
                .resizable()
                .frame(width: 16, height: 16)
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                .foregroundColor(.blackish)
                .opacity(index >= pin.count ? 0.0 : 1.0)
                .animation(.none)
        }
    }
    
    private func pinCharacter(at index: Int) -> String {
        guard index < self.pin.count else {
            return " "
        }
        return String(self.pin[self.pin.index(self.pin.startIndex, offsetBy: index)])
    }
}
