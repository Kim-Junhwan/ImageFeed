//
//  ImageFeedViewModel.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/21/26.
//

import Foundation

struct ImageFeedState: CustomStringConvertible, Withable {
    var images: [IFImage] = []
    var isLoading: Bool = false
    
    var description: String {
        "imagesCount: \(images.count), isLoading: \(isLoading)"
    }
}

enum ImageFeedIntent: enumDescribable {
    case loadInital
    case loadNextPage
    case toggleLike(IFImage)
}

enum ImageFeedEffect: enumDescribable {
    case error(message: String)
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
        case .loadInital:
            withLoading {
                await self.loadInitPage()
            }
        case .loadNextPage:
            withLoading {
                await self.loadNextPage()
            }
        case .toggleLike(let image):
            handleToggleLike(for: image)
        }
    }
    
    private func loadInitPage() async {
        innerState.currentPage = 0
        innerState.canLoadMore = true
        updateState(state.with { $0.images = [] })
        
        await loadNextPage()
    }
    
    private func loadNextPage() async {
        do {
            innerState.currentPage += 1
            let fetchImages = try await fetchImageUseCase.excute(page: innerState.currentPage)
            if fetchImages.isEmpty {
                innerState.canLoadMore = false
            } else {
                updateState(state.with { $0.images.append(contentsOf: fetchImages) })
            }
        } catch {
            postEffect(.error(message: error.localizedDescription))
        }
    }
    
    private func handleToggleLike(for image: IFImage) {
        guard let index = state.images.firstIndex(where: { $0.id == image.id }) else { return }
        updateState(state.with { $0.images[index].isLiked.toggle() })
    }
}
