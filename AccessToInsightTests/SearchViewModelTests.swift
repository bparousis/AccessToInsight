//
//  SearchViewModelTests.swift
//  AccessToInsightTests
//
//  Created by Bill Parousis on 2021-07-05.
//

import Foundation

import XCTest

@testable import AccessToInsight

class SearchViewModelTests: XCTestCase {
    
    var sut: SearchViewModel!
    var mockSearchEngine: MockSearchEngine!

    override func setUp() {
        Current = .mock
        mockSearchEngine = MockSearchEngine()
        sut = SearchViewModel(searchEngine: mockSearchEngine)
        AppSettings.recentSearches = []
    }

    override func tearDownWithError() throws {}

    func testRequestSearchWithResults() {
        
        let t1 = SearchResult(title: "title1", subtitle: "subtitle1", snippet: "snippet", filePath: "/path", rank: 0.45)
        let t2 = SearchResult(title: "title2", subtitle: "subtitle2", snippet: "snippet", filePath: "/path", rank: 0.40)
        let t3 = SearchResult(title: "title3", subtitle: "subtitle3", snippet: "snippet", filePath: "/path", rank: 0.40)
        let t4 = SearchResult(title: "title4", subtitle: "subtitle4", snippet: "snippet", filePath: "/path", rank: 0.35)
        
        let d1 = SearchResult(title: "document1", subtitle: "subtitle1", snippet: "snippet", filePath: "/path", rank: 0.45)
        let d2 = SearchResult(title: "document2", subtitle: "subtitle2", snippet: "snippet", filePath: "/path", rank: 0.40)
        
        mockSearchEngine.searchResults = [.title:    [t1, t2, t3, t4],
                                          .document: [d1, d2]]
        let expect1 = XCTestExpectation()
        
        XCTAssertEqual(AppSettings.recentSearches?.count, 0)
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 1)
            XCTAssertEqual(self.sut.searchResultsCount, 4)
            let result1 = self.sut.searchResult(at: 0)
            let result2 = self.sut.searchResult(at: 1)
            let result3 = self.sut.searchResult(at: 2)
            let result4 = self.sut.searchResult(at: 3)
            let result5 = self.sut.searchResult(at: 4)
            XCTAssertEqual("title1", result1?.title)
            XCTAssertEqual("title2", result2?.title)
            XCTAssertEqual("title3", result3?.title)
            XCTAssertEqual("title4", result4?.title)
            XCTAssertNil(result5)
            expect1.fulfill()
        }
        sut.requestSearch("title", searchType: .title)
        wait(for: [expect1], timeout: 0.5)

        let expect2 = XCTestExpectation()
        XCTAssertEqual(AppSettings.recentSearches?.count, 1)
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 2)
            XCTAssertEqual(self.sut.searchResultsCount, 2)
            let result1 = self.sut.searchResult(at: 0)
            let result2 = self.sut.searchResult(at: 1)
            XCTAssertEqual("document1", result1?.title)
            XCTAssertEqual("document2", result2?.title)
            expect2.fulfill()
        }
        sut.requestSearch("document", searchType: .document)
        wait(for: [expect2], timeout: 0.5)
    }
    
    func testRecentSearches() {
        AppSettings.recentSearches = ["search1", "search2", "search3"]
        XCTAssertEqual(sut.recentSearchesCount, 3)
        XCTAssertEqual(sut.recentSearch(at: 0), "search1")
        XCTAssertEqual(sut.recentSearch(at: 1), "search2")
        XCTAssertEqual(sut.recentSearch(at: 2), "search3")
        XCTAssertNil(sut.recentSearch(at: 3))
    }
    
    func testDeleteRecentSearch() {
        AppSettings.recentSearches = ["search1", "search2", "search3"]
        XCTAssertEqual(sut.recentSearchesCount, 3)
        XCTAssertTrue(sut.deleteRecentSearch(at: 1))
        XCTAssertEqual(sut.recentSearchesCount, 2)
        XCTAssertEqual(sut.recentSearch(at: 0), "search1")
        XCTAssertEqual(sut.recentSearch(at: 1), "search3")
        XCTAssertTrue(sut.deleteRecentSearch(at: 0))
        XCTAssertEqual(sut.recentSearchesCount, 1)
        XCTAssertEqual(sut.recentSearch(at: 0), "search3")
    }
    
    func testSwitchingSearchDisplayMode() {
        sut.searchDisplayMode = .recentSearches
        AppSettings.recentSearches = []
        XCTAssertEqual(sut.rowCount, 0)
        
        AppSettings.recentSearches = ["search1", "search2", "search3"]
        XCTAssertEqual(sut.rowCount, 3)
        
        sut.searchDisplayMode = .searchResults
        XCTAssertEqual(sut.rowCount, 0)
        
        let d1 = SearchResult(title: "document1", subtitle: "subtitle1", snippet: "snippet", filePath: "/path", rank: 0.45)
        let d2 = SearchResult(title: "document2", subtitle: "subtitle2", snippet: "snippet", filePath: "/path", rank: 0.40)
        
        mockSearchEngine.searchResults = [.document: [d1, d2]]
        let expect = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(self.sut.rowCount, 2)
            expect.fulfill()
        }
        sut.requestSearch("document", searchType: .document)
        wait(for: [expect], timeout: 0.5)
        
        sut.searchDisplayMode = .recentSearches
        XCTAssertEqual(sut.rowCount, 4)
        
        sut.searchDisplayMode = .searchResults
        XCTAssertEqual(sut.rowCount, 2)
    }
    
    func testMaxCountRecentSearches() {
        
        let d1 = SearchResult(title: "document1", subtitle: "subtitle1", snippet: "snippet", filePath: "/path", rank: 0.45)
        let d2 = SearchResult(title: "document2", subtitle: "subtitle2", snippet: "snippet", filePath: "/path", rank: 0.40)
        mockSearchEngine.searchResults = [.document: [d1, d2]]
        AppSettings.lastSearchScopeIndex = 1
        
        AppSettings.recentSearches = []
        let expect1 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 1)
            expect1.fulfill()
        }
        sut.requestSearch("s1")
        wait(for: [expect1], timeout: 0.5)
        
        let expect2 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 2)
            expect2.fulfill()
        }
        sut.requestSearch("s2")
        wait(for: [expect2], timeout: 0.5)
        
        let expect3 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 3)
            expect3.fulfill()
        }
        sut.requestSearch("s3")
        wait(for: [expect3], timeout: 0.5)
        
        let expect4 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 4)
            expect4.fulfill()
        }
        sut.requestSearch("s4")
        wait(for: [expect4], timeout: 0.5)
        
        let expect5 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 5)
            expect5.fulfill()
        }
        sut.requestSearch("s5")
        wait(for: [expect5], timeout: 0.5)
        
        let expect6 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 6)
            expect6.fulfill()
        }
        sut.requestSearch("s6")
        wait(for: [expect6], timeout: 0.5)
        
        let expect7 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 7)
            expect7.fulfill()
        }
        sut.requestSearch("s7")
        wait(for: [expect7], timeout: 0.5)
        
        let expect8 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 8)
            expect8.fulfill()
        }
        sut.requestSearch("s8")
        wait(for: [expect8], timeout: 0.5)
        
        let expect9 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 9)
            XCTAssertEqual(AppSettings.recentSearches?.first, "s9")
            XCTAssertEqual(AppSettings.recentSearches?.last, "s1")
            expect9.fulfill()
        }
        sut.requestSearch("s9")
        wait(for: [expect9], timeout: 0.5)
        
        // Max history is last 9 searches.  So on the tenth we should drop the last
        // and "s10" the newest most recent query.
        let expect10 = XCTestExpectation()
        sut.searchCompleted = {
            XCTAssertEqual(AppSettings.recentSearches?.count, 9)
            XCTAssertEqual(AppSettings.recentSearches?.first, "s10")
            XCTAssertEqual(AppSettings.recentSearches?.last, "s2")
            expect10.fulfill()
        }
        sut.requestSearch("s10")
        wait(for: [expect10], timeout: 0.5)
    }
}
