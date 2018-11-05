//
//  SearchViewDelegate.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2018-11-04.
//

import Foundation

protocol SearchViewDelegate : class {
    func loadPage(_ filePath: String)
    func searchViewControllerCancel(_ controller: SearchViewController)
}
