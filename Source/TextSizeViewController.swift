//
//  TextSizeViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import UIKit
import WebKit

class TextSizeViewController: UIViewController, WKNavigationDelegate {
    private var textSizeWebView : WKWebView?
    private var toolbar: UIToolbar?
    private var pageLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.pageLoaded = false
        self.title = "Text Size"
        let webConfig = WKWebViewConfiguration()
        self.textSizeWebView = WKWebView(frame: .zero, configuration: webConfig)
        self.textSizeWebView?.translatesAutoresizingMaskIntoConstraints = false
        self.textSizeWebView?.navigationDelegate = self
        
        var lastLocationBookmark : LocalBookmark? = nil
        
        let defaults = UserDefaults.standard
        let data = defaults.object(forKey: "lastLocationBookmark") as? Data
        if  let lastData = data {
            let unarchiver = NSKeyedUnarchiver(forReadingWith: lastData)
            lastLocationBookmark = unarchiver.decodeObject(forKey: "bookmark") as? LocalBookmark
            unarchiver.finishDecoding()
        }
        
        if let bookmarkLocation = lastLocationBookmark?.location {
            self.textSizeWebView?.loadLocalWebContent(bookmarkLocation)
        }
        else {
            self.textSizeWebView?.loadLocalWebContent("index.html")
        }
        
        self.toolbar = UIToolbar()
        self.toolbar?.translatesAutoresizingMaskIntoConstraints = false
        ThemeManager.decorateToolbar(self.toolbar)
        let increaseImage = UIImage(named: "increase_font")
        let leftFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let middleFixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        middleFixed.width = 35.0
        let rightFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let increaseButton = UIBarButtonItem(image: increaseImage, style: .plain, target: self, action: #selector(increaseFontSize(_:)))
        
        let decreaseImage = UIImage(named:"decrease_font")
        let decreaseButton = UIBarButtonItem(image: decreaseImage, style: .plain, target: self, action: #selector(decreaseFontSize(_:)))
        
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetTextFontSize(_:)))
        self.toolbar?.items = [leftFlex, decreaseButton, middleFixed, increaseButton, rightFlex, resetButton]
        
        self.view.addSubview(self.textSizeWebView!)
        self.view.addSubview(self.toolbar!)
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                textSizeWebView!.topAnchor.constraint(equalTo: guide.topAnchor),
                textSizeWebView!.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                textSizeWebView!.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                textSizeWebView!.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
                toolbar!.leadingAnchor.constraint(equalTo:guide.leadingAnchor),
                toolbar!.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                toolbar!.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
                ])
        } else {
            let margins = view.layoutMarginsGuide
            NSLayoutConstraint.activate([
                textSizeWebView!.topAnchor.constraint(equalTo: margins.topAnchor),
                textSizeWebView!.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                textSizeWebView!.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                textSizeWebView!.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
                toolbar!.leadingAnchor.constraint(equalTo:margins.leadingAnchor),
                toolbar!.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                toolbar!.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
                ])
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.textSizeWebView?.fitContentToScreen()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if pageLoaded == false {
            decisionHandler(.allow)
        }
        else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.applyTheme()
        webView.adjustTextSize()
        pageLoaded = true
    }
    
    @objc func increaseFontSize(_ sender: UIBarButtonItem) {
        changeTextFontSize(increase: true)
    }
    
    @objc func decreaseFontSize(_ sender: UIBarButtonItem) {
        changeTextFontSize(increase: false)
    }
    
    @objc func resetTextFontSize(_ sender: UIBarButtonItem) {
        let textFontSize = 100
        UserDefaults.standard.set(textFontSize, forKey: Constants.TEXT_FONT_SIZE_KEY)
        UserDefaults.standard.synchronize()
        textSizeWebView?.adjustTextSize()
    }
    
    func changeTextFontSize(increase: Bool) {
        var textFontSize = MainViewController.textFontSize()
        if increase {
            textFontSize = textFontSize < 160 ? textFontSize + 5 : textFontSize
        }
        else {
            textFontSize = textFontSize > 50 ? textFontSize - 5 : textFontSize
        }
        
        UserDefaults.standard.set(textFontSize, forKey: Constants.TEXT_FONT_SIZE_KEY)
        UserDefaults.standard.synchronize()
        textSizeWebView?.adjustTextSize()
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
