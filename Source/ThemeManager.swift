//
//  ThemeManager.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-01.
//

import Foundation
import UIKit

struct ThemeManager {
    
    static var preferredStatusBarStyle: UIStatusBarStyle {
        return isNightMode ? .lightContent : .default
    }
    
    static var javascriptCSS: String {
        var cssFile: String
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            cssFile = isNightMode ? ipadNightCSS : ipadCSS
        default:
            cssFile = isNightMode ? iphoneNightCSS : iphoneCSS
        }
        
        let javascript = """
        var links = document.getElementsByTagName('link');
        for(var i = 0; i < links.length; i++) {
        if (links[i].rel === 'stylesheet') {
        var hrefString = links[i].href;
        links[i].href = hrefString.replace('screen.css', '\(cssFile)');
        break;
        }}
        """
        return javascript
    }
    
    static var webViewAlpha: CGFloat {
        return isNightMode ? 0.0 : 1.0
    }
    
    static func decorateNavigationController(_ navigationController: UINavigationController?) {
        if let navigationController = navigationController {
            navigationController.navigationBar.barStyle = isNightMode ? .blackTranslucent : .default
        }
    }
    
    static func decorateLabel(_ label: UILabel) {
        label.textColor = theme.labelColor
    }
    
    static func makeDecoratedActivityIndicator() -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: isNightMode ? .white : .gray)
    }
    
    static func decorateActionSheet(_ actionSheet: UIAlertController) {
        guard actionSheet.preferredStyle == .actionSheet else {
            return
        }
        
        if isNightMode {
            actionSheet.view.tintColor = theme.backgroundColor
        }
    }
    
    static func decorateView(_ view: UIView) {
        view.backgroundColor = theme.backgroundColor
    }
    
    static func htmlFontTag(content: String) -> String {
        let color = isNightMode ? "white" : "black"
        return "<font color='\(color)'>\(content)</font>"
    }
    
    static func decorateGroupedTableCell(_ cell: UITableViewCell) {
        cell.textLabel?.textColor = theme.labelColor
        cell.detailTextLabel?.textColor = theme.labelColor
        cell.backgroundColor = theme.cellBackgroundColor
    }
    
    static func decorateTableCell(_ cell: UITableViewCell) {
        cell.backgroundColor = theme.backgroundColor
        cell.textLabel?.textColor = theme.labelColor
        cell.detailTextLabel?.textColor = theme.labelColor
    }
    
    static func decorateToolbar(_ toolbar : UIToolbar) {
        toolbar.isTranslucent = true
        toolbar.barTintColor = theme.barTintColor
        toolbar.tintColor = theme.tintColor
    }
    
    static func decorateTableView(_ tableView: UITableView) {
        switch tableView.style {
        case .plain:
            tableView.backgroundColor = theme.backgroundColor
        default:
            tableView.backgroundColor = theme.tableBackgroundColor
        }
    }
}

private extension ThemeManager {
    
    static let iphoneCSS = "iphone.css"
    static let iphoneNightCSS = "iphone_night.css"
    static let ipadCSS = "ipad.css"
    static let ipadNightCSS = "ipad_night.css"
    
    struct Theme {
        var backgroundColor: UIColor
        var cellBackgroundColor: UIColor
        var labelColor: UIColor
        var barTintColor: UIColor?
        var tintColor: UIColor?
        var tableBackgroundColor: UIColor
        
        static let light = Theme(backgroundColor: .white, cellBackgroundColor: .white, labelColor: .black, barTintColor: nil, tintColor: nil, tableBackgroundColor: .groupTableViewBackground)
        
        static let night = Theme(backgroundColor: .midnight, cellBackgroundColor: .charcoal, labelColor: .white, barTintColor: .midnight, tintColor: .babyBlue, tableBackgroundColor: .midnight)
    }
    
    static var isNightMode: Bool {
        return UserDefaults.standard.bool(forKey: "nightMode")
    }
    
    static var theme: Theme {
        return isNightMode ? .night : .light
    }
}
