//
//  InfoViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2019-11-24.
//

import Foundation
import UIKit
import WebKit

class InfoViewController: UIViewController {
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Info"
        view.addSubview(webView)
        anchor(to: webView)
        webView.loadLocalWebContent(Page.about)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13, *) {
            webView.reload()
        }
    }
}

extension InfoViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.decorate()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webView.fitContentToScreen()
    }
}
