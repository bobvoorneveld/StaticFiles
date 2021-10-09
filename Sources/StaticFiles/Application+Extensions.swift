//
//  Application+Extensions.swift
//  
//
//  Created by Bob Voorneveld on 09/10/2021.
//

import Vapor

public struct StaticFilesServiceKey: StorageKey {
    public typealias Value = StaticFilesService
}

public extension Application {
    var staticFiles: StaticFilesService? {
        get {
            self.storage[StaticFilesServiceKey.self]
        }
        set {
            self.storage[StaticFilesServiceKey.self] = newValue
        }
    }
}
