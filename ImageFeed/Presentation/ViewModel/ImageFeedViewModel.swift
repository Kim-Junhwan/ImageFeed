//
//  ImageFeedViewModel.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/21/26.
//

import Foundation

struct ImageFeedState: CustomStringConvertible {
    var images: [IFImage] = []
    var isLoading: Bool = false
    
    var description: String {
        ""
    }
}

enum ImageFeedIntent: enumDescribable {
    case appear
    case loadNextPage
}

enum ImageFeedEffect: enumDescribable {
    case none
}

@MainActor
final class ImageFeedViewModel: BaseViewModel<ImageFeedIntent, ImageFeedState, ImageFeedEffect> {
    
    struct InnerState {
        var currentPage: Int = 0
        var canLoadMore: Bool = true
    }
    
    private let fetchImageUseCase: FetchImageUseCase
    private var innerState: InnerState = InnerState()
    
    init(fetchImageUseCase: FetchImageUseCase) {
        self.fetchImageUseCase = fetchImageUseCase
        super.init(initialState: .init())
    }
    
    override func handleIntent(_ intent: ImageFeedIntent) {
        switch intent {
        case .appear:
            break
        case .loadNextPage:
            withLoading { [weak self] in
                await self?.handleLoadNextPage()
            }
        }
    }
    
    private func handleLoadNextPage() async {
        do {
            let fetchImages = try await fetchImageUseCase.excute(page: innerState.currentPage)
            
            if fetchImages.isEmpty {
                innerState.canLoadMore = false
            } else {
            }
        } catch {
            
        }
    }
}
