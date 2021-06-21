//
//  TextSizeViewModel.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2021-06-20.
//

import Foundation

struct TextSizeViewModel {
    
    private let textSizeRange: ClosedRange<Int>
    private let changeSize = 5
    let title = "Text Size"

    var page: String {
        guard let bookmarkLocation = AppSettings.lastLocationBookmark?.location else {
            return Page.home.rawValue
        }
        return bookmarkLocation
    }
    
    init(textSizeRange: ClosedRange<Int> = 50...160) {
        self.textSizeRange = textSizeRange
    }

    /// Increase or decrease text font size.
    /// Return value: True if text font size is changed.  Otherwise, false.
    @discardableResult func changeTextFontSize(increase: Bool) -> Bool {
        let newTextFontSize = increase ? AppSettings.textFontSize + changeSize :
                                         AppSettings.textFontSize - changeSize
        if textSizeRange.contains(newTextFontSize) {
            AppSettings.textFontSize = newTextFontSize
            return true
        }
        return false
    }
    
    func resetTextFontSize() {
        AppSettings.resetTextFontSize()
    }
}
