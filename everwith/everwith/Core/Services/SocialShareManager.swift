//
//  SocialShareManager.swift
//  EverWith
//
//  Handles deep-share intents for TikTok and Instagram.
//

import Foundation

enum ShareIntentError: LocalizedError {
    case appNotInstalled(String)
    case imageEncodingFailed
    case unableToPresent
    case userCancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .appNotInstalled(let app):
            return "\(app) is not installed."
        case .imageEncodingFailed:
            return "Unable to prepare image for sharing."
        case .unableToPresent:
            return "Something went wrong while opening the share sheet."
        case .userCancelled:
            return "Share cancelled."
        case .unknown:
            return "Unable to share right now."
        }
    }
}

#if canImport(UIKit)
import UIKit

final class SocialShareManager {
    static let shared = SocialShareManager()
    
    private init() {}
    
    func share(
        image: UIImage,
        platform: SharePlatform,
        hashtag: String,
        completion: @escaping (Result<Void, ShareIntentError>) -> Void
    ) {
        switch platform {
        case .instagram:
            shareToInstagram(image: image, hashtag: hashtag, completion: completion)
        case .tiktok:
            shareToTikTok(image: image, hashtag: hashtag, completion: completion)
        }
    }
    
    private func shareToInstagram(
        image: UIImage,
        hashtag: String,
        completion: @escaping (Result<Void, ShareIntentError>) -> Void
    ) {
        guard let urlScheme = URL(string: "instagram-stories://share") else {
            completion(.failure(.unknown))
            return
        }
        
        guard UIApplication.shared.canOpenURL(urlScheme) else {
            completion(.failure(.appNotInstalled("Instagram Stories")))
            return
        }
        
        guard let imageData = image.pngData() else {
            completion(.failure(.imageEncodingFailed))
            return
        }
        
        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData,
            "com.instagram.sharedSticker.contentURL": "https://everwith.app",
            "com.instagram.sharedSticker.stickerTexts": [hashtag]
        ]]
        
        UIPasteboard.general.setItems(
            pasteboardItems,
            options: [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(300)]
        )
        
        UIApplication.shared.open(urlScheme, options: [:]) { success in
            completion(success ? .success(()) : .failure(.unknown))
        }
    }
    
    private func shareToTikTok(
        image: UIImage,
        hashtag: String,
        completion: @escaping (Result<Void, ShareIntentError>) -> Void
    ) {
        let tiktokURL = URL(string: "tiktok://camera/")!
        UIPasteboard.general.string = hashtag
        
        if UIApplication.shared.canOpenURL(tiktokURL) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            UIApplication.shared.open(tiktokURL, options: [:]) { success in
                completion(success ? .success(()) : .failure(.unknown))
            }
            return
        }
        
        presentSystemShareSheet(items: [image, hashtag], completion: completion)
    }
    
    private func presentSystemShareSheet(
        items: [Any],
        completion: @escaping (Result<Void, ShareIntentError>) -> Void
    ) {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else {
            completion(.failure(.unableToPresent))
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, completed, _, error in
            if let _ = error {
                completion(.failure(.unknown))
            } else if completed {
                completion(.success(()))
            } else {
                completion(.failure(.userCancelled))
            }
        }
        
        rootVC.present(activityVC, animated: true)
    }
}

#else

final class SocialShareManager {
    static let shared = SocialShareManager()
    private init() {}
    
    func share(
        image: UIImage,
        platform: SharePlatform,
        hashtag: String,
        completion: @escaping (Result<Void, ShareIntentError>) -> Void
    ) {
        completion(.failure(.unknown))
    }
}

#endif

