//
//  ImageFeedView.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/21/26.
//

import SwiftUI

struct ImageFeedView: View {
    @State private var viewModel: ImageFeedViewModel
    @State private var imageDataRepository: ImageDataRepository
    @State private var errorMessage: String? = nil
    
    @State private var items: [Color] = []
    
    init(
        viewModel: ImageFeedViewModel,
        imageDataRepository: ImageDataRepository
    ) {
        self.viewModel = viewModel
        self.imageDataRepository = imageDataRepository
    }
    
    var body: some View {
        let images = viewModel.state.images
        let lastImageId = images.last?.id
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(images) { image in
                        ImageFeedCell(image: image, imageDataRepository: imageDataRepository, onLikeTap: {})
                            .equatable()
                        .onAppear {
                            if image.id == lastImageId {
                                viewModel.trigger(.loadNextPage)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)

                LoadingIndicatorView(isLoading: viewModel.isLoading)
            }
            .navigationTitle("Image Feed")
            .refreshable {
                viewModel.trigger(.loadInital)
            }
            .task {
                viewModel.trigger(.loadInital)
            }
            .onReceive(viewModel.effectPublisher) { effect in
                switch effect {
                case .error(message: let message):
                    errorMessage = message
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("확인") {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

// MARK: - LoadingIndicatorView
private struct LoadingIndicatorView: View {
    let isLoading: Bool

    var body: some View {
        if isLoading {
            ProgressView()
                .padding()
        }
    }
}

// MARK: - ImageFeedCell
struct ImageFeedCell: View, Equatable {
    let image: IFImage
    let imageDataRepository: ImageDataRepository
    let onLikeTap: () -> Void

    static func == (lhs: ImageFeedCell, rhs: ImageFeedCell) -> Bool {
        lhs.image == rhs.image
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 이미지
            CachedAsyncImage(
                url: image.thumbnailUrl,
                imageDataRepository: imageDataRepository,
                targetSize: CGSize(width: 200, height: 160) // 셀 실제 표시 크기(pt)
            )
            .aspectRatio(contentMode: .fill)
            .frame(height: 160)
            .clipped()
            .cornerRadius(8)

            // 정보 영역
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(image.author)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("\(image.likesCount) likes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onLikeTap) {
                    Image(systemName: image.isLiked ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundColor(image.isLiked ? .red : .primary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

//#Preview {
//    ImageFeedView(viewModel: <#T##ImageFeedViewModel#>, imageDataRepository: <#T##any ImageDataRepository#>)
//}


