//
//  File.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import Foundation

class LocalBookmark : NSObject, NSCoding {
    
    static let titleKey = "title"
    static let locationKey = "location"
    static let scrollXKey = "scrollX"
    static let scrollYKey = "scrollY"
    static let noteKey = "note"
    
    var title: String
    var location: String
    var note: String?
    var scrollX : Int
    var scrollY : Int

    init(title: String, location: String, scrollX: Int, scrollY: Int) {
        self.title = title
        self.location = location
        self.scrollX = scrollX
        self.scrollY = scrollY
    }

    @objc func encode(with coder: NSCoder) {
        coder.encode(title, forKey: LocalBookmark.titleKey)
        coder.encode(location, forKey: LocalBookmark.locationKey)
        coder.encode(note, forKey: LocalBookmark.noteKey)
        coder.encode(scrollX, forKey: LocalBookmark.scrollXKey)
        coder.encode(scrollY, forKey: LocalBookmark.scrollYKey)
    }

    @objc required convenience init?(coder decoder: NSCoder) {
        guard let title = decoder.decodeObject(forKey: LocalBookmark.titleKey) as? String,
            let location = decoder.decodeObject(forKey: LocalBookmark.locationKey) as? String
            else { return nil }

        self.init(title: title,
                  location: location,
                  scrollX: decoder.decodeInteger(forKey: LocalBookmark.scrollXKey),
                  scrollY: decoder.decodeInteger(forKey: LocalBookmark.scrollYKey))
        self.note = decoder.decodeObject(forKey: LocalBookmark.noteKey) as? String
    }
}
