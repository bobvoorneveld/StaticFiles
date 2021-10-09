//
//  StaticFilesService.swift
//  
//
//  Created by Bob Voorneveld on 06/10/2021.
//

import Foundation

public enum StaticFilesServiceError: Error {
    case noManifestFile
    case manifestDecodeError
}

public struct StaticFilesService {
    
    public let manifestFilePath: String
    private let manifest: [String: String]
    private let isActive: Bool

    public init(cacheDirectory: String, isActive: Bool) throws {
        self.isActive = isActive
        self.manifestFilePath = cacheDirectory + "manifest.json"

        if !isActive {
            self.manifest = [:]
            return
        }

        guard let data = FileManager.default.contents(atPath: manifestFilePath) else {
            throw StaticFilesServiceError.noManifestFile
        }
        guard let decoded = try? JSONSerialization.jsonObject(with: data, options: []), let manifest = decoded as? [String:String] else {
            throw StaticFilesServiceError.manifestDecodeError
        }
        self.manifest = manifest
    }
    
    public func get(_ original: String) -> String? {
        if isActive {
            return manifest[original]
        }
        return original
    }
}
