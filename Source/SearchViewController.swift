//
//  SearchViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-04.
//

import UIKit

class SearchViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    static let recentSearchesKey = "recentSearches"
    static let lastSearchScopeIndexKey = "lastSearchScopeIndex"
    var searchEngine: SearchEngine?
    var tableData: [Any] = []
    var showRecentSearches = true
    var searchTimer: Timer? = nil
    var isSearching = false
    var searchingIndicator: UIActivityIndicatorView?
    var searchController: UISearchController?
    weak var searchDelegate : SearchViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.isSearching = false
        self.searchTimer = nil
        self.showRecentSearches = true
        self.tableView.backgroundColor = ThemeManager.backgroundColor()
        
        let cancelButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(cancel(_:)))
        self.navigationItem.leftBarButtonItem = cancelButtonItem
        
        if let recentSearches = UserDefaults.standard.stringArray(forKey: SearchViewController.recentSearchesKey) {
            self.tableData = recentSearches
        }
        
        let lastSearchScopeIndex = UserDefaults.standard.integer(forKey: SearchViewController.lastSearchScopeIndexKey)
        self.searchEngine = SearchEngine()
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchResultsUpdater = self
        self.searchController?.dimsBackgroundDuringPresentation = false
        self.searchController?.searchBar.sizeToFit()
        self.searchController?.searchBar.scopeButtonTitles = ["Title", "Document"]
        self.searchController?.searchBar.selectedScopeButtonIndex = lastSearchScopeIndex
        self.searchController?.searchBar.delegate = self
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        
        self.tableView.tableHeaderView = self.searchController?.searchBar
    }
    
    @objc func cancel(_ cancelItem: UIBarButtonItem) {
        self.searchDelegate?.searchViewControllerCancel(self)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.requestSearch()
    }
    
    func requestSearch() {
        if self.searchTimer != nil {
            self.searchTimer?.invalidate()
            self.searchTimer = nil
        }
        self.searchTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(performSearch),
                                                userInfo: nil, repeats: false)
    }
    
    func isTitleSearch() -> Bool {
        return self.searchController?.searchBar.selectedScopeButtonIndex == 0
    }
    
    private func updateRecentSearches(_ newQuery: String) {
        if let recentSearches = UserDefaults.standard.stringArray(forKey: SearchViewController.recentSearchesKey) {
            let containsQuery = recentSearches.contains(where: { (elem) -> Bool in
                return elem == newQuery
            })
            
            if (!containsQuery) {
                var newSearches = recentSearches
                if (newSearches.count >= 9) {
                    newSearches.removeLast()
                }
                newSearches.insert(newQuery, at: 0)
                UserDefaults.standard.set(newSearches, forKey: SearchViewController.recentSearchesKey)
                UserDefaults.standard.synchronize()
            }
        }
        else {
            UserDefaults.standard.set([newQuery], forKey: SearchViewController.recentSearchesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    @objc func performSearch() {
        guard let queryString = self.searchController?.searchBar.text else {
            return
        }
        
        if (queryString.count > 1) {
            updateRecentSearches(queryString)
            let scopeIndex = self.searchController?.searchBar.selectedScopeButtonIndex
            let scopeType = self.searchController?.searchBar.scopeButtonTitles?[scopeIndex!]
            self.isSearching = true
            self.tableData = []
            self.tableView.reloadData()

            DispatchQueue.global(qos: .userInitiated).async {
                let queryResults = self.searchEngine?.query(queryString, type: scopeType)
                DispatchQueue.main.async {
                    [unowned self] in
                    self.isSearching = false
                    self.searchingIndicator?.stopAnimating()
                    self.searchingIndicator?.removeFromSuperview()
                    self.showRecentSearches = false
                    if let data = queryResults as? [Dictionary<String,Any>] {
                        self.tableData = data
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.showRecentSearches = true
        if let recentSearches = UserDefaults.standard.stringArray(forKey: SearchViewController.recentSearchesKey) {
           self.tableData = recentSearches
        }
        self.tableView.reloadData()
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        UserDefaults.standard.set(selectedScope, forKey: SearchViewController.lastSearchScopeIndexKey)
        UserDefaults.standard.synchronize()
        self.requestSearch()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections = 0
        
        if self.tableData.count > 0 || self.showRecentSearches || self.isSearching
        {
            self.tableView.separatorStyle = .singleLine
            numOfSections = 1
            self.tableView.backgroundView = nil
        }
        else
        {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: self.tableView.bounds.height))
            if let searchTextLength = self.searchController?.searchBar.text?.count {
                noDataLabel.text  = searchTextLength > 0 ? "No Result" : ""
            }
            noDataLabel.textColor        = ThemeManager.isNightMode() ? UIColor.white: UIColor.black
            noDataLabel.textAlignment    = .center
            self.tableView.backgroundView = noDataLabel
            self.tableView.separatorStyle = .none
        }
    
        return numOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.isSearching ? 1 : self.tableData.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell") else {
                // Never fails:
                return UITableViewCell(style: .subtitle, reuseIdentifier: "SearchCell")
            }
            return cell
        }()
        
        var startFontTag : String
        ThemeManager.decorateTableCell(cell)
        if ThemeManager.isNightMode() {
            cell.backgroundColor = UIColor.clear
            startFontTag = "<font color='white'>"
        }
        else {
            startFontTag = "<font color='black'>"
        }
    
        if self.isSearching {
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            let style : UIActivityIndicatorView.Style = ThemeManager.isNightMode() ? .white : .gray
            
            self.searchingIndicator = UIActivityIndicatorView(style: style)
            cell.contentView.addSubview(self.searchingIndicator!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.searchingIndicator?.startAnimating()
            }
            self.searchingIndicator?.center = cell.contentView.center
        }
        else if self.showRecentSearches {
            if let aSearch = self.tableData[indexPath.row] as? String {
                cell.textLabel?.text = aSearch
            }
            else {
                cell.textLabel?.text = nil
            }
            cell.detailTextLabel?.text = nil
            cell.detailTextLabel?.attributedText = nil
        }
        else {
            if indexPath.row < self.tableData.count {
                if let resultData = self.tableData[indexPath.row] as? Dictionary<String,Any> {
                    let subtitle = resultData["subtitle"] as? String
                    let snippet = resultData["snippet"] as! String
                    let formattedSnippet = "\(startFontTag)\(snippet)</font>"
                    if let data = formattedSnippet.data(using: .unicode) {
                        do {
                            let attrStr = try NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                            cell.textLabel?.text = resultData["title"] as? String
                            if self.isTitleSearch() && subtitle != nil && subtitle!.count > 0 {
                                cell.detailTextLabel?.text = subtitle
                            }
                            else {
                                cell.detailTextLabel?.attributedText = self.isTitleSearch() ? nil : attrStr
                            }
                        } catch {}
                    }
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return self.showRecentSearches ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.showRecentSearches {
            if let aSearch = self.tableData[indexPath.row] as? String {
                self.searchController?.searchBar.text = aSearch
                self.performSearch()
            }
        }
        else {
            if let resultData = self.tableData[indexPath.row] as? Dictionary<String,Any>,
                let filePath = resultData["filePath"] as? String {
                self.searchDelegate?.loadPage(filePath)
            }
            
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var recentSearches = self.tableData
            recentSearches.remove(at: indexPath.row)
            self.tableData = recentSearches
            UserDefaults.standard.set(recentSearches, forKey: SearchViewController.recentSearchesKey)
            UserDefaults.standard.synchronize()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
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
