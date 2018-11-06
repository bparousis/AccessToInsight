//
//  File.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-03.
//

import Foundation

protocol BookmarksControllerDelegate : class {
    func bookmarksController(_ controller: BookmarksTableController!, selectedBookmark:LocalBookmark!)

    func bookmarksControllerCancel(_ controller: BookmarksTableController!)
}
