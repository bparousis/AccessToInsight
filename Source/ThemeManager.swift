//
//  ThemeManager.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-01.
//

import Foundation
import UIKit

class ThemeManager: NSObject {
    
    private static let SCREEN_CSS_PATH = "css/screen.css"
    private static let IPHONE_CSS = "iphone.css"
    private static let IPHONE_NIGHT_CSS = "iphone_night.css"
    private static let IPAD_CSS = "ipad.css"
    private static let IPAD_NIGHT_CSS = "ipad_night.css"
    
    @objc class func getCSSJavascript() -> String {
        var cssFile : String = IPHONE_CSS
        let nightMode = UserDefaults.standard.bool(forKey: "nightMode")
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            cssFile = nightMode ? IPAD_NIGHT_CSS : IPAD_CSS
            break
        default:
            cssFile = nightMode ? IPHONE_NIGHT_CSS : IPHONE_CSS
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
    
    @objc class func isNightMode() -> Bool {
        return UserDefaults.standard.bool(forKey: "nightMode")
    }
    
    @objc class func backgroundColor() -> UIColor {
        return isNightMode() ? UIColor(red: 39.0/255.0, green: 40.0/255.0, blue: 34.0/255.0, alpha: 1.0) : UIColor.white
    }
    
    @objc class func decorateTableCell(_ cell: UITableViewCell) {
        if isNightMode() {
            cell.backgroundColor = UIColor(red:68.0/255.0, green:68.0/255.0, blue:68.0/255.0, alpha:1.0)
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.textColor = UIColor.white
        }
        else {
            cell.backgroundColor = UIColor.white
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
        }
    }
    
    @objc class func decorateToolbar(_ toolbar : UIToolbar?) {
        if let decorateToolbar = toolbar {
            decorateToolbar.isTranslucent = true
            if isNightMode() {
                decorateToolbar.barTintColor = backgroundColor()
                decorateToolbar.tintColor = UIColor(red:227.0/255.0, green:227.0/255.0, blue:227.0/255.0, alpha:1.0)
            }
            else {
                decorateToolbar.barTintColor = nil
                decorateToolbar.tintColor = nil
            }
        }
    }
    
    @objc class func decorateTableView(_ tableView: UITableView?) {
        if let decorateTableView = tableView {
            if isNightMode() {
                decorateTableView.backgroundColor = backgroundColor()
            }
            else {
                let aTableView = UITableView(frame: .zero, style: .grouped)
                decorateTableView.backgroundColor = aTableView.backgroundColor
            }
        }
    }
}
