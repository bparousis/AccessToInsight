//
//  SearchViewModel.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2021-06-26.
//

import Foundation

enum SearchDisplayMode {
    case recentSearches
    case searchResults
}

// This class isn't using data binding as you'd expect wtih view model, but this is just temporary
// before switching to SwiftUI where there will be proper binding using Combine.
class SearchViewModel {
    private let searchEngine: SearchEngine
    let title = "Search"
    private var recentSearches: [String]? {
        set {
            AppSettings.recentSearches = newValue
        }

        get {
            AppSettings.recentSearches
        }
    }

    var searchCompleted: (()->Void)?
    var willPerformSearch: (()->Void)?
    
    private let maxCountRecentSearches = 9
    
    private(set) var isSearching: Bool = false
    var searchDisplayMode: SearchDisplayMode = .recentSearches
    
    private var searchResults: [SearchResult] = []
    private var searchTimer: Timer? = nil
    
    var searchResultsCount: Int {
        searchResults.count
    }
    
    var recentSearchesCount: Int {
        recentSearches?.count ?? 0
    }
    
    var rowCount: Int {
        switch searchDisplayMode {
        case .recentSearches:
            return recentSearchesCount
        case .searchResults:
            return isSearching ? 1 : searchResultsCount
        }
    }
    
    init(searchEngine: SearchEngine = SearchEngine()) {
        self.searchEngine = searchEngine
    }
    
    func searchResult(at index: Int) -> SearchResult? {
        searchResults.indices.contains(index) ? searchResults[index] : nil
    }
    
    func recentSearch(at index: Int) -> String? {
        guard let recentSearches = recentSearches else {
            return nil
        }
        return recentSearches.indices.contains(index) ? recentSearches[index] : nil
    }
    
    func deleteRecentSearch(at index: Int) -> Bool {
        if var recentSearches = recentSearches, recentSearches.indices.contains(index) {
            recentSearches.remove(at: index)
            self.recentSearches = recentSearches
            return true
        }
        return false
    }
    
    func requestSearch(_ query: String, searchType: SearchType = AppSettings.searchType) {
        if searchTimer != nil {
            searchTimer?.invalidate()
            searchTimer = nil
        }
        let userInfo: [String: Any] = ["query": query, "searchType": searchType]
        searchTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(performSearch), userInfo: userInfo, repeats: false)
    }
}

private extension SearchViewModel {
    @objc func performSearch(sender: Timer) {
        guard let userInfo = sender.userInfo as? [String: Any],
              let query = userInfo["query"] as? String,
              let searchType = userInfo["searchType"] as? SearchType
        else {
            return
        }
        
        updateRecentSearches(query)
        searchDisplayMode = .searchResults
        searchResults.removeAll()
        isSearching = true
        willPerformSearch?()

        searchEngine.asyncQuery(query, type: searchType) { result in
            self.searchResults = result
            self.isSearching = false
            self.searchCompleted?()
        }
    }
    
    func updateRecentSearches(_ query: String) {
        if let recentSearches = AppSettings.recentSearches {
            if !recentSearches.contains(query) {
                var newSearches = recentSearches
                if newSearches.count >= maxCountRecentSearches {
                    newSearches.removeLast()
                }
                newSearches.insert(query, at: 0)
                AppSettings.recentSearches = newSearches
            }
        }
        else {
            AppSettings.recentSearches = [query]
        }
    }
}
