//
//  MediaTag.swift
//
//
//  Created by Bob Voorneveld on 30/09/2021.
//

import Leaf
import Foundation

struct MediaTagError: Error {}

public struct MediaTag: LeafTag {
    public init() {}
    public func render(_ ctx: LeafContext) throws -> LeafData {
        guard let path = ctx.parameters.first?.string else {
            ctx.request?.logger.error("Must include path to media file")
            throw MediaTagError()
        }

        // Check if this file is in the manifest.
        guard let newPath = ctx.application?.staticFiles?.get(path) else {
            ctx.request?.logger.warning("Could not find file, returning original file. \(path)")
            return LeafData.string(path)
        }

        // Return the hashed version of the file.
        return LeafData.string(newPath)
    }
}
