//
//  DiskCacheManager.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/19/26.
//

import Foundation
internal import UniformTypeIdentifiers

final actor DiskCacheManager {
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 200 * 1024 * 1024
    
    init() {
        let cachePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachePath.appendingPathComponent("ImageCache", conformingTo: .data)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func save(_ data: Data, key: String) throws {
        let fileUrl = cacheDirectory.appendingPathComponent(toSafeFileName(key), conformingTo: .data)
        try data.write(to: fileUrl)
        
        try enforceSizeLimit()
    }
    
    func load(key: String) throws -> Data? {
        let fileUrl = cacheDirectory.appendingPathComponent(toSafeFileName(key), conformingTo: .data)
        guard fileManager.fileExists(atPath: fileUrl.path()) else { return nil }
        
        // 캐시 접근 시간 업데이트
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileUrl.path())
        return try Data(contentsOf: fileUrl)
    }
    
    func clear() async throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        
        for fileUrl in contents {
            try fileManager.removeItem(at: fileUrl)
        }
    }
    
    private func enforceSizeLimit() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        let cacheSize = try contents.reduce(0) { partialResult, url in
            let size = try fileManager.attributesOfItem(atPath: url.path())[.size] as? Int ?? 0
            return partialResult + size
        }

        if cacheSize > maxCacheSize {
            try clearCacheUntilMaxSize(contents, currentCacheSize: cacheSize)
        }
    }
    
    private func clearCacheUntilMaxSize(_ cacheUrl: [URL], currentCacheSize: Int) throws {
        let modiSortContents = try cacheUrl
            .sorted { a1, a2 in
                let a1Date = try fileManager.attributesOfItem(atPath: a1.path())[.modificationDate] as? Date ?? Date.distantPast
                let a2Date = try fileManager.attributesOfItem(atPath: a2.path())[.modificationDate] as? Date ?? Date.distantPast
            return a1Date < a2Date
        }
        
        var endIndex: Int = 0
        let targetSize = currentCacheSize - maxCacheSize
        var sum = 0
        for (index, url) in modiSortContents.enumerated() {
            sum += try fileManager.attributesOfItem(atPath: url.path())[.size] as? Int ?? 0
            endIndex = index
            if targetSize < sum {
                break
            }
        }
        
        for clearIndex in 0...endIndex {
            try fileManager.removeItem(at: modiSortContents[clearIndex])
        }
        
    }
    
    private func toSafeFileName(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
    }
}
