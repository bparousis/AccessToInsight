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
        var pathWithoutHash : String = path
        
        if let hashRange = path.range(of: "#", options: .backwards) {
            pathWithoutHash = String(path[..<hashRange.lowerBound])
        }
        
        if let resourcePath = Bundle.main.resourcePath {
            let fullPath = NSString.path(withComponents:[resourcePath,Constants.LOCAL_WEB_DATA_DIR, pathWithoutHash])
            let readAccessPath = NSString.path(withComponents:[resourcePath,Constants.LOCAL_WEB_DATA_DIR])
            let url = URL(fileURLWithPath: fullPath)
            let readAccessURL = URL(fileURLWithPath: readAccessPath)
            loadFileURL(url, allowingReadAccessTo: readAccessURL)
        }
    }
    
    func adjustTextSize() {
        let textFontSize = MainViewController.textFontSize()
        let jsString = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(textFontSize)%'"
        evaluateJavaScript(jsString, completionHandler:nil)
    }
    
    func fitContentToScreen() {
        let javascript = """
                var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);
                """
        evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    func applyTheme() {
        evaluateJavaScript(ThemeManager.getCSSJavascript(), completionHandler: nil)
    }
    
    private func URLStringToLocalContentPath(urlString: String ) -> String? {
        let urlArray = urlString.components(separatedBy: Constants.LOCAL_WEB_DATA_DIR)
        return urlArray.count >= 2 ? urlArray[1] : nil
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
        evaluateJavaScript(js,  completionHandler: { [unowned self] (result, error) in
            self.evaluateJavaScript("document.title", completionHandler: { [unowned self] (result, error) in
                let title = result as? String
                self.evaluateJavaScript("location.href", completionHandler: {[unowned self] (result, error) in
                    if let urlString = result as? String {
                        let location = self.URLStringToLocalContentPath(urlString: urlString)
                        self.evaluateJavaScript("document.getElementById('H_tipitakaID').innerHTML.stripHTML()", completionHandler:
                            { [unowned self] (result, error) in
                                let tipitakaID = result as? String
                                self.evaluateJavaScript("scrollX", completionHandler: {[unowned self] (result, error) in
                                    let xPos = result as? Int
                                    self.evaluateJavaScript("scrollY", completionHandler: {(result, error) in
                                        let yPos = result as? Int
                                        let bookmark = LocalBookmark(title: title!,
                                                                     location: location!,
                                                                     scrollX: xPos!,
                                                                     scrollY: yPos!)
                                        bookmark.note = tipitakaID
                                        completionHandler(bookmark)
                                    })
                                })
                                
                        })
                    }
                    else {
                        completionHandler(nil)
                    }
                })
            })
        })
    }
}
