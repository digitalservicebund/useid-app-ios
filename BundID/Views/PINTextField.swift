import SwiftUI

class CarretAtEndTextField: UITextField {
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        let beginning = self.beginningOfDocument
        let end = self.position(from: beginning, offset: self.text?.count ?? 0)
        return end
    }
}

struct DoneConfiguration {
    var enabled: Bool
    var title: String
    var handler: (String) -> Void
}

struct PINTextField: UIViewRepresentable {
    
    @Binding private var text: String
    var maxLength: Int
    var showPIN: Bool
    @Binding var shouldBeFocused: Bool
    var doneConfiguration: DoneConfiguration?
    var textChangeHandler: ((String) -> Void)?
    
    init(text: Binding<String>, maxLength: Int = 5, showPIN: Bool = true, shouldBeFocused: Binding<Bool>, doneConfiguration: DoneConfiguration?, textChangeHandler: ((String) -> Void)?) {
        self._text = text
        self.maxLength = maxLength
        self.showPIN = showPIN
        self._shouldBeFocused = shouldBeFocused
        self.doneConfiguration = doneConfiguration
        self.textChangeHandler = textChangeHandler
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = CarretAtEndTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.isSecureTextEntry = !showPIN
        textField.textColor = .clear
        textField.backgroundColor = .clear
        
        if let doneConfiguration = doneConfiguration {
            let frame = CGRect(x: 0, y: 0, width: textField.frame.size.width, height: 44)
            let toolBar = UIToolbar(frame: frame)
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                         target: nil,
                                         action: nil)
            let doneButton = UIBarButtonItem(title: doneConfiguration.title,
                                             image: nil,
                                             primaryAction: UIAction { _ in
                doneConfiguration.handler(text)
            })
            doneButton.isEnabled = doneConfiguration.enabled
            toolBar.setItems([spacer, doneButton], animated: false)
            textField.inputAccessoryView = toolBar
        }
        
        let editingChanged = UIAction { action in
            let newText = (action.sender as! UITextField).text ?? ""
            let oldText = text
            withAnimation(.linear(duration: 0.05)) {
                text = newText
            }
            if newText != oldText {
                textChangeHandler?(text)
            }
        }
        
        textField.addAction(editingChanged, for: .editingChanged)
        
        if shouldBeFocused {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        }
        
        return textField
    }
    
    func updateUIView(_ textField: UITextField, context: Context) {
        textField.text = text
        if let doneConfiguration = doneConfiguration, let doneButton = findDoneButton(textField) {
            doneButton.isEnabled = doneConfiguration.enabled
        }
        if shouldBeFocused {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        }
    }
    
    func findDoneButton(_ textField: UITextField) -> UIBarButtonItem? {
        return (textField.inputAccessoryView as? UIToolbar)?.items?[safe: 1]
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
