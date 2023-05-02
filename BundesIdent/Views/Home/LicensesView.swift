import SwiftUI
import UIKit
import LicensePlistViewController

struct LicensesView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> LicensePlistViewController {
        return BundLicensePlistViewController(fileNamed: "Licenses", tableViewStyle: .insetGrouped)
    }
    
    func updateUIViewController(_ uiViewController: LicensePlistViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {}
}
