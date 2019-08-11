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
    
    private var bookmarks: [LocalBookmark] = []
    
    static var lastLocationBookmark: LocalBookmark? {
        var lastLocationBookmark: LocalBookmark?
        if let data = UserDefaults.standard.object(forKey: Constants.lastLocationBookmarkKey) as? Data {
            let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
            lastLocationBookmark = unarchiver.decodeObject(forKey: Constants.bookmarkKey) as? LocalBookmark
            unarchiver.finishDecoding()
        }
        return lastLocationBookmark
    }
    
    override init() {
        super.init()
        load()
    }
    
    func save() {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(bookmarks, forKey: BookmarksManager.BookmarksKey)
        archiver.finishEncoding()
        if let url = archiveFilePath() {
            data.write(to: url, atomically: true)
        }
    }
    
    func getCount() -> Int {
        return bookmarks.count
    }
    
    func bookmarkAtIndex(_ index: Int) -> LocalBookmark? {
        guard bookmarks.indices.contains(index) else { return nil }
        return bookmarks[index]
    }
    
    func addBookmark(_ bookmark: LocalBookmark) {
        bookmarks.append(bookmark)
        save()
    }
    
    func deleteBookmarkAtIndex(_ index: Int) {
        guard bookmarks.indices.contains(index) else { return }
        bookmarks.remove(at: index)
        save()
    }
    
    func moveBookmark(from fromIndex: Int, to toIndex:Int) {
        guard bookmarks.indices.contains(fromIndex) && bookmarks.indices.contains(toIndex) else {
            return
        }
        
        let bookmarkToMove = bookmarks[fromIndex]
        bookmarks.remove(at: fromIndex)
        bookmarks.insert(bookmarkToMove, at: toIndex)
        save()
    }
    
    static func setLocalBookmarkKeyedUnarchived() {
        // Needed for migration from old LocalBookmark class from Objective-C code.
        NSKeyedUnarchiver.setClass(LocalBookmark.self, forClassName: "LocalBookmark")
    }
}

private extension BookmarksManager {
    
    func load() {
        // Attempt to load bookmarks from file.
        
        if let archiveFilePath = archiveFilePath() {
            do {
                let data = try Data(contentsOf: archiveFilePath)
                let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
                if let archiveBookmarks = unarchiver.decodeObject(forKey: BookmarksManager.BookmarksKey) as? [LocalBookmark] {
                    self.bookmarks = archiveBookmarks
                }
                unarchiver.finishDecoding()
            }
            catch {
                loadDefaultBookmarks()
            }
        }
    }

    func loadDefaultBookmarks() {
        guard let plistPath = Bundle.main.path(forResource: BookmarksManager.DefaultBookmarksPlistName, ofType: "plist"),
            let defaultBookmarks = NSArray(contentsOfFile: plistPath)
            else {
                return
        }
        
        var newBookmarks:[LocalBookmark] = []
        for obj: Any in defaultBookmarks {
            if let dict = obj as? Dictionary<String,Any> {
                if let title = dict[LocalBookmark.titleKey] as? String, let location = dict[LocalBookmark.locationKey] as? String,
                    let scrollX = dict[LocalBookmark.scrollXKey] as? Int, let scrollY = dict[LocalBookmark.scrollYKey] as? Int {
                    let bm: LocalBookmark = LocalBookmark(title: title, location: location, scrollX: scrollX, scrollY: scrollY)
                    if let note = dict[LocalBookmark.noteKey] as? String {
                        bm.note = note
                    }
                    newBookmarks.append(bm)
                }
            }
        }
        bookmarks = newBookmarks
    }
    
    func archiveFilePath() -> URL? {
        var documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        documentsPathURL?.appendPathComponent(BookmarksManager.BookmarksArchiveFilename)
        return documentsPathURL
    }
}
