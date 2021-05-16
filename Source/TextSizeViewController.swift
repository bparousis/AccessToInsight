//
//  TextSizeViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import UIKit
import WebKit

class TextSizeViewController: UIViewController  {
    private lazy var textSizeWebView : WKWebView = {
        let webConfig = WKWebViewConfiguration()
        if #available(iOS 13.0, *) {
            let preferences = WKWebpagePreferences()
            preferences.preferredContentMode = .mobile
            webConfig.defaultWebpagePreferences = preferences
        }
        let webView = WKWebView(frame: .zero, configuration: webConfig)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()

    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        ThemeManager.decorateToolbar(toolbar)
        return toolbar
    }()

    private var allowPageLoad = true

    override func viewDidLoad() {
        super.viewDidLoad()

        allowPageLoad = true
        title = "Text Size"
        var lastLocationBookmark : LocalBookmark? = nil
        
        let defaults = UserDefaults.standard
        let data = defaults.object(forKey: Constants.lastLocationBookmarkKey) as? Data
        if  let lastData = data {
            let unarchiver = NSKeyedUnarchiver(forReadingWith: lastData)
            lastLocationBookmark = unarchiver.decodeObject(forKey: Constants.bookmarkKey) as? LocalBookmark
            unarchiver.finishDecoding()
        }
        
        if let bookmarkLocation = lastLocationBookmark?.location {
            textSizeWebView.loadLocalWebContent(bookmarkLocation)
        }
        else {
            textSizeWebView.loadLocalWebContent("index.html")
        }

        let increaseImage = UIImage(named: "increase_font")
        let leftFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let middleFixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        middleFixed.width = 35.0
        let rightFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let increaseButton = UIBarButtonItem(image: increaseImage, style: .plain, target: self, action: #selector(increaseFontSize(_:)))
        
        let decreaseImage = UIImage(named:"decrease_font")
        let decreaseButton = UIBarButtonItem(image: decreaseImage, style: .plain, target: self, action: #selector(decreaseFontSize(_:)))
        
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetTextFontSize(_:)))
        toolbar.items = [leftFlex, decreaseButton, middleFixed, increaseButton, rightFlex, resetButton]
        
        view.addSubview(textSizeWebView)
        view.addSubview(toolbar)
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                textSizeWebView.topAnchor.constraint(equalTo: guide.topAnchor),
                textSizeWebView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                textSizeWebView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                textSizeWebView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
                toolbar.leadingAnchor.constraint(equalTo:guide.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                toolbar.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
                ])
        } else {
            let margins = view.layoutMarginsGuide
            NSLayoutConstraint.activate([
                textSizeWebView.topAnchor.constraint(equalTo: margins.topAnchor),
                textSizeWebView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                textSizeWebView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                textSizeWebView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
                toolbar.leadingAnchor.constraint(equalTo:margins.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                toolbar.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
                ])
        }
    }
    
    @objc func increaseFontSize(_ sender: UIBarButtonItem) {
        changeTextFontSize(increase: true)
    }
    
    @objc func decreaseFontSize(_ sender: UIBarButtonItem) {
        changeTextFontSize(increase: false)
    }
    
    @objc func resetTextFontSize(_ sender: UIBarButtonItem) {
        let textFontSize = 100
        UserDefaults.standard.set(textFontSize, forKey: Constants.textFontSizeKey)
        UserDefaults.standard.synchronize()
        textSizeWebView.adjustTextSize()
    }
    
    func changeTextFontSize(increase: Bool) {
        var textFontSize = MainViewController.textFontSize()
        if increase {
            textFontSize = textFontSize < 160 ? textFontSize + 5 : textFontSize
        }
        else {
            textFontSize = textFontSize > 50 ? textFontSize - 5 : textFontSize
        }
        
        UserDefaults.standard.set(textFontSize, forKey: Constants.textFontSizeKey)
        UserDefaults.standard.synchronize()
        textSizeWebView.adjustTextSize()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13, *) {
            allowPageLoad = true
            textSizeWebView.reload()
        }
    }
}

extension TextSizeViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        textSizeWebView.fitContentToScreen()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(allowPageLoad ? .allow : .cancel)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.applyTheme()
        webView.adjustTextSize()
        allowPageLoad = false
    }
}
