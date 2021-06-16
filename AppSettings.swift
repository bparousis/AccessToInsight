//
//  AppSettings.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2021-06-11.
//

import Foundation
import UIKit

typealias ScrollPosition = (x: Int, y: Int)

struct AppSettings {
    
    private static let defaultTextFontSize = 100
    private static let textFontSizeKey = "fontSize"
    private static let bookmarkKey = "bookmark"
    private static let lastLocationBookmarkKey = "lastLocationBookmark"
    private static let lastXScrollPosition = "lastXScrollPosition"
    private static let lastYScrollPosition = "lastYScrollPosition"
    private static let lastSearchScopeIndexKey = "lastSearchScopeIndex"
    private static let recentSearchesKey = "recentSearches"
    
    // MARK: Night Mode
    static var nightMode: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "nightMode")
        }
        
        get {
            UserDefaults.standard.bool(forKey: "nightMode")
        }
    }
    
    // MARK: Last Scroll Position
    static var lastScrollPosition: ScrollPosition {
        set {
            UserDefaults.standard.set(newValue.x, forKey: lastXScrollPosition)
            UserDefaults.standard.set(newValue.y, forKey: lastYScrollPosition)
        }
        
        get {
            let x = UserDefaults.standard.integer(forKey: lastXScrollPosition)
            let y = UserDefaults.standard.integer(forKey: lastYScrollPosition)
            return (x, y)
        }
    }
    
    // MARK:  Text Font SIze
    static var textFontSize: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: textFontSizeKey)
        }
        
        get {
            guard let textFontSize = UserDefaults.standard.object(forKey: textFontSizeKey) as? Int else {
                return defaultTextFontSize
            }
            return textFontSize
        }
    }
    
    static func resetTextFontSize() {
        textFontSize = defaultTextFontSize
    }
    
    // MARK: Last Location Bookmark
    static var lastLocationBookmark: LocalBookmark? {
        set {
            let archiver = NSKeyedArchiver(requiringSecureCoding: false)
            archiver.encode(newValue, forKey: bookmarkKey)
            archiver.finishEncoding()
            UserDefaults.standard.set(archiver.encodedData, forKey: lastLocationBookmarkKey)
        }
        
        get {
            var lastLocationBookmark: LocalBookmark?
            if let data = UserDefaults.standard.data(forKey: lastLocationBookmarkKey) {
                if let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) {
                    unarchiver.requiresSecureCoding = false
                    lastLocationBookmark = unarchiver.decodeObject(of: LocalBookmark.self, forKey: bookmarkKey)
                    unarchiver.finishDecoding()
                }
            }
            return lastLocationBookmark
        }
    }

    // MARK: Last Search Scope Index
    static var lastSearchScopeIndex: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: lastSearchScopeIndexKey)
        }
        
        get {
            UserDefaults.standard.integer(forKey: lastSearchScopeIndexKey)
        }
    }
}
