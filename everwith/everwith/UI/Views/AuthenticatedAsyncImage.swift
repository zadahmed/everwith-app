//
//  AuthenticatedAsyncImage.swift
//  EverWith
//
//  Optimized AsyncImage wrapper for CDN URLs
//  Note: Images are public for performance, secured by unguessable UUIDs
//

import SwiftUI

struct AuthenticatedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String
    let imageId: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    init(
        url: String,
        imageId: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.imageId = imageId
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        // Direct AsyncImage - no auth needed, images are public
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                content(image)
            case .failure:
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    Text("Failed to load")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            @unknown default:
                placeholder()
            }
        }
    }
}

// Convenience initializers
extension AuthenticatedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: String, imageId: String) {
        self.init(
            url: url,
            imageId: imageId,
            content: { $0 },
            placeholder: { ProgressView() }
        )
    }
}

extension AuthenticatedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: String, imageId: String, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(
            url: url,
            imageId: imageId,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}
