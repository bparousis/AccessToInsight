//
//  TextSizeViewModelTests.swift
//  AccessToInsightTests
//
//  Created by Bill Parousis on 2021-06-20.
//

import Foundation

import XCTest

@testable import AccessToInsight

class TextSizeViewModelTests: XCTestCase {
    
    var sut: TextSizeViewModel!

    override func setUp() {
        Current = .mock
        sut = TextSizeViewModel(textSizeRange: 50...150)
    }

    override func tearDownWithError() throws {
    }
    
    func testPage() {
        AppSettings.lastLocationBookmark = nil
        XCTAssertEqual(sut.page, "index.html")
        
        AppSettings.lastLocationBookmark = LocalBookmark(title: "testTitle",
                                                         location: "testLocation.html",
                                                         scrollX: 0, scrollY: 0)
        XCTAssertEqual(sut.page, "testLocation.html")
    }

    func testIncreaseFontSize() {
        AppSettings.resetTextFontSize()
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 105)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 110)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 115)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 120)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 125)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 130)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 135)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 140)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 145)
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 150) // Should reach max here.
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 150) // Shouldn't increase since maxed.
        
        AppSettings.resetTextFontSize()
        sut.changeTextFontSize(increase: true)
        XCTAssertEqual(AppSettings.textFontSize, 105)
    }
    
    func testDecresaseFontSize() {
        AppSettings.resetTextFontSize()
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 95)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 90)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 85)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 80)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 75)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 70)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 65)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 60)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 55)
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 50) // Should reach max here.
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 50) // Shouldn't increase since maxed.
        
        AppSettings.resetTextFontSize()
        sut.changeTextFontSize(increase: false)
        XCTAssertEqual(AppSettings.textFontSize, 95)
    }
}
