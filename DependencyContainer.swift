//
//  DependencyContainer.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2021-06-20.
//

import Foundation

struct DependencyContainer {
    let defaults: UserDefaults
    
    init(defaults: UserDefaults) {
        self.defaults = defaults
    }
    
    static let main = DependencyContainer(defaults: .standard)
}

var Current: DependencyContainer = .main
