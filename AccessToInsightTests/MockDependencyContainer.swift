//
//  MockDependencyContainer.swift
//  AccessToInsightTests
//
//  Created by Bill Parousis on 2021-06-20.
//

import Foundation

@testable import AccessToInsight

extension DependencyContainer {
    static var mock = DependencyContainer(defaults: .mock)
}

extension UserDefaults {
    static var mock: UserDefaults = {
        let userDefaults = UserDefaults(suiteName: "AccessToInsightTests")!
        userDefaults.removePersistentDomain(forName: "AccessToInsightTests")
        return userDefaults
    }()
}
