//
//  SearchEngineIntegrationTests.swift
//  AccessToInsightTests
//
//  Created by Bill Parousis on 2021-06-17.
//

import Foundation

import XCTest

@testable import AccessToInsight

class SearchEngineIntegrationTests: XCTestCase {
    
    var sut: SearchEngine!

    override func setUp() {
        Current = .mock
        sut = SearchEngine()
    }

    override func tearDownWithError() throws {}

    func testSearchTitle() {
        let expectation = XCTestExpectation(description: "Search with three results")
        sut.asyncQuery("karma", type: .title) { result in
            XCTAssertEqual(result.count, 3)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testNoResults() {
        let expectation = XCTestExpectation(description: "No results")
        sut.asyncQuery("test", type: .title) { result in
            XCTAssertEqual(result.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testNonAlphaNumericSearchResults() {
        let expectation = XCTestExpectation(description: "No results")
        sut.asyncQuery("@#^!^@%*@", type: .title) { result in
            XCTAssertEqual(result.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMultipleWords() {
        let expectation = XCTestExpectation(description: "Multiple results")
        sut.asyncQuery("Monastic Code", type: .title) { result in
            XCTAssertEqual(result.count, 61)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchDocument() {
        
        let expectation = XCTestExpectation(description: "Multiple results")
        sut.asyncQuery("Sotaapanna", type: .document) { result in
            XCTAssertEqual(result.count, 14)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
