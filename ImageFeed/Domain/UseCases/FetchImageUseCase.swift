//
//  FetchImageUseCase.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/19/26.
//

import Foundation

final class FetchImageUseCase {
    private let imageRepository: ImageRepository
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
    }
    
    func excute(page: Int) async throws -> [IFImage] {
        return try await imageRepository.fetchImages(page: page)
    }
}
