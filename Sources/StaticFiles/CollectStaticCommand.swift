//
//  CollectStaticCommand.swift
//  
//
//  Created by Bob Voorneveld on 05/10/2021.
//

import Vapor

struct CollectStaticCommand: Command {
    
    var help = """
This will collect the static files in your Public folder and create hashed files out of it.

Use this in combination with #media("/relativepath/filename") in your templates to get the correct url.
"""
    
    struct Signature: CommandSignature {
        @Option(name: "ignore-dir", short: "i")
        var directory: String?        
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
        guard let manifestPath = context.application.staticFiles?.manifestFilePath else {
            throw CollectStaticCommandError.noManifestFilePath
        }

        let path = context.application.directory.publicDirectory

        let ignoreDirectory: String?
        if let dir = signature.directory {
            ignoreDirectory = path + dir
            context.console.output("ignoring '\(dir)'", style: .info)
        } else {
            ignoreDirectory = nil
        }
        let result = try collect(at: "", publicDir: String(path.dropLast()), ignoreDirectory: ignoreDirectory, console: context.console)
        
        context.console.output("Collecting files", style: .info)
        try createManifest(for: result, to: manifestPath, console: context.console)
    }
    
    private func collect(at path: String, publicDir: String, ignoreDirectory: String? = nil, console: Console) throws -> [String: String] {
        let dirPath = publicDir + path
        let contents = try FileManager.default.contentsOfDirectory(atPath: dirPath)
        
        var collectedFiles = [String: String]()
        for content in contents {
            let filePath = dirPath + "/" + content

            let url = URL(fileURLWithPath: filePath)
            let newPath = path + "/" + content
            if try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false {
                if filePath == ignoreDirectory || filePath == publicDir + "/dist" {
                    continue
                }
                let collected = try collect(at: newPath, publicDir: publicDir, ignoreDirectory: ignoreDirectory, console: console)
                collectedFiles.merge(collected) { first, second in first }
            } else {
                collectedFiles[newPath] = try hashFile(at: path, filename: content, publicDir: publicDir, console: console)
            }
        }
        
        return collectedFiles
    }
    
    private func hashFile(at path: String, filename: String, publicDir: String, console: Console) throws -> String {
        let fullPath = publicDir + path + "/" + filename
        let data = FileManager.default.contents(atPath: fullPath)!

        let hashed = SHA256.hash(data: data)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined().prefix(8)
        
        let filename = "\(hashString).\(filename)"

        let directory = publicDir + "/dist" + path
        let partialPath = "/dist" + path + "/" + filename
        let hashedPath = directory + "/" + filename
        

        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: directory, isDirectory: &isDir) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        }

        if !FileManager.default.fileExists(atPath: hashedPath, isDirectory: &isDir) {
            try FileManager.default.copyItem(atPath: fullPath, toPath: hashedPath)
        }
        
        console.output("\(fullPath) => \(hashedPath)", style: .info)
        
        return partialPath

    }

    private func createManifest(for dict: [String: String], to manifestPath: String, console: Console) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        
        console.output("Creating manifest file", style: .info)

        let url = URL(fileURLWithPath: manifestPath)
        try jsonData.write(to: url)
    }
}

enum CollectStaticCommandError: Error {
    case noManifestFilePath
}
