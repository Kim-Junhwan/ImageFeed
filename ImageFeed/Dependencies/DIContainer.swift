//
//  DIContainer.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/22/26.
//

import Foundation

final class DIContainer {
    // Singletons
    private lazy var apiService = UnsplashAPIService()
    private(set) lazy var imageDataRepository: ImageDataRepository = ImageDataRepositoryImpl()
    
    // Repository
    private lazy var imageRepository: ImageRepository = ImageRepositoryImpl(
        apiService: apiService
    )
    
    // UseCase
    private lazy var fetchImagesUseCase = FetchImageUseCase(
        imageRepository: imageRepository
    )
    
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
