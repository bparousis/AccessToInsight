//
//  MainViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-03.
//

import UIKit
import WebKit

class MainViewController: UIViewController, WKNavigationDelegate, UIGestureRecognizerDelegate, BookmarksControllerDelegate,
    UITextFieldDelegate, UIPopoverPresentationControllerDelegate, SearchViewDelegate
{
    
    static let nightModeNotificationName = NSNotification.Name("NightMode")
    
    var actionSheet: UIAlertController? = nil
    var toolbarHidden: Bool = false
    var bookmark: LocalBookmark? = nil
    var startAlpha: Float = 1.0
    var doneAddBookmark: UIAlertAction? = nil
    
    var topConstraint: NSLayoutConstraint? = nil
    var bottomConstraint: NSLayoutConstraint? = nil
    var rescrollX: Int = 0
    var rescrollY: Int = 0
    var needRescroll = false
    
    var webView: WKWebView? = nil
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
        
        self.toolbarHidden = false
        
        self.webView = WKWebView(frame: .zero)
        self.webView?.navigationDelegate = self
        self.webView?.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delegate = self
        tapGesture.numberOfTapsRequired = 2
        self.webView?.addGestureRecognizer(tapGesture)
        
        determineStartAlpha()
        self.webView?.isOpaque = false
        updateColorScheme()
        self.view.addSubview(self.webView!)
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            self.topConstraint = webView!.topAnchor.constraint(equalTo: guide.topAnchor)
            self.bottomConstraint = webView!.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
            NSLayoutConstraint.activate([
                self.topConstraint!,
                webView!.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                webView!.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                self.bottomConstraint!
                ])
        } else {
            let margins = view.layoutMarginsGuide
            self.topConstraint = webView!.topAnchor.constraint(equalTo: margins.topAnchor)
            self.bottomConstraint = webView!.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
            NSLayoutConstraint.activate([
                self.topConstraint!,
                webView!.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                webView!.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                self.bottomConstraint!
                ])
        }
        self.topConstraint?.isActive = true
        self.bottomConstraint?.constant = -44.0
        self.bottomConstraint?.isActive = true
        self.view.layoutIfNeeded()

        // Load the last page the user was viewing.
        // Unfortunately I don't know of a way to save and load the history.
        
        var lastLocationBookmark: LocalBookmark? = nil
        if let data = UserDefaults.standard.object(forKey: Constants.LAST_LOCATION_BOOKMARK_KEY) as? Data {
            let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
            lastLocationBookmark = unarchiver.decodeObject(forKey: Constants.BOOKMARK_KEY) as? LocalBookmark
            unarchiver.finishDecoding()
        }

        if (lastLocationBookmark != nil) {
            self.loadLocalBookmark(lastLocationBookmark!)
        } else {
            home()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func URLStringToLocalContentPath(urlString: String ) -> String? {
        let urlArray = urlString.components(separatedBy: Constants.LOCAL_WEB_DATA_DIR)
        return urlArray.count >= 2 ? urlArray[1] : nil
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webView.fitContentToScreen()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        webView.alpha = CGFloat(self.startAlpha)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        webView.alpha = CGFloat(self.startAlpha)
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
        
        self.webView?.adjustTextSize()
        if (needRescroll) {
//            if (rescrollY || rescrollX)
            self.scrollTo(x: rescrollX, y: rescrollY)
            needRescroll = false
        }
    }
    
    func scrollTo(x scrollX: Int, y scrollY: Int) {
        self.webView?.evaluateJavaScript("window.scrollTo(\(scrollX), \(scrollY))", completionHandler: nil)
    }
    
    class func textFontSize() -> Int {
        var textFontSize = 100
        if let textFontSizeNum = UserDefaults.standard.object(forKey: Constants.TEXT_FONT_SIZE_KEY) as? Int {
            textFontSize = textFontSizeNum
        }
        return textFontSize
    }
    
    func loadLocalBookmark(_ bookmark: LocalBookmark) {
        rescrollX = bookmark.scrollX
        rescrollY = bookmark.scrollY
        needRescroll = false
        self.webView?.loadLocalWebContent(bookmark.location)
    }
    
    @IBAction func home() {
        self.webView?.loadLocalWebContent("index.html")
    }
    
    @IBAction func goBack() {
        self.webView?.alpha = CGFloat(self.startAlpha)
        self.webView?.goBack()
        UIView.animate(withDuration: 1.0) {
            self.webView?.alpha = 1.0
        }
    }
    
    @IBAction func goForward() {
        self.webView?.alpha = CGFloat(self.startAlpha)
        self.webView?.goForward()
        UIView.animate(withDuration: 1.0) {
            self.webView?.alpha = 0.5
        }
    }
    
    @IBAction func actionButton() {
        self.actionSheet = UIAlertController(title: "Select Action", message: nil, preferredStyle: .actionSheet)
        
        if ThemeManager.isNightMode() {
            self.actionSheet?.view.tintColor = ThemeManager.backgroundColor()
        }
        self.actionSheet?.popoverPresentationController?.barButtonItem = self.actionBarButtonItem
        self.actionSheet?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned self] (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.actionSheet?.addAction(UIAlertAction(title: "Add Bookmark", style: .default, handler: { [unowned self] (action) in
            self.webView?.getBookmark(completionHandler: { [unowned self] (bookmark) in
                self.bookmark = bookmark
                let alert = UIAlertController(title: "Add Bookmark", message: "Enter a title for the bookmark", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { [unowned self] (textField) in
                    textField.text = self.bookmark?.title
                    textField.delegate = self
                    textField.addTarget(self, action: #selector(self.textDidChange(_:)), for: .editingChanged)
                })
                self.doneAddBookmark = UIAlertAction(title: "Done", style: .default, handler: { (action) in
                    if let addBookmark = self.bookmark, let bookmarkTitle = alert.textFields?.first?.text {
                        addBookmark.title = bookmarkTitle
                        BookmarksManager.instance.addBookmark(addBookmark)
                    }
                    
                })
                alert.addAction(self.doneAddBookmark!)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            })
        }))
        self.actionSheet?.addAction(UIAlertAction(title: "Open on Live Site", style: .default, handler: {[unowned self] (alert) in
            self.webView?.getBookmark(completionHandler: { (bookmark) in
                guard let location = bookmark?.location, let url = URL(string:"http://www.accesstoinsight.org\(location)")
                    else {
                        return
                }
                UIApplication.shared.openURL(url)
            })
        }))
        
        self.actionSheet?.addAction(UIAlertAction(title: "Random Sutta", style: .default, handler: { [unowned self] (alert) in
            self.webView?.loadLocalWebContent("random-sutta.html")
        }))
        
        self.actionSheet?.addAction(UIAlertAction(title: "Random Article", style: .default, handler: { [unowned self] (alert) in
            self.webView?.loadLocalWebContent("random-article.html")
        }))
        
        // Present action sheet.
        self.present(self.actionSheet!, animated: true, completion: nil)
    }
    
    @objc func textDidChange(_ textField: UITextField) {
        if let text = textField.text {
            self.doneAddBookmark?.isEnabled = text.count > 0
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
    
    @IBAction func showBookmarks() {
        let btc = BookmarksTableController(style: .plain)
        btc.delegate = self
    
        let nav = UINavigationController(rootViewController: btc)
        nav.navigationBar.barStyle = ThemeManager.isNightMode() ? .blackTranslucent : .default
        nav.modalPresentationStyle = .popover
        self.present(nav, animated: true, completion: nil)
    
        // configure the Popover presentation controller
        if let popController = nav.popoverPresentationController {
            popController.permittedArrowDirections = .any
            popController.barButtonItem = self.bmBarButtonItem
            popController.delegate = self
        }
    }
    
    @IBAction func showSettings() {
        let controller = SettingsViewController()
        controller.title = "Settings"
        self.navigationController?.pushViewController(controller, animated: true)
    }

    @IBAction func showSearch() {
        let controller = SearchViewController()
        controller.searchDelegate = self
        controller.title = "Search"

        let nav = UINavigationController(rootViewController: controller)
        nav.navigationBar.barStyle = ThemeManager.isNightMode() ? .blackTranslucent : .default
        self.present(nav, animated: true, completion: nil)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func loadPage(_ filePath: String) {
        self.webView?.loadLocalWebContent(filePath)
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchViewControllerCancel(_ controller: SearchViewController) {
        self.dismiss(animated: true, completion: nil)
    }

    // Need to get rid of this. Too generic.
    func settingsControllerDidFinish() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        toggleScreenDecorations()
    }
    
    func toggleScreenDecorations() {
        self.toolbarHidden = !self.toolbarHidden
        UIView.beginAnimations("toolbar", context: nil)
        if self.toolbarHidden == false {
            self.bottomConstraint?.constant = -44.0
            toolbar?.isHidden = false
        }
        else {
            self.bottomConstraint?.constant = 0.0
            toolbar?.isHidden = true
        }
        self.view.layoutIfNeeded()
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
        if notification.name == MainViewController.nightModeNotificationName {
            determineStartAlpha()
            updateColorScheme()
            self.webView?.reload()
        }
    }
    
    func determineStartAlpha() {
        self.startAlpha = ThemeManager.isNightMode() ? 0.0 : 1.0
    }
    
    func updateColorScheme() {
        ThemeManager.decorateToolbar(self.toolbar)
        self.view.backgroundColor = ThemeManager.backgroundColor()
        self.webView?.backgroundColor = ThemeManager.backgroundColor()
        self.navigationController?.navigationBar.barStyle = ThemeManager.isNightMode() ? .blackTranslucent : .default
    }
    
    func bookmarksController(_ controller: BookmarksTableController!, selectedBookmark bookmark: LocalBookmark!) {
        self.dismiss(animated: true, completion: nil)
        self.loadLocalBookmark(bookmark)
    }
    
    func bookmarksControllerCancel(_ controller: BookmarksTableController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        webView?.adjustTextSize()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
        self.saveLastLocation()
    }
    
    func prefersStatusBarHidden() -> Bool {
        return self.toolbarHidden
    }
    
    func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation
    {
        return .slide
    }
    
    func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return ThemeManager.isNightMode() ? .lightContent : .default
    }
    
    func saveLastLocation() {
        self.webView?.getBookmark { (lastLocationBookmark) in
            let data = NSMutableData()
            let archiver = NSKeyedArchiver(forWritingWith: data)
            archiver.encode(lastLocationBookmark, forKey: Constants.BOOKMARK_KEY)
            archiver.finishEncoding()
            UserDefaults.standard.set(data, forKey: Constants.LAST_LOCATION_BOOKMARK_KEY)
            UserDefaults.standard.synchronize()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
