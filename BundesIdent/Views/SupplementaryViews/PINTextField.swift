import SwiftUI

class CarretAtEndTextField: UITextField {
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        let beginning = beginningOfDocument
        let end = position(from: beginning, offset: text?.count ?? 0)
        return end
    }
}

struct DoneConfiguration {
    var enabled: Bool
    var title: String
    var handler: (String) -> Void
}

struct PINTextField: UIViewRepresentable {
    
    @Binding var text: String
    var maxLength: Int
    var showPIN: Bool
    var doneConfiguration: DoneConfiguration?

    init(text: Binding<String>, maxLength: Int = 5, showPIN: Bool = true, doneConfiguration: DoneConfiguration?) {
        _text = text
        self.maxLength = maxLength
        self.showPIN = showPIN
        self.doneConfiguration = doneConfiguration
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = CarretAtEndTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.isSecureTextEntry = !showPIN
        textField.textColor = .clear
        textField.backgroundColor = .clear
        
        if let doneConfiguration {
            let frame = CGRect(x: 0, y: 0, width: textField.frame.size.width, height: 44)
            let toolBar = UIToolbar(frame: frame)
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                         target: nil,
                                         action: nil)
            let doneButton = UIBarButtonItem(title: doneConfiguration.title,
                                             image: nil,
                                             primaryAction: UIAction(handler: { _ in doneConfiguration.handler(text) }))
            doneButton.style = .done
            doneButton.isEnabled = doneConfiguration.enabled
            toolBar.setItems([spacer, doneButton], animated: false)
            textField.inputAccessoryView = toolBar
        }
        
        let editingChanged = UIAction { action in
            let newText = (action.sender as? UITextField)?.text ?? ""
            withAnimation(.linear(duration: 0.2)) {
                text = newText
            }
        }
        
        textField.addAction(editingChanged, for: .editingChanged)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        if let doneConfiguration, let doneButton = findDoneButton(uiView) {
            doneButton.isEnabled = doneConfiguration.enabled
        }
        
        context.coordinator.maxLength = maxLength
    }
    
    func findDoneButton(_ textField: UITextField) -> UIBarButtonItem? {
        (textField.inputAccessoryView as? UIToolbar)?.items?[safe: 1]
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($text, maxLength: maxLength)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        
        let text: Binding<String>
        var maxLength: Int
        
        init(_ text: Binding<String>, maxLength: Int) {
            self.text = text
            self.maxLength = maxLength
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard CharacterSet(charactersIn: "0123456789").isSuperset(of: CharacterSet(charactersIn: string)) else { return false }
            
            return textLimit(existingText: textField.text,
                             newText: string,
                             limit: maxLength)
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
