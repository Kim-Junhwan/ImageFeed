//
//  ImageRepositoryImpl.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/19/26.
//

import Foundation

final class ImageRepositoryImpl: ImageRepository {
    
    private let apiService: UnsplashAPIService
    
    init(apiService: UnsplashAPIService) {
        self.apiService = apiService
    }
    
    func fetchImages(page: Int) async throws -> [IFImage] {
        return try await apiService.fetchImages(page: page).map { $0.toEntity() }.compactMap { $0 }
    }
}
