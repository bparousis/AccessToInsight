//
//  SearchViewController.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-04.
//

import UIKit

protocol SearchViewDelegate : class {
    func loadPage(_ filePath: String)
    func searchViewControllerCancel(_ controller: SearchViewController)
}

class SearchViewController: UITableViewController {

    private let viewModel: SearchViewModel

    var searchingIndicator: UIActivityIndicatorView?
    var searchController: UISearchController
    weak var searchDelegate : SearchViewDelegate?

    init(viewModel: SearchViewModel = SearchViewModel()) {
        self.viewModel = viewModel
        searchController = UISearchController(searchResultsController: nil)
        
        super.init(nibName: nil, bundle: nil)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.scopeButtonTitles = ["Title", "Document"]
        searchController.searchBar.selectedScopeButtonIndex = AppSettings.lastSearchScopeIndex
        searchController.searchBar.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
        viewModel.searchCompleted = {
            self.searchingIndicator?.stopAnimating()
            self.searchingIndicator?.removeFromSuperview()
            self.tableView.reloadData()
        }
        tableView.decorate()
        tableView.tableFooterView = UIView()

        let cancelButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(cancel(_:)))
        navigationItem.leftBarButtonItem = cancelButtonItem
        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true
        
        navigationItem.searchController = searchController
        // Make the search bar always visible.
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    @objc func cancel(_ cancelItem: UIBarButtonItem) {
        searchDelegate?.searchViewControllerCancel(self)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections = 0
        
        if viewModel.rowCount > 0 {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        } else {
            let noDataLabel = UILabel.makeDecorated(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            if let searchTextLength = searchController.searchBar.text?.count {
                noDataLabel.text  = searchTextLength > 0 ? "No Result" : ""
            }
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
        }
    
        return numOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rowCount
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
        
        cell.clear()
        cell.decorate()
        
        switch viewModel.searchDisplayMode {
        case .recentSearches:
            cell.textLabel?.text = viewModel.recentSearch(at: indexPath.row)
        case .searchResults:
            if viewModel.isSearching {
                showSearchIndicatorInCell(cell)
            } else {
                if let searchResult = viewModel.searchResult(at: indexPath.row) {
                    cell.textLabel?.text = searchResult.title
                    
                    if isTitleSearch {
                        if let subtitle = searchResult.subtitle, !subtitle.isEmpty {
                            cell.detailTextLabel?.text = subtitle
                        }
                    } else { // document search
                        let formattedSnippet = formatSnippet(searchResult.snippet)
                        if let data = formattedSnippet.data(using: .unicode) {
                            let attrStr = try? NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                            cell.detailTextLabel?.attributedText = attrStr
                        }
                    }
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch viewModel.searchDisplayMode {
        case .recentSearches:
            return .delete
        case .searchResults:
            return .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.searchDisplayMode {
        case .recentSearches:
            if let aSearch = viewModel.recentSearch(at: indexPath.row) {
                searchController.searchBar.text = aSearch
                viewModel.requestSearch(aSearch)
            }
        case .searchResults:
            if let searchResult = viewModel.searchResult(at: indexPath.row) {
                searchDelegate?.loadPage(searchResult.filePath)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if viewModel.deleteRecentSearch(at: indexPath.row) {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
}

private extension SearchViewController {

    var isTitleSearch: Bool {
        searchController.searchBar.selectedScopeButtonIndex == 0
    }
    
    func formatSnippet(_ snippet: String) -> String {
        if #available(iOS 13.0, *) {
            let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
            return snippet.decoratedUsingHTMLFontTag(darkMode: isDarkMode)
        } else {
            return snippet.decoratedUsingHTMLFontTag()
        }
    }
    
    func showSearchIndicatorInCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        
        searchingIndicator = UIActivityIndicatorView.makeDecorated()
        cell.contentView.addSubview(searchingIndicator!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.searchingIndicator?.startAnimating()
        }
        searchingIndicator?.center = cell.contentView.center
    }
}

extension SearchViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {}
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        viewModel.searchDisplayMode = .recentSearches
        tableView.reloadData()
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        AppSettings.lastSearchScopeIndex = selectedScope
        guard let queryString = searchController.searchBar.text, !queryString.isEmpty else {
            return
        }
        viewModel.requestSearch(queryString)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let queryString = searchController.searchBar.text, !queryString.isEmpty else {
            return
        }
        viewModel.requestSearch(queryString)
    }
}

private extension String {
    func decoratedUsingHTMLFontTag(darkMode: Bool = AppSettings.nightMode) -> String {
        let color = darkMode ? "white" : "black"
        return "<font color='\(color)'>\(self)</font>"
    }
}

private extension UITableViewCell {
    func clear() {
        textLabel?.text = nil
        detailTextLabel?.text = nil
        detailTextLabel?.attributedText = nil
    }
}
