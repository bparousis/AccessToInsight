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
        AppSettings.nightMode ? .lightContent : .default
    }
    
    static func getJavascriptCSS(darkMode: Bool = AppSettings.nightMode) -> String {
        var cssFile: String
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            cssFile = getIpadCSS(darkMode: darkMode)
        default:
            cssFile = getIphoneCSS(darkMode: darkMode)
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
    
    static func decorateNavigationController(_ navigationController: UINavigationController?) {
        if #available(iOS 13.0, *) {}
        else {
            navigationController?.navigationBar.barStyle = AppSettings.nightMode ? .blackTranslucent : .default
        }
    }
    
    static func decorateLabel(_ label: UILabel) {
        label.textColor = theme.labelColor
    }
    
    static func makeDecoratedActivityIndicator() -> UIActivityIndicatorView {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: AppSettings.nightMode ? .white : .gray)
        }
    }
    
    static func decorateActionSheet(_ actionSheet: UIAlertController) {
        guard actionSheet.preferredStyle == .actionSheet else {
            return
        }
        
        if #available(iOS 13.0, *) {
            actionSheet.view.tintColor = theme.labelColor
        } else {
            if AppSettings.nightMode {
                actionSheet.view.tintColor = theme.backgroundColor
            }
        }
    }
    
    static func decorateView(_ view: UIView) {
        view.backgroundColor = theme.backgroundColor
    }

    static func htmlFontTag(content: String, darkMode: Bool = AppSettings.nightMode) -> String {
        let color = darkMode ? "white" : "black"
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
        
        if #available(iOS 13.0, *) {
            tableView.separatorColor = UIColor(named: "tableSeparatorColor")
        }
    }
}

private extension ThemeManager {

    static func getIpadCSS(darkMode: Bool = AppSettings.nightMode) -> String {
        darkMode ? "ipad_night.css" : "ipad.css"
    }

    static func getIphoneCSS(darkMode: Bool = AppSettings.nightMode) -> String {
        darkMode ? "iphone_night.css" : "iphone.css"
    }

    struct Theme {
        var backgroundColor: UIColor?
        var cellBackgroundColor: UIColor?
        var labelColor: UIColor?
        var barTintColor: UIColor?
        var tintColor: UIColor?
        var tableBackgroundColor: UIColor?
        
        static let light = Theme(backgroundColor: .white, cellBackgroundColor: .white, labelColor: .black, barTintColor: nil, tintColor: nil, tableBackgroundColor: .groupTableViewBackground)
        
        static let night = Theme(backgroundColor: .midnight, cellBackgroundColor: .charcoal, labelColor: .white, barTintColor: .midnight, tintColor: .babyBlue, tableBackgroundColor: .midnight)
        
        @available(iOS 13.0, *)
        static let ios13 = Theme(backgroundColor: UIColor(named: "backgroundColor"), cellBackgroundColor: UIColor(named: "cellBackgroundColor"), labelColor: .label, barTintColor: UIColor(named: "barTintColor"), tintColor: .label, tableBackgroundColor: UIColor(named: "tableBackgroundColor"))
    }

    static var theme: Theme {
        if #available(iOS 13.0, *) {
            return .ios13
        } else {
            return AppSettings.nightMode ? .night : .light
        }
    }
}
