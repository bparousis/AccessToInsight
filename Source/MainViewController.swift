//
//  MainViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-03.
//

import UIKit
import WebKit

class MainViewController: UIViewController
{
    typealias ScrollPosition = (x: Int, y: Int)
    
    static let nightModeNotificationName = NSNotification.Name("NightMode")
    
    var toolbarHidden: Bool = false
    var bookmark: LocalBookmark? = nil
    var startAlpha: CGFloat = 1.0
    var doneAddBookmark: UIAlertAction? = nil
    
    var topConstraint: NSLayoutConstraint? = nil
    var bottomConstraint: NSLayoutConstraint? = nil
    var rescrollPosition: ScrollPosition? = nil
    
    var webView: WKWebView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var bmBarButtonItem: UIBarButtonItem!
    @IBOutlet var actionBarButtonItem: UIBarButtonItem!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        addNightModeNotification()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addNightModeNotification()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Needed for migration from old LocalBookmark class from Objective-C code.
        NSKeyedUnarchiver.setClass(LocalBookmark.self, forClassName: "LocalBookmark")
        
        toolbarHidden = false
        
        webView = WKWebView(frame: .zero)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delegate = self
        tapGesture.numberOfTapsRequired = 2
        webView.addGestureRecognizer(tapGesture)
        
