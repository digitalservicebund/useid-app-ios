import Foundation
import LicensePlistViewController
import UIKit

class BundLicensePlistViewController: LicensePlistViewController {
    
    public convenience init(fileNamed fileName: String,
                            title: String? = LicensePlistViewController.defaultTitle,
                            headerHeight: CGFloat? = LicensePlistViewController.defaultHeaderHeight,
                            tableViewStyle: UITableView.Style = .grouped) {
        let path = Bundle.main.path(forResource: fileName, ofType: "plist")
        self.init(plistPath: path, title: title, headerHeight: headerHeight, tableViewStyle: tableViewStyle)
    }
    
    override init(plistPath: String? = LicensePlistViewController.defaultPlistPath, title: String? = LicensePlistViewController.defaultTitle, headerHeight: CGFloat? = LicensePlistViewController.defaultHeaderHeight, tableViewStyle: UITableView.Style = .grouped) {
        super.init(plistPath: plistPath, title: title, headerHeight: headerHeight, tableViewStyle: tableViewStyle)
    }
    
    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.textLabel?.font = .bundBodyLRegular
        return cell
    }
}
