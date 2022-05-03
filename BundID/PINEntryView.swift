//
//  PINEntryView.swift
//  BundID
//
//  Created by Andreas Ganske on 03.05.22.
//

import SwiftUI
import Introspect

public struct PINEntryView: View {
    
    var maxDigits: Int = 5
    
    @State var pin: String = ""
    @State var showPin = true
    
    var handler: (String) -> Void
    
    public var body: some View {
        VStack(spacing: 10) {
            ZStack {
                pinCharacter
                textField
            }
        }
    }
    
    @ViewBuilder
    private var pinCharacter: some View {
        HStack(spacing: 20) {
            ForEach(0..<maxDigits, id: \.self) { index in
                VStack(spacing: 0) {
                    if showPin {
                        Text(self.pinCharacter(at: index))
                            .font(.custom("BundesSans", size: 26).bold())
                    } else {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .padding(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                            .opacity(index >= self.pin.count ? 0.0 : 1.0)
                    }
                    Rectangle()
                        .foregroundColor(.blackish)
                        .frame(height: 1)
                }
            }
        }
        .padding()
        .background(
            Color.white.cornerRadius(10)
        )
    }
    
    private var textField: some View {
        let boundPin = Binding<String>(get: { self.pin }, set: { newValue in
            self.pin = newValue
            self.submitPin()
        })
        
        return TextField("", text: boundPin, onCommit: submitPin)
            .accentColor(.clear)
            .foregroundColor(.clear)
            .keyboardType(.numberPad)
            .introspectTextField { textField in
                // Hack to show the keyboard after transitioning to this screen because of rearranging buttons.
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + .milliseconds(500)) {
                    textField.becomeFirstResponder()
                }
            }
    }
    
    private func submitPin() {
        if pin.count > maxDigits {
            pin = String(pin.prefix(maxDigits))
        }
        
        if pin.count == maxDigits {
            handler(pin)
        }
    }
    
    private func pinCharacter(at index: Int) -> String {
        guard index < self.pin.count else {
            return " "
        }
        return String(self.pin[self.pin.index(self.pin.startIndex, offsetBy: index)])
    }
}
