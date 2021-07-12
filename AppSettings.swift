//
//  AppSettings.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2021-06-11.
//

import Foundation
import UIKit

typealias ScrollPosition = (x: Int, y: Int)

enum Page {
    static let home = "index.html"
    static let about = "about.html"
    static let randomSutta = "random-sutta.html"
    static let randomArticle = "random-article.html"
}

struct AppSettings {
    
    private static let defaultTextFontSize = 100
    private static let textFontSizeKey = "fontSize"
    private static let bookmarkKey = "bookmark"
    private static let lastLocationBookmarkKey = "lastLocationBookmark"
    private static let lastXScrollPosition = "lastXScrollPosition"
    private static let lastYScrollPosition = "lastYScrollPosition"
    private static let lastSearchScopeIndexKey = "lastSearchScopeIndex"
    private static let recentSearchesKey = "recentSearches"
    
    static let topScrollPosition: ScrollPosition = (0,0)
    
    // MARK: Night Mode
    static var nightMode: Bool {
        set {
            Current.defaults.set(newValue, forKey: "nightMode")
        }
        
        get {
            Current.defaults.bool(forKey: "nightMode")
        }
    }
    
    // MARK: Last Scroll Position
    static var lastScrollPosition: ScrollPosition {
        set {
            Current.defaults.set(newValue.x, forKey: lastXScrollPosition)
            Current.defaults.set(newValue.y, forKey: lastYScrollPosition)
        }
        
        get {
            let x = Current.defaults.integer(forKey: lastXScrollPosition)
            let y = Current.defaults.integer(forKey: lastYScrollPosition)
            return (x, y)
        }
    }
    
    // MARK:  Text Font SIze
    static var textFontSize: Int {
        set {
            Current.defaults.set(newValue, forKey: textFontSizeKey)
        }
        
        get {
            guard let textFontSize = Current.defaults.object(forKey: textFontSizeKey) as? Int else {
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
            Current.defaults.set(archiver.encodedData, forKey: lastLocationBookmarkKey)
        }
        
        get {
            var lastLocationBookmark: LocalBookmark?
            if let data = Current.defaults.data(forKey: lastLocationBookmarkKey) {
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
            Current.defaults.set(newValue, forKey: lastSearchScopeIndexKey)
        }
        
        get {
            Current.defaults.integer(forKey: lastSearchScopeIndexKey)
        }
    }
    
    static var searchType: SearchType {
        lastSearchScopeIndex == 0 ? .title : .document
    }
    
    static var recentSearches: [String]? {
        set {
            Current.defaults.set(newValue, forKey: recentSearchesKey)
        }
        
        get {
            Current.defaults.stringArray(forKey: recentSearchesKey)
        }
    }
}
