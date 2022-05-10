//
//  PINTextField.swift
//  BundID
//
//  Created by Andreas Ganske on 05.05.22.
//

import SwiftUI

class CarretAtEndTextField: UITextField {
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        let beginning = self.beginningOfDocument
        let end = self.position(from: beginning, offset: self.text?.count ?? 0)
        return end
    }
}

struct PINTextField: UIViewRepresentable {
    
    @Binding private var text: String
    var maxLength: Int
    var doneEnabled: Bool
    var doneText: String
    var showPIN: Bool
    var handler: (String) -> Void
    
    init(text: Binding<String>, maxLength: Int = 5, doneEnabled: Bool = true, doneText: String, showPIN: Bool = true, handler: @escaping (String) -> Void) {
        self._text = text
        self.maxLength = maxLength
        self.doneEnabled = doneEnabled
        self.doneText = doneText
        self.showPIN = showPIN
        self.handler = handler
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textfield = CarretAtEndTextField()
        textfield.delegate = context.coordinator
        textfield.keyboardType = .numberPad
        textfield.isSecureTextEntry = !showPIN
        textfield.textColor = .clear
        textfield.backgroundColor = .clear
        let frame = CGRect(x: 0, y: 0, width: textfield.frame.size.width, height: 44)
        let toolBar = UIToolbar(frame: frame)
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                     target: nil,
                                     action: nil)
        let doneButton = UIBarButtonItem(title: doneText,
                                         image: nil,
                                         primaryAction: UIAction { _ in
            handler(text)
        })
        doneButton.isEnabled = doneEnabled
        let editingChanged = UIAction { action in
            text = (action.sender as! UITextField).text ?? ""
        }
        textfield.addAction(editingChanged, for: .editingChanged)
        toolBar.setItems([spacer, doneButton], animated: false)
        textfield.inputAccessoryView = toolBar
        textfield.becomeFirstResponder()
        return textfield
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        let doneButton = (uiView.inputAccessoryView as! UIToolbar).items![1]
        doneButton.isEnabled = doneEnabled
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PINTextField
        
        init(_ textField: PINTextField) {
            self.parent = textField
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard CharacterSet(charactersIn: "0123456789").isSuperset(of: CharacterSet(charactersIn: string)) else { return false }
            
            return self.textLimit(existingText: textField.text,
                                  newText: string,
                                  limit: parent.maxLength)
        }
        
        private func textLimit(existingText: String?,
                               newText: String,
                               limit: Int) -> Bool {
            let text = existingText ?? ""
            let isAtLimit = text.count + newText.count <= limit
            return isAtLimit
        }
    }
}
