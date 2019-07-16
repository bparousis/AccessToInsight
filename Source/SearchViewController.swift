//
//  SearchViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-04.
//

import UIKit

class SearchViewController: UITableViewController {
    
    static let recentSearchesKey = "recentSearches"
    static let lastSearchScopeIndexKey = "lastSearchScopeIndex"
    lazy var searchEngine: SearchEngine = {
       return SearchEngine()
    }()
    
    var tableData: [Any] = []
    var showRecentSearches = true
    var searchTimer: Timer? = nil
    var isSearching = false
    var searchingIndicator: UIActivityIndicatorView?
    var searchController: UISearchController!
    weak var searchDelegate : SearchViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        isSearching = false
        searchTimer = nil
        showRecentSearches = true
        tableView.backgroundColor = ThemeManager.backgroundColor()
        
        let cancelButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(cancel(_:)))
        navigationItem.leftBarButtonItem = cancelButtonItem
        
        if let recentSearches = UserDefaults.standard.stringArray(forKey: SearchViewController.recentSearchesKey) {
            tableData = recentSearches
        }
        
        let lastSearchScopeIndex = UserDefaults.standard.integer(forKey: SearchViewController.lastSearchScopeIndexKey)
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.scopeButtonTitles = ["Title", "Document"]
        searchController.searchBar.selectedScopeButtonIndex = lastSearchScopeIndex
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true
        
        tableView.tableHeaderView = searchController.searchBar
    }
    
    @objc func cancel(_ cancelItem: UIBarButtonItem) {
        searchDelegate?.searchViewControllerCancel(self)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections = 0
        
        if tableData.count > 0 || showRecentSearches || isSearching
        {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        }
        else
        {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            if let searchTextLength = searchController.searchBar.text?.count {
                noDataLabel.text  = searchTextLength > 0 ? "No Result" : ""
            }
            noDataLabel.textColor        = ThemeManager.isNightMode() ? UIColor.white: UIColor.black
            noDataLabel.textAlignment    = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
        }
    
        return numOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? 1 : tableData.count
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
    
        if isSearching {
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            let style : UIActivityIndicatorView.Style = ThemeManager.isNightMode() ? .white : .gray
            
            searchingIndicator = UIActivityIndicatorView(style: style)
            cell.contentView.addSubview(searchingIndicator!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.searchingIndicator?.startAnimating()
            }
            searchingIndicator?.center = cell.contentView.center
        }
        else if showRecentSearches {
            if let aSearch = tableData[indexPath.row] as? String {
                cell.textLabel?.text = aSearch
            }
            else {
                cell.textLabel?.text = nil
            }
            cell.detailTextLabel?.text = nil
            cell.detailTextLabel?.attributedText = nil
        }
        else {
            if indexPath.row < tableData.count {
                if let resultData = tableData[indexPath.row] as? Dictionary<String,Any> {
                    let subtitle = resultData["subtitle"] as? String
                    let snippet = resultData["snippet"] as! String
                    let formattedSnippet = "\(startFontTag)\(snippet)</font>"
                    if let data = formattedSnippet.data(using: .unicode) {
                        do {
                            let attrStr = try NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                            cell.textLabel?.text = resultData["title"] as? String
                            if isTitleSearch() && subtitle != nil && subtitle!.count > 0 {
                                cell.detailTextLabel?.text = subtitle
                            }
                            else {
                                cell.detailTextLabel?.attributedText = isTitleSearch() ? nil : attrStr
                            }
                        } catch {}
                    }
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return showRecentSearches ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if showRecentSearches {
            if let aSearch = tableData[indexPath.row] as? String {
                searchController.searchBar.text = aSearch
                performSearch()
            }
        }
        else {
            if let resultData = tableData[indexPath.row] as? Dictionary<String,Any>,
                let filePath = resultData["filePath"] as? String {
                searchDelegate?.loadPage(filePath)
            }
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var recentSearches = tableData
            recentSearches.remove(at: indexPath.row)
            tableData = recentSearches
            UserDefaults.standard.set(recentSearches, forKey: SearchViewController.recentSearchesKey)
            UserDefaults.standard.synchronize()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

private extension SearchViewController {
    @objc func performSearch() {
        guard let queryString = searchController.searchBar.text, queryString.count > 1 else {
            return
        }
        
        updateRecentSearches(queryString)
        let scopeIndex = searchController.searchBar.selectedScopeButtonIndex
        let scopeType = searchController.searchBar.scopeButtonTitles?[scopeIndex]
        isSearching = true
        tableData = []
        tableView.reloadData()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let queryResults = self.searchEngine.query(queryString, type: scopeType)
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
    
    func updateRecentSearches(_ newQuery: String) {
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
    
    func requestSearch() {
        if searchTimer != nil {
            searchTimer?.invalidate()
            searchTimer = nil
        }
        searchTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(performSearch),
                                           userInfo: nil, repeats: false)
    }
    
    func isTitleSearch() -> Bool {
        return searchController.searchBar.selectedScopeButtonIndex == 0
    }
}

extension SearchViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {}
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        showRecentSearches = true
        if let recentSearches = UserDefaults.standard.stringArray(forKey: SearchViewController.recentSearchesKey) {
            tableData = recentSearches
        }
        tableView.reloadData()
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        UserDefaults.standard.set(selectedScope, forKey: SearchViewController.lastSearchScopeIndexKey)
        UserDefaults.standard.synchronize()
        requestSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        requestSearch()
    }
}
