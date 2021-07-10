//
//  SearchEngine.swift
//  AccessToInsightTests
//
//  Created by Bill Parousis on 2021-06-16.
//

import Foundation
import SQLite3

enum SearchType {
    case title
    case document
    
    var column: String {
        switch self {
        case .title:
            return "title"
        case .document:
            return "Page"
        }
    }
}

struct SearchResult {
    let title: String
    let subtitle: String?
    let snippet: String
    let filePath: String
    let rank: Double
}

class SearchEngine {
    lazy var cache: NSCache<NSString,NSArray> = {
        var cache = NSCache<NSString,NSArray>()
        cache.countLimit = 4
        return cache
    }()
    
    func query(_ query: String, searchType: SearchType) -> [SearchResult] {
        
        let cacheKey = "\(query)\(searchType)" as NSString
        if let cacheResults = cache.object(forKey: cacheKey) as? [SearchResult] {
            return cacheResults
        }

        var results: [SearchResult] = []
        guard let dbPath = Bundle.main.path(forResource: "pages", ofType: "db") as NSString? else {
            return results
        }

        let selectStatement = "SELECT title, subtitle, snippet(Page), filePath, matchinfo(Page) FROM Page WHERE \(searchType.column) MATCH ?" as NSString
        
        var sqlStmt: OpaquePointer? = nil
        var database: OpaquePointer? = nil
        if sqlite3_open(dbPath.utf8String, &database) == SQLITE_OK {
            if sqlite3_prepare_v2(database, selectStatement.utf8String, -1, &sqlStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(sqlStmt, 1, (query as NSString).utf8String, -1, nil)
                while sqlite3_step(sqlStmt) == SQLITE_ROW {
                    let title = String(cString: sqlite3_column_text(sqlStmt, 0))
                    var subtitle: String?
                    if let subtitleCString = sqlite3_column_text(sqlStmt, 1) {
                        subtitle = String(cString: subtitleCString)
                    }
                    let snippet = String(cString: sqlite3_column_text(sqlStmt, 2))
                    let filePath = String(cString: sqlite3_column_text(sqlStmt, 3))
                    
                    var rank: Double = 0
                    if let matchInfo = sqlite3_column_blob(sqlStmt, 4) {
                        let matchInfoPtr = matchInfo.assumingMemoryBound(to: UInt32.self)
                        rank = rankFunc(UnsafeMutablePointer<UInt32>(mutating: matchInfoPtr))
                    }

                    let searchResult = SearchResult(title: title, subtitle: subtitle, snippet: snippet, filePath: filePath, rank: rank)
                    results.append(searchResult)
                }
            }
            sqlite3_finalize(sqlStmt)
        }
        sqlite3_close(database)
        
        results.sort { $0.rank > $1.rank }
        cache.setObject(results as NSArray, forKey: cacheKey)
        return results
    }
    
    func asyncQuery(_ query: String, type: SearchType,
                    completionHandler: @escaping ([SearchResult])->Void) {

        DispatchQueue.global(qos: .userInitiated).async {
            let queryResults = self.query(query, searchType: type)
            DispatchQueue.main.async {
                completionHandler(queryResults)
            }
        }
    }
}

extension LegacySearchEngine {
    func asyncQuery(_ query: String, type: LegacySearchType,
                    completionHandler: @escaping ([[String:Any]])->Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let queryResults = self.query(query, type: type)
            DispatchQueue.main.async {
                completionHandler(queryResults)
            }
        }
    }
}
