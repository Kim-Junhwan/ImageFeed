//
//  DIContainer.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/22/26.
//

import Foundation

final class DIContainer {
    // Singletons
    private let apiService: UnsplashAPIService
    private let imageDataRepository: ImageDataRepository
    private let imageRepository: ImageRepository
    
    init() {
        let apiService = UnsplashAPIService()
        self.apiService = apiService
        self.imageDataRepository = ImageDataRepositoryImpl()
        self.imageRepository = ImageRepositoryImpl(apiService: apiService)
        self.fetchImagesUseCase = FetchImageUseCase(imageRepository: self.imageRepository)
    }
    
    // UseCase
    private let fetchImagesUseCase: FetchImageUseCase
    
    // View Factory
    func makeImageFeedView() -> ImageFeedView {
        let viewModel = ImageFeedViewModel(
            fetchImageUseCase: fetchImagesUseCase
        )
        
        return ImageFeedView(
            viewModel: viewModel,
            imageDataRepository: imageDataRepository
        )
    }
}
