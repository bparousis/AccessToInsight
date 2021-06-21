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
    static let nightModeNotificationName = NSNotification.Name("NightMode")
    
    private var toolbarHidden: Bool = false
    private var startAlpha: CGFloat = 0.0
    
    private var doneAddBookmark: UIAlertAction? = nil
    
    private var bottomConstraint: NSLayoutConstraint? = nil
    private var rescrollPosition: ScrollPosition? = nil
    
    private lazy var bookmarksManager: BookmarksManager = {
        var documentsPathURL = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask)[0]
        return BookmarksManager(storePath: documentsPathURL)
    }()

    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = .link
        if #available(iOS 13.0, *) {
            let references = WKWebpagePreferences()
            references.preferredContentMode = .mobile
            config.defaultWebpagePreferences = references
        }
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delegate = self
        tapGesture.numberOfTapsRequired = 2
        webView.addGestureRecognizer(tapGesture)
        
        webView.isOpaque = false
        return webView
    }()

    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var backButtonItem: UIBarButtonItem!
    @IBOutlet var forwardButtonItem: UIBarButtonItem!
    @IBOutlet var homeButtonItem: UIBarButtonItem!
    @IBOutlet var actionBarButtonItem: UIBarButtonItem!
    @IBOutlet var bmBarButtonItem: UIBarButtonItem!
    @IBOutlet var searchButtonItem: UIBarButtonItem!
    @IBOutlet var settingsButtonItem: UIBarButtonItem!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        addNightModeNotification()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addNightModeNotification()
    }
    
    func setupToolbarIcons() {
        if #available(iOS 13, *) {
        } else {
            backButtonItem.image = UIImage(named: "back")
            forwardButtonItem.image = UIImage(named: "forward")
            homeButtonItem.image = UIImage(named: "home")
            actionBarButtonItem.image = UIImage(named: "action")
            bmBarButtonItem.image = UIImage(named: "bookmark")
            searchButtonItem.image = UIImage(named: "search")
            settingsButtonItem.image = UIImage(named: "settings")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupToolbarIcons()
        BookmarksManager.setLocalBookmarkKeyedUnarchived()
        
        toolbarHidden = false
        updateColorScheme()
        view.addSubview(webView)
        
        let guide = view.safeAreaLayoutGuide
        let topConstraint = webView.topAnchor.constraint(equalTo: guide.topAnchor)
        let bottomConstraint = webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        self.bottomConstraint = bottomConstraint
        NSLayoutConstraint.activate([
            topConstraint,
            webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            bottomConstraint
            ])
        topConstraint.isActive = true
        bottomConstraint.constant = -44.0
        bottomConstraint.isActive = true
        view.layoutIfNeeded()
        
        if let lastLocationBookmark = AppSettings.lastLocationBookmark {
            loadLocalBookmark(lastLocationBookmark, scrollPosition: AppSettings.lastScrollPosition)
        } else {
            home()
        }
    }
    
    func scrollTo(x scrollX: Int, y scrollY: Int) {
        webView.evaluateJavaScript("window.scrollTo(\(scrollX), \(scrollY))")
    }

    func loadLocalBookmark(_ bookmark: LocalBookmark, scrollPosition: ScrollPosition? = nil) {
        if let scrollPosition = scrollPosition {
            rescrollPosition = scrollPosition
        } else {
            rescrollPosition = (bookmark.scrollX, bookmark.scrollY)
        }
        webView.loadLocalWebContent(bookmark.location)
    }
    
    @IBAction func home() {
        webView.loadLocalWebContent(.home)
    }
    
    @IBAction func goBack() {
        webView.alpha = startAlpha
        webView.goBack()
        webView.animateFade()
    }
    
    @IBAction func goForward() {
        webView.alpha = startAlpha
        webView.goForward()
        webView.animateFade()
    }
    
    @IBAction func actionButton() {
        let actionSheet = UIAlertController.makeDecoratedActionSheet(title: "Select Action")
        actionSheet.popoverPresentationController?.barButtonItem = actionBarButtonItem
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned self] (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Add Bookmark", style: .default, handler: { [unowned self] (action) in
            self.webView.getBookmark(completionHandler: { [unowned self] (bookmark) in
                let alert = UIAlertController(title: "Add Bookmark", message: "Enter a title for the bookmark", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { [unowned self] (textField) in
                    textField.text = bookmark?.title
                    textField.delegate = self
                    textField.addTarget(self, action: #selector(self.textDidChange(_:)), for: .editingChanged)
                })
                self.doneAddBookmark = UIAlertAction(title: "Done", style: .default, handler: { (action) in
                    if let addBookmark = bookmark, let bookmarkTitle = alert.textFields?.first?.text {
                        addBookmark.title = bookmarkTitle
                        self.bookmarksManager.addBookmark(addBookmark)
                    }
                })
                alert.addAction(self.doneAddBookmark!)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            })
        }))
        actionSheet.addAction(UIAlertAction(title: "Open on Live Site", style: .default, handler: {[unowned self] (alert) in
            webView.getBookmark(completionHandler: { (bookmark) in
                guard let location = bookmark?.location, let url = URL(string:"http://www.accesstoinsight.org\(location)")
                    else {
                        return
                }
                UIApplication.shared.open(url, options: [:])
            })
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Random Sutta", style: .default, handler: { [unowned self] (alert) in
            rescrollPosition = AppSettings.topScrollPosition
            webView.loadLocalWebContent(.randomSutta)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Random Article", style: .default, handler: { [unowned self] (alert) in
            rescrollPosition = AppSettings.topScrollPosition
            webView.loadLocalWebContent(.randomArticle)
        }))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    @objc func textDidChange(_ textField: UITextField) {
        if let text = textField.text {
            doneAddBookmark?.isEnabled = text.count > 0
        }
    }
    
    @IBAction func showBookmarks() {
        let btc = BookmarksTableController(bookmarksManager: bookmarksManager)
        btc.delegate = self
    
        let nav = UINavigationController.makeDecorated(rootViewController: btc)
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

        let nav = UINavigationController.makeDecorated(rootViewController: searchViewController)
        present(nav, animated: true, completion: nil)
        navigationController?.setNavigationBarHidden(true, animated: false)
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
        toolbar?.isHidden = toolbarHidden
        bottomConstraint?.constant = toolbarHidden ? 0.0 : -44.0
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
        startAlpha = 0.0
        updateColorScheme()
        webView.reload()
    }
    
    func updateColorScheme() {
        toolbar.decorate()
        view.decorateBackground()
        webView.decorateBackground()
        navigationController?.decorate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        webView.adjustTextSize()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        toolbarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .slide
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return super.preferredStatusBarStyle
        } else {
            return AppSettings.nightMode ? .lightContent : .default
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13, *) {
            webView.reload()
        }
    }
    
    func saveLastLocation() {
        webView.getBookmark { lastLocationBookmark in
            AppSettings.lastLocationBookmark = lastLocationBookmark
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

        // If you don't do this check here you can get into an infinite loop since calls like
        // loadLocalFragmentURL below will call this delegate method again, but navigationType
        // will be .other.
        guard navigationAction.navigationType != .other else {
            webView.animateFade(startAlpha: startAlpha)
            decisionHandler(.allow)
            return
        }

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.isFileURL {
            if url.fragment != nil {
                decisionHandler(.cancel)
                webView.loadLocalFragmentURL(url)
                return
            }
            webView.animateFade(startAlpha: startAlpha)
            decisionHandler(.allow)
            return
        }

        UIApplication.shared.open(url, options: [:])
        decisionHandler(.cancel)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Need to perform this way otherwise, webview might be in a state where it's not fully rendered
        // and code below, such as saveLastLocation or scrollTo doesn't work.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            webView.decorate()
            webView.animateFade()
            webView.adjustTextSize()
            if let rescrollPosition = self.rescrollPosition {
                self.scrollTo(x: rescrollPosition.x, y: rescrollPosition.y)
                self.rescrollPosition = nil
            }
            self.saveLastLocation()
        }
    }
}

extension MainViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
}

extension MainViewController: SearchViewDelegate {
    
    func loadPage(_ filePath: String) {
        webView.loadLocalWebContent(filePath)
        dismiss(animated: true)
    }
    
    func searchViewControllerCancel(_ controller: SearchViewController) {
        dismiss(animated: true)
    }
}

extension MainViewController: BookmarksTableControllerDelegate {
    func bookmarksController(_ controller: BookmarksTableController, selectedBookmark bookmark: LocalBookmark) {
        dismiss(animated: true) {
            self.loadLocalBookmark(bookmark)
        }
    }
    
    func bookmarksControllerCancel(_ controller: BookmarksTableController) {
        dismiss(animated: true)
    }
}

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        AppSettings.lastScrollPosition = (Int(scrollView.contentOffset.x), Int(scrollView.contentOffset.y))
    }
}

private extension WKWebView {
    
    func animateFade(startAlpha: CGFloat? = nil) {
        if let startAlpha = startAlpha {
            alpha = startAlpha
        }

        UIView.animate(withDuration: 0.25) { [unowned self] in
            self.alpha = 1.0
        }
    }
}
