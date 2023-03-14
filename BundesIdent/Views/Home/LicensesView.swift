import LicensePlistViewController
import SwiftUI
import UIKit

struct LicensesView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> LicensePlistViewController {
        BundLicensePlistViewController(fileNamed: "Licenses", tableViewStyle: .insetGrouped)
    }
    
    func updateUIViewController(_ uiViewController: LicensePlistViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {}
}
