//
//  ImageDataRepositoryImpl.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/21/26.
//

import Foundation

final class ImageDataRepositoryImpl: ImageDataRepository {
    
    private let memoryCache = NSCache<NSString, NSData>()
    private let diskCache = DiskCacheManager()
    
    init() {
        memoryCache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func loadImageData(url: URL) async throws -> Data {
        let key = url.absoluteString
        
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached as Data
        }
        
        if let cached = try await diskCache.load(key: key) {
            memoryCache.setObject(cached as NSData, forKey: key as NSString)
            return cached
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        Task.detached(priority: .background) { [weak self] in
            try await self?.diskCache.save(data, key: key)
        }
        memoryCache.setObject(data as NSData, forKey: key as NSString)
        
        return data
    }
    
    func clear() async {
        memoryCache.removeAllObjects()
        try? await diskCache.clear()
    }
    
    
}
