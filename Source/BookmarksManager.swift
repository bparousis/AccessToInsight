//
//  BookmarksManager.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import Foundation

class BookmarksManager {
    private static let DefaultBookmarksPlistName = "DefaultBookmarks"
    private static let BookmarksArchiveFilename = "LocalBookmarks"
    private static let BookmarksKey = "bookmarks"
    private let storePath: URL
    
    private lazy var bookmarks: [LocalBookmark] = getBookmarks()
    
    static var lastLocationBookmark: LocalBookmark? {
        AppSettings.lastLocationBookmark
    }
    
    init(storePath: URL) {
        self.storePath = storePath
    }

    func save() {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.encode(bookmarks, forKey: BookmarksManager.BookmarksKey)
        archiver.finishEncoding()
        try? archiver.encodedData.write(to: archiveFilePath, options: .atomicWrite)
    }
    
    var count: Int {
        bookmarks.count
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
        bookmarks.swapAt(fromIndex, toIndex)
        save()
    }
    
    static func setLocalBookmarkKeyedUnarchived() {
        // Needed for migration from old LocalBookmark class from Objective-C code.
        NSKeyedUnarchiver.setClass(LocalBookmark.self, forClassName: "LocalBookmark")
    }
}

private extension BookmarksManager {
    
    func getBookmarks() -> [LocalBookmark] {
        // Attempt to load bookmarks from file.
        guard FileManager.default.fileExists(atPath: archiveFilePath.path) else {
            return getDefaultBookmarks()
        }

        do {
            let data = try Data(contentsOf: archiveFilePath)
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            let archiveBookmarks = unarchiver.decodeObject(forKey: BookmarksManager.BookmarksKey) as? [LocalBookmark]
            unarchiver.finishDecoding()
            return archiveBookmarks ?? getDefaultBookmarks()
        }
        catch {
            return getDefaultBookmarks()
        }
    }

    func getDefaultBookmarks() -> [LocalBookmark] {
        guard let plistPath = Bundle.main.path(forResource: BookmarksManager.DefaultBookmarksPlistName, ofType: "plist"),
            let defaultBookmarks = NSArray(contentsOfFile: plistPath)
            else {
                return []
        }

        var newBookmarks: [LocalBookmark] = []
        for obj in defaultBookmarks {
            if let dict = obj as? Dictionary<String,Any>,
               let title = dict[LocalBookmark.titleKey] as? String,
               let location = dict[LocalBookmark.locationKey] as? String,
               let scrollX = dict[LocalBookmark.scrollXKey] as? Int,
               let scrollY = dict[LocalBookmark.scrollYKey] as? Int
            {
                let bm: LocalBookmark = LocalBookmark(title: title, location: location, scrollX: scrollX, scrollY: scrollY)
                if let note = dict[LocalBookmark.noteKey] as? String {
                    bm.note = note
                }
                newBookmarks.append(bm)
            }
        }
        return newBookmarks
    }
    
    var archiveFilePath: URL {
        storePath.appendingPathComponent(BookmarksManager.BookmarksArchiveFilename)
    }
}
