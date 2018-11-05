//
//  File.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-02.
//

import Foundation

class LocalBookmark : NSObject, NSCoding {
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
        coder.encode(title, forKey: "title")
        coder.encode(location, forKey: "location")
        coder.encode(note, forKey:"note")
        coder.encode(scrollX, forKey:"scrollX")
        coder.encode(scrollY, forKey:"scrollY")
    }

    @objc required convenience init?(coder decoder: NSCoder) {
        guard let title = decoder.decodeObject(forKey:"title") as? String,
            let location = decoder.decodeObject(forKey:"location") as? String
            else { return nil }

        self.init(title: title,
                  location: location,
                  scrollX: decoder.decodeInteger(forKey: "scrollX"),
                  scrollY: decoder.decodeInteger(forKey: "scrollY"))
        self.note = decoder.decodeObject(forKey:"note") as? String
    }
}
