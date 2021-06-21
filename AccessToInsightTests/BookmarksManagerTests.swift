//
//  BookmarksManagerTests.swift
//  AccessToInsightTests
//
//  Created by Bill Parousis on 2021-06-16.
//

import XCTest

@testable import AccessToInsight

class BookmarksManagerTests: XCTestCase {
    
    var sut: BookmarksManager!

    override func setUp() {
        Current = .mock
        sut = BookmarksManager(storePath: FileManager.default.temporaryDirectory)
    }

    override func tearDownWithError() throws {
        let documentsPathURL = FileManager.default.temporaryDirectory.appendingPathComponent("LocalBookmarks")
        if FileManager.default.fileExists(atPath: documentsPathURL.path) {
            try FileManager.default.removeItem(at: documentsPathURL)
        }
    }

    func testDefaultBookmarks() {
        XCTAssertEqual(sut.count, 5)

        let bookmark1 = sut.bookmarkAtIndex(0)
        let bookmark2 = sut.bookmarkAtIndex(1)
        let bookmark3 = sut.bookmarkAtIndex(2)
        let bookmark4 = sut.bookmarkAtIndex(3)
        let bookmark5 = sut.bookmarkAtIndex(4)

        XCTAssertEqual(bookmark1?.title, "What is Buddhism?")
        XCTAssertEqual(bookmark2?.title, "Getting Started")
        XCTAssertEqual(bookmark3?.title, "Content Help and FAQ")
        XCTAssertEqual(bookmark4?.title, "Tipitaka (Pali Canon)")
        XCTAssertEqual(bookmark5?.title, "Dhammapada")
    }

    func testAddingBookmarks() {
        let bookmark = LocalBookmark(title: "title1", location: "location1", scrollX: 0, scrollY: 0)
        sut.addBookmark(bookmark)
        XCTAssertEqual(sut.count, 6)
        
        let bookmark2 = LocalBookmark(title: "title2", location: "location2", scrollX: 0, scrollY: 0)
        let bookmark3 = LocalBookmark(title: "title3", location: "location3", scrollX: 0, scrollY: 0)
        sut.addBookmark(bookmark2)
        sut.addBookmark(bookmark3)
        XCTAssertEqual(sut.count, 8)
    }
    
    func testMovingBookmarks() {
        let bookmark1 = LocalBookmark(title: "title1", location: "location1", scrollX: 0, scrollY: 0)
        let bookmark2 = LocalBookmark(title: "title2", location: "location2", scrollX: 0, scrollY: 0)
        sut.addBookmark(bookmark1)
        sut.addBookmark(bookmark2)
        
        XCTAssertEqual(sut.bookmarkAtIndex(5)?.title, "title1")
        XCTAssertEqual(sut.bookmarkAtIndex(6)?.title, "title2")
        sut.moveBookmark(from: 5, to: 6)
        XCTAssertEqual(sut.bookmarkAtIndex(5)?.title, "title2")
        XCTAssertEqual(sut.bookmarkAtIndex(6)?.title, "title1")
        sut.moveBookmark(from: 0, to: 6)
        XCTAssertEqual(sut.bookmarkAtIndex(0)?.title, "title1")
        XCTAssertEqual(sut.bookmarkAtIndex(6)?.title, "What is Buddhism?")
        
        sut.moveBookmark(from: 0, to: 100)
        XCTAssertEqual(sut.bookmarkAtIndex(0)?.title, "title1")
    }
    
    func testDeletingBookmarks() {
        let bookmark1 = LocalBookmark(title: "title1", location: "location1", scrollX: 0, scrollY: 0)
        let bookmark2 = LocalBookmark(title: "title2", location: "location2", scrollX: 0, scrollY: 0)
        let bookmark3 = LocalBookmark(title: "title3", location: "location3", scrollX: 0, scrollY: 0)
        sut.addBookmark(bookmark1)
        sut.addBookmark(bookmark2)
        sut.addBookmark(bookmark3)
        
        XCTAssertEqual(sut.bookmarkAtIndex(6)?.title, "title2")
        XCTAssertEqual(sut.count, 8)
        sut.deleteBookmarkAtIndex(6)
        XCTAssertEqual(sut.bookmarkAtIndex(6)?.title, "title3")
        XCTAssertEqual(sut.count, 7)
        sut.deleteBookmarkAtIndex(100)
        XCTAssertEqual(sut.count, 7)
        sut.deleteBookmarkAtIndex(0)
        sut.deleteBookmarkAtIndex(0)
        sut.deleteBookmarkAtIndex(0)
        XCTAssertEqual(sut.count, 4)
    }
}
