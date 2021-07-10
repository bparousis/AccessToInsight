//
//  MockSearchEngine.swift
//  AccessToInsightTests
//
//  Created by Bill Parousis on 2021-07-06.
//

import Foundation

@testable import AccessToInsight

class MockSearchEngine: SearchEngine {
    var searchResults: [SearchType: [SearchResult]] = [:]
    override func query(_ query: String, searchType: SearchType) -> [SearchResult] {
        return searchResults[searchType]!
    }
    
    override func asyncQuery(_ query: String, type: SearchType,
                    completionHandler: @escaping ([SearchResult])->Void) {
        completionHandler(searchResults[type]!)
    }
}
