//
//  BookmarksManager.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import Foundation

class BookmarksManager: NSObject {
    private static let DefaultBookmarksPlistName = "DefaultBookmarks"
    private static let BookmarksArchiveFilename = "LocalBookmarks"
    private static let BookmarksKey = "bookmarks"
    
    private var bookmarks : Array<LocalBookmark>?
    
    @objc static let instance = BookmarksManager()
    
    private override init() {
        super.init()
        load()
    }
    
    @objc class func sharedInstance() -> BookmarksManager {
        return instance
    }
    
    private func load() {
        // Attempt to load bookmarks from file.
        
        if let archiveFilePath = archiveFilePath() {
            do {
                let data = try Data(contentsOf: archiveFilePath)
                let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
                self.bookmarks = unarchiver.decodeObject(forKey: BookmarksManager.BookmarksKey) as? Array<LocalBookmark>
                unarchiver.finishDecoding()
            }
            catch {
                loadDefaultBookmarks()
            }
        }
    }
    
    private func loadDefaultBookmarks() {
        guard let plistPath = Bundle.main.path(forResource: BookmarksManager.DefaultBookmarksPlistName, ofType: "plist"),
              let defaultBookmarks = NSArray(contentsOfFile: plistPath)
        else {
            return
        }
        
        var newBookmarks:[LocalBookmark] = []
        for obj: Any in defaultBookmarks {
            if let dict = obj as? NSDictionary {
                if let title = dict["title"] as? String, let location = dict["location"] as? String,
                    let scrollX = dict["scrollX"] as? Int, let scrollY = dict["scrollY"] as? Int {
                    let bm: LocalBookmark = LocalBookmark(title: title, location: location, scrollX: scrollX, scrollY: scrollY)
                    if let note = dict["note"] as? String {
                        bm.note = note
                    }
                    newBookmarks.append(bm)
                }
            }
        }
        self.bookmarks = newBookmarks
    }
    
    private func archiveFilePath() -> URL? {
        var documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        documentsPathURL?.appendPathComponent(BookmarksManager.BookmarksArchiveFilename)
        return documentsPathURL
    }
    
    @objc func save() {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(bookmarks, forKey: BookmarksManager.BookmarksKey)
        archiver.finishEncoding()
        if let url = archiveFilePath() {
            data.write(to: url, atomically: true)
        }
    }
    
    @objc func getCount() -> Int {
        if let count = bookmarks?.count {
            return count
        }
        else {
            return 0
        }
    }
    
    @objc func bookmarkAtIndex(_ index: Int) -> LocalBookmark? {
        return bookmarks?[index]
    }
    
    @objc func addBookmark(_ bookmark: LocalBookmark) {
        bookmarks?.append(bookmark)
        save()
    }
    
    @objc func deleteBookmarkAtIndex(_ index: Int) {
        bookmarks?.remove(at: index)
        save()
    }
    
    @objc func moveBookmarkAtIndex(_ fromIndex: Int, toIndex:Int) {
        if let bookmarkToMove = bookmarks?[fromIndex] {
            bookmarks?.remove(at: fromIndex)
            bookmarks?.insert(bookmarkToMove, at: toIndex)
            save()
        }
    }
}
