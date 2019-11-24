//
//  WKWebViewExtension.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import Foundation
import WebKit

extension WKWebView {

    func loadLocalWebContent(_ path: String) {
        var path = path
        
        if let hashRange = path.range(of: "#", options: .backwards) {
            path = String(path[..<hashRange.lowerBound])
        }
        
        if let resourcePath = Bundle.main.resourcePath {
            let fullPath = NSString.path(withComponents:[resourcePath, Constants.localWebDataDir, path])
            let url = URL(fileURLWithPath: fullPath)
            loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
    
    func adjustTextSize() {
        let textFontSize = MainViewController.textFontSize()
        let jsString = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(textFontSize)%'"
        evaluateJavaScript(jsString)
    }
    
    func fitContentToScreen() {
        let javascript = """
                var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);
                """
        evaluateJavaScript(javascript)
    }
    
    func applyTheme() {
        if #available(iOS 13.0, *) {
            let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
            evaluateJavaScript(ThemeManager.getJavascriptCSS(darkMode: isDarkMode))
        } else {
            evaluateJavaScript(ThemeManager.getJavascriptCSS())
        }
    }
    
    func applyTheme(darkMode: Bool) {
        evaluateJavaScript(ThemeManager.getJavascriptCSS(darkMode: darkMode))
    }
    
    private func urlStringToLocalContentPath(urlString: String ) -> String? {
        let urlArray = urlString.components(separatedBy: Constants.localWebDataDir)
        guard urlArray.count >= 2 else {
            return nil
        }
        return urlArray[1]
    }
    
    func getScrollPosition(completionHandler: @escaping (ScrollPosition?) -> Void) {
        self.evaluateJavaScript("scrollX") { (result, error) in
            guard let xPos = result as? Int else {
                completionHandler(nil)
                return
            }
            self.evaluateJavaScript("scrollY") {(result, error) in
                guard let yPos = result as? Int else {
                    completionHandler(nil)
                    return
                }
                completionHandler((xPos, yPos))
            }
        }
    }
    
    func getBookmark(completionHandler: @escaping (LocalBookmark?) -> Void) {
        let js = """
            String.prototype.stripHTML = function() {
                var matchTag = /<(?:.|\\s)*?>/g;
                var s = this.replace(matchTag, '');
                var spaceRegexp = /\\s+/g;
                return s.replace(spaceRegexp, ' ')
            };
        """
        evaluateJavaScript(js) { (result, error) in
            self.evaluateJavaScript("document.title") { (result, error) in
                let title = result as? String
                self.evaluateJavaScript("location.href") { (result, error) in
                    if let urlString = result as? String, let location = self.urlStringToLocalContentPath(urlString: urlString) {
                        self.evaluateJavaScript("document.getElementById('H_tipitakaID').innerHTML.stripHTML()")
                            { (result, error) in
                                let tipitakaID = result as? String
                                self.getScrollPosition { scrollPosition in
                                    let bookmark = LocalBookmark(title: title ?? "Untitled Bookmark",
                                                                 location: location,
                                                                 scrollX: scrollPosition?.x ?? 0,
                                                                 scrollY: scrollPosition?.y ?? 0)
                                    bookmark.note = tipitakaID
                                    completionHandler(bookmark)
                                }
                        }
                    } else {
                        completionHandler(nil)
                    }
                }
            }
        }
    }
}
