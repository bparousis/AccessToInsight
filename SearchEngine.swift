//
//  SearchEngine.swift
//  AccessToInsightTests
//
//  Created by Bill Parousis on 2021-06-16.
//

import Foundation

extension SearchEngine {
    func asyncQuery(_ query: String, type: SearchType,
                    completionHandler: @escaping ([[String:Any]])->Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let queryResults = self.query(query, type: type)
            DispatchQueue.main.async {
                completionHandler(queryResults)
            }
        }
    }
}
