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
        let toolbar = UIToolbar.makeDecorated()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()

    private let viewModel: TextSizeViewModel
    private var allowPageLoad = true

    init(viewModel: TextSizeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        allowPageLoad = true
        title = viewModel.title
        textSizeWebView.loadLocalWebContent(viewModel.page)

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
    }
    
    @objc func increaseFontSize(_ sender: UIBarButtonItem) {
        changeTextFontSize(increase: true)
    }
    
    @objc func decreaseFontSize(_ sender: UIBarButtonItem) {
        changeTextFontSize(increase: false)
    }
    
    @objc func resetTextFontSize(_ sender: UIBarButtonItem) {
        viewModel.resetTextFontSize()
        textSizeWebView.adjustTextSize()
    }
    
    func changeTextFontSize(increase: Bool) {
        if viewModel.changeTextFontSize(increase: increase) {
            textSizeWebView.adjustTextSize()
        }
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
        webView.decorate()
        webView.adjustTextSize()
        allowPageLoad = false
    }
}
