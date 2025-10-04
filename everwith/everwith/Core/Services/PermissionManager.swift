//
//  PermissionManager.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import Photos
import AVFoundation
import UIKit
import SwiftUI
import Combine

// MARK: - Permission Manager
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @Published var cameraStatus: AVAuthorizationStatus = .notDetermined
    @Published var microphoneStatus: AVAuthorizationStatus = .notDetermined
    
    private init() {
        updatePermissionStatuses()
    }
    
    // MARK: - Permission Status Updates
    func updatePermissionStatuses() {
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    // MARK: - Photo Library Permission
    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            photoLibraryStatus = status
        }
        return status
    }
    
    var isPhotoLibraryAuthorized: Bool {
        return photoLibraryStatus == .authorized || photoLibraryStatus == .limited
    }
    
    var photoLibraryPermissionDescription: String {
        switch photoLibraryStatus {
        case .authorized:
            return "Full access to photo library"
        case .limited:
            return "Limited access to selected photos"
        case .denied:
            return "Photo library access denied"
        case .restricted:
            return "Photo library access restricted"
        case .notDetermined:
            return "Photo library permission not requested"
        @unknown default:
            return "Unknown photo library status"
        }
    }
    
    // MARK: - Camera Permission
    func requestCameraPermission() async -> AVAuthorizationStatus {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            cameraStatus = status ? .authorized : .denied
        }
        return cameraStatus
    }
    
    var isCameraAuthorized: Bool {
        return cameraStatus == .authorized
    }
    
    var cameraPermissionDescription: String {
        switch cameraStatus {
        case .authorized:
            return "Camera access granted"
        case .denied:
            return "Camera access denied"
        case .restricted:
            return "Camera access restricted"
        case .notDetermined:
            return "Camera permission not requested"
        @unknown default:
            return "Unknown camera status"
        }
    }
    
    // MARK: - Microphone Permission
    func requestMicrophonePermission() async -> AVAuthorizationStatus {
        let status = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            microphoneStatus = status ? .authorized : .denied
        }
        return microphoneStatus
    }
    
    var isMicrophoneAuthorized: Bool {
        return microphoneStatus == .authorized
    }
    
    var microphonePermissionDescription: String {
        switch microphoneStatus {
        case .authorized:
            return "Microphone access granted"
        case .denied:
            return "Microphone access denied"
        case .restricted:
            return "Microphone access restricted"
        case .notDetermined:
            return "Microphone permission not requested"
        @unknown default:
            return "Unknown microphone status"
        }
    }
    
    // MARK: - Settings Redirect
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Permission Required Check
    func checkRequiredPermissions(for feature: AppFeature) -> PermissionCheckResult {
        var missingPermissions: [PermissionType] = []
        var canProceed = true
        
        switch feature {
        case .photoRestore:
            if !isPhotoLibraryAuthorized {
                missingPermissions.append(.photoLibrary)
                canProceed = false
            }
            
        case .photoExport:
            if !isPhotoLibraryAuthorized {
                missingPermissions.append(.photoLibrary)
                canProceed = false
            }
            
        case .videoExport:
            if !isPhotoLibraryAuthorized {
                missingPermissions.append(.photoLibrary)
                canProceed = false
            }
            if !isMicrophoneAuthorized {
                missingPermissions.append(.microphone)
                canProceed = false
            }
            
        case .cameraCapture:
            if !isCameraAuthorized {
                missingPermissions.append(.camera)
                canProceed = false
            }
            if !isMicrophoneAuthorized {
                missingPermissions.append(.microphone)
                canProceed = false
            }
        }
        
        return PermissionCheckResult(
            canProceed: canProceed,
            missingPermissions: missingPermissions
        )
    }
}

// MARK: - App Feature Enum
enum AppFeature {
    case photoRestore
    case photoExport
    case videoExport
    case cameraCapture
}

// MARK: - Permission Type Enum
enum PermissionType: String, CaseIterable {
    case photoLibrary = "photo_library"
    case camera = "camera"
    case microphone = "microphone"
    
    var displayName: String {
        switch self {
        case .photoLibrary: return "Photo Library"
        case .camera: return "Camera"
        case .microphone: return "Microphone"
        }
    }
    
    var icon: String {
        switch self {
        case .photoLibrary: return "photo.on.rectangle"
        case .camera: return "camera"
        case .microphone: return "mic"
        }
    }
    
    var description: String {
        switch self {
        case .photoLibrary: return "Access your photos to restore and export memories"
        case .camera: return "Take new photos for restoration"
        case .microphone: return "Record audio for video exports"
        }
    }
}

// MARK: - Permission Check Result
struct PermissionCheckResult {
    let canProceed: Bool
    let missingPermissions: [PermissionType]
}

// MARK: - Permission Request View
struct PermissionRequestView: View {
    let permissionType: PermissionType
    let onRequest: () -> Void
    let onSkip: (() -> Void)?
    
    init(permissionType: PermissionType, onRequest: @escaping () -> Void, onSkip: (() -> Void)? = nil) {
        self.permissionType = permissionType
        self.onRequest = onRequest
        self.onSkip = onSkip
    }
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.honeyGold.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: permissionType.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.honeyGold)
            }
            
            // Content
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                Text("\(permissionType.displayName) Access")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text(permissionType.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("We need this permission to provide the best experience for restoring and sharing your memories.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // Action Buttons
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                Button(action: onRequest) {
                    Text("Allow Access")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.charcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.honeyGold)
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                }
                .buttonStyle(PlainButtonStyle())
                
                if let onSkip = onSkip {
                    Button(action: onSkip) {
                        Text("Not Now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.charcoal.opacity(0.6))
                    }
                }
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Permission Denied View
struct PermissionDeniedView: View {
    let permissionType: PermissionType
    let onOpenSettings: () -> Void
    let onRetry: (() -> Void)?
    
    init(permissionType: PermissionType, onOpenSettings: @escaping () -> Void, onRetry: (() -> Void)? = nil) {
        self.permissionType = permissionType
        self.onOpenSettings = onOpenSettings
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.charcoal.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
            }
            
            // Content
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                Text("\(permissionType.displayName) Access Denied")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text("To use this feature, please enable \(permissionType.displayName.lowercased()) access in Settings.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Action Buttons
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.charcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.honeyGold)
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                }
                .buttonStyle(PlainButtonStyle())
                
                if let onRetry = onRetry {
                    Button(action: onRetry) {
                        Text("Check Again")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.charcoal.opacity(0.6))
                    }
                }
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

#Preview {
    VStack(spacing: 20) {
        PermissionRequestView(
            permissionType: .photoLibrary,
            onRequest: {},
            onSkip: {}
        )
        
        PermissionDeniedView(
            permissionType: .camera,
            onOpenSettings: {},
            onRetry: {}
        )
    }
    .background(Color.warmLinen)
}