        determineStartAlpha()
        webView.isOpaque = false
        updateColorScheme()
        view.addSubview(webView)
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            topConstraint = webView.topAnchor.constraint(equalTo: guide.topAnchor)
            bottomConstraint = webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
            NSLayoutConstraint.activate([
                topConstraint!,
                webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                bottomConstraint!
                ])
        } else {
            let margins = view.layoutMarginsGuide
            topConstraint = webView.topAnchor.constraint(equalTo: margins.topAnchor)
            bottomConstraint = webView.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
            NSLayoutConstraint.activate([
                topConstraint!,
                webView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                bottomConstraint!
                ])
        }
        topConstraint?.isActive = true
        bottomConstraint?.constant = -44.0
        bottomConstraint?.isActive = true
        view.layoutIfNeeded()

        // Load the last page the user was viewing.
        // Unfortunately I don't know of a way to save and load the history.
        
        var lastLocationBookmark: LocalBookmark? = nil
        if let data = UserDefaults.standard.object(forKey: Constants.lastLocationBookmarkKey) as? Data {
            let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
            lastLocationBookmark = unarchiver.decodeObject(forKey: Constants.bookmarkKey) as? LocalBookmark
            unarchiver.finishDecoding()
        }

        if (lastLocationBookmark != nil) {
            loadLocalBookmark(lastLocationBookmark!)
        } else {
            home()
        }
    }
    
    func scrollTo(x scrollX: Int, y scrollY: Int) {
        webView.evaluateJavaScript("window.scrollTo(\(scrollX), \(scrollY))", completionHandler: nil)
    }
    
    class func textFontSize() -> Int {
        var textFontSize = 100
        if let textFontSizeNum = UserDefaults.standard.object(forKey: Constants.textFontSizeKey) as? Int {
            textFontSize = textFontSizeNum
        }
        return textFontSize
    }
    
    func loadLocalBookmark(_ bookmark: LocalBookmark) {
        rescrollPosition = (bookmark.scrollX, bookmark.scrollY)
        webView.loadLocalWebContent(bookmark.location)
    }
    
    @IBAction func home() {
        webView.loadLocalWebContent("index.html")
    }
    
    @IBAction func goBack() {
        webView.alpha = startAlpha
        webView.goBack()
        UIView.animate(withDuration: 1.0) {
            self.webView.alpha = 1.0
        }
    }
    
    @IBAction func goForward() {
        webView.alpha = startAlpha
        webView.goForward()
        UIView.animate(withDuration: 1.0) {
            self.webView.alpha = 0.5
        }
    }
    
    @IBAction func actionButton() {
        let actionSheet = UIAlertController(title: "Select Action", message: nil, preferredStyle: .actionSheet)
        ThemeManager.decorateActionSheet(actionSheet)
        actionSheet.popoverPresentationController?.barButtonItem = actionBarButtonItem
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned self] (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Add Bookmark", style: .default, handler: { [unowned self] (action) in
            self.webView.getBookmark(completionHandler: { [unowned self] (bookmark) in
                self.bookmark = bookmark
                let alert = UIAlertController(title: "Add Bookmark", message: "Enter a title for the bookmark", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { [unowned self] (textField) in
                    textField.text = bookmark?.title
                    textField.delegate = self
                    textField.addTarget(self, action: #selector(self.textDidChange(_:)), for: .editingChanged)
                })
                self.doneAddBookmark = UIAlertAction(title: "Done", style: .default, handler: { (action) in
                    if let addBookmark = bookmark, let bookmarkTitle = alert.textFields?.first?.text {
                        addBookmark.title = bookmarkTitle
                        BookmarksManager.instance.addBookmark(addBookmark)
                    }
                    
                })
                alert.addAction(self.doneAddBookmark!)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            })
        }))
        actionSheet.addAction(UIAlertAction(title: "Open on Live Site", style: .default, handler: {[unowned self] (alert) in
            self.webView.getBookmark(completionHandler: { (bookmark) in
                guard let location = bookmark?.location, let url = URL(string:"http://www.accesstoinsight.org\(location)")
                    else {
                        return
                }
                UIApplication.shared.openURL(url)
            })
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Random Sutta", style: .default, handler: { [unowned self] (alert) in
            self.webView.loadLocalWebContent("random-sutta.html")
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Random Article", style: .default, handler: { [unowned self] (alert) in
            self.webView.loadLocalWebContent("random-article.html")
        }))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    @objc func textDidChange(_ textField: UITextField) {
        if let text = textField.text {
            doneAddBookmark?.isEnabled = text.count > 0
        }
    }
    
    @IBAction func showBookmarks() {
        let btc = BookmarksTableController(style: .plain)
        btc.delegate = self
    
        let nav = UINavigationController(rootViewController: btc)
        ThemeManager.decorateNavigationController(nav)
        nav.modalPresentationStyle = .popover
        present(nav, animated: true, completion: nil)
    
        // configure the Popover presentation controller
        if let popController = nav.popoverPresentationController {
            popController.permittedArrowDirections = .any
            popController.barButtonItem = bmBarButtonItem
        }
    }
    
    @IBAction func showSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @IBAction func showSearch() {
        let searchViewController = SearchViewController()
        searchViewController.searchDelegate = self

        let nav = UINavigationController(rootViewController: searchViewController)
        ThemeManager.decorateNavigationController(nav)
        present(nav, animated: true, completion: nil)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func loadPage(_ filePath: String) {
        webView.loadLocalWebContent(filePath)
        dismiss(animated: true, completion: nil)
    }
    
    // Need to get rid of this. Too generic.
    func settingsControllerDidFinish() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        toggleScreenDecorations()
    }
    
    func toggleScreenDecorations() {
        toolbarHidden.toggle()
        UIView.beginAnimations("toolbar", context: nil)
        
        if toolbarHidden {
            bottomConstraint?.constant = 0.0
            toolbar?.isHidden = true
        } else {
            bottomConstraint?.constant = -44.0
            toolbar?.isHidden = false
        }
        view.layoutIfNeeded()
        UIView.commitAnimations()
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    func addNightModeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(nightModeNotification(_:)),
                                               name: MainViewController.nightModeNotificationName, object: nil)
    }
    
    @objc func nightModeNotification(_ notification:NSNotification)
    {
        guard notification.name == MainViewController.nightModeNotificationName else { return }
        determineStartAlpha()
        updateColorScheme()
        webView.reload()
    }
    
    func determineStartAlpha() {
        startAlpha = ThemeManager.webViewAlpha
    }
    
    func updateColorScheme() {
        ThemeManager.decorateToolbar(toolbar)
        ThemeManager.decorateView(view)
        ThemeManager.decorateView(webView)
        ThemeManager.decorateNavigationController(navigationController)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        webView.adjustTextSize()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
        saveLastLocation()
    }
    
    override var prefersStatusBarHidden: Bool {
        return toolbarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.preferredStatusBarStyle
    }
    
    func saveLastLocation() {
        webView.getBookmark { (lastLocationBookmark) in
            let data = NSMutableData()
            let archiver = NSKeyedArchiver(forWritingWith: data)
            archiver.encode(lastLocationBookmark, forKey: Constants.bookmarkKey)
            archiver.finishEncoding()
            UserDefaults.standard.set(data, forKey: Constants.lastLocationBookmarkKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MainViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webView.fitContentToScreen()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        webView.alpha = startAlpha
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        webView.alpha = startAlpha
        UIView.animate(withDuration: 1.0) {
            [unowned webView] in
            webView.alpha = 1.0
        }
        
        if navigationAction.navigationType == .other {
            decisionHandler(.allow)
            return
        }
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        if let scheme = url.scheme {
            if scheme == "file" {
                decisionHandler(.allow)
                return
            }
        }
        
        if !UIApplication.shared.canOpenURL(url) {
            decisionHandler(.cancel)
            return
        }
        UIApplication.shared.openURL(url)
        decisionHandler(.cancel)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.applyTheme()
        UIView.animate(withDuration: 1.0) {
            [unowned webView] in
            webView.alpha = 1.0
        }
        
        webView.adjustTextSize()
        if let rescrollPosition = rescrollPosition {
            scrollTo(x: rescrollPosition.x, y: rescrollPosition.y)
            self.rescrollPosition = nil
        }
    }
}

extension MainViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
}

extension MainViewController: SearchViewDelegate {
    func searchViewControllerCancel(_ controller: SearchViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension MainViewController: BookmarksControllerDelegate {
    func bookmarksController(_ controller: BookmarksTableController!, selectedBookmark bookmark: LocalBookmark!) {
        dismiss(animated: true, completion: nil)
        loadLocalBookmark(bookmark)
    }
    
    func bookmarksControllerCancel(_ controller: BookmarksTableController!) {
        dismiss(animated: true, completion: nil)
    }
}

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
