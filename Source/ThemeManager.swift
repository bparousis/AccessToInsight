//
//  ThemeManager.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-01.
//

import Foundation
import UIKit
import WebKit

fileprivate struct ThemeManager {
    
    static func getJavascriptCSS(darkMode: Bool = AppSettings.nightMode) -> String {
        var cssFile: String
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            cssFile = getIpadCSS(darkMode: darkMode)
        default:
            cssFile = getIphoneCSS(darkMode: darkMode)
        }
        
        return """
        var links = document.getElementsByTagName('link');
        for(var i = 0; i < links.length; i++) {
        if (links[i].rel === 'stylesheet') {
        var hrefString = links[i].href;
        links[i].href = hrefString.replace('screen.css', '\(cssFile)');
        break;
        }}
        """
    }
    
    static func decorateNavigationController(_ navigationController: UINavigationController) {
        if #available(iOS 13.0, *) {}
        else {
            navigationController.navigationBar.barStyle = AppSettings.nightMode ? .blackTranslucent : .default
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
    
    static func decorateBackground(_ view: UIView) {
        view.backgroundColor = theme.backgroundColor
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

// MARK: Decorate extensions

extension UITableView {
    static func makeDecorated(frame: CGRect = .zero, style: Style = .grouped) -> UITableView {
        let tableView = UITableView(frame: frame, style: style)
        tableView.decorate()
        return tableView
    }
    
    func decorate() {
        ThemeManager.decorateTableView(self)
    }
}

extension UIToolbar {
    static func makeDecorated() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.decorate()
        return toolbar
    }
    
    func decorate() {
        ThemeManager.decorateToolbar(self)
    }
}

extension UITableViewCell {
    func decorateGrouped() {
        ThemeManager.decorateGroupedTableCell(self)
    }
    
    func decorate() {
        ThemeManager.decorateTableCell(self)
    }
}

extension UIAlertController {
    static func makeDecoratedActionSheet(title: String, message: String? = nil) -> UIAlertController {
        let actionSheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        ThemeManager.decorateActionSheet(actionSheet)
        return actionSheet
    }
}

extension UILabel {
    static func makeDecorated(frame: CGRect = .zero) -> UILabel {
        let label = UILabel(frame: frame)
        label.decorate()
        return label
    }
    
    func decorate() {
        ThemeManager.decorateLabel(self)
    }
}

extension UIView {
    func decorateBackground() {
        ThemeManager.decorateBackground(self)
    }
}

extension UIActivityIndicatorView {
    static func makeDecorated() -> UIActivityIndicatorView {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: AppSettings.nightMode ? .white : .gray)
        }
    }
}

extension UINavigationController {
    static func makeDecorated(rootViewController: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: rootViewController)
        nav.decorate()
        return nav
    }
    
    func decorate() {
        ThemeManager.decorateNavigationController(self)
    }
}

extension WKWebView {
    func decorate() {
        if #available(iOS 13.0, *) {
            let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
            evaluateJavaScript(ThemeManager.getJavascriptCSS(darkMode: isDarkMode))
        } else {
            evaluateJavaScript(ThemeManager.getJavascriptCSS())
        }
    }
}
