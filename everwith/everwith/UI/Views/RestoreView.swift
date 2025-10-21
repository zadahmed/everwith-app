//
//  RestoreView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import Photos
import PhotosUI

struct RestoreView: View {
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var showPhotoPicker = false
    @State private var showingBefore = false
    @State private var showSaveSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                                .foregroundColor(.charcoal)
                            
                            Text("Restore Photo")
                                .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                                .foregroundColor(.charcoal)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal, adaptivePadding(for: geometry))
                .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 28 : 38)
                .padding(.bottom, adaptiveSpacing(16, for: geometry))
                
                // Main Content
                if selectedImage == nil {
                    // Step 1: Select Photo
                    VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(
                                size: adaptiveFontSize(64, for: geometry),
                                weight: .light
                            ))
                            .foregroundColor(.honeyGold.opacity(0.6))
                        
                        Text("Select a photo to restore")
                            .font(.system(
                                size: adaptiveFontSize(20, for: geometry),
                                weight: .semibold
                            ))
                            .foregroundColor(.charcoal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("Choose a photo from your library")
                            .font(.system(
                                size: adaptiveFontSize(16, for: geometry),
                                weight: .regular
                            ))
                            .foregroundColor(.charcoal.opacity(0.7))
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                        
                        Button(action: { showPhotoPicker = true }) {
                            Text("Choose Photo")
                                .font(.system(
                                    size: adaptiveFontSize(17, for: geometry),
                                    weight: .semibold
                                ))
                                .foregroundColor(.white)
                                .frame(maxWidth: adaptiveSize(280, for: geometry))
                                .frame(height: adaptiveSize(54, for: geometry))
                                .background(Color.honeyGold)
                                .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                        }
                        .padding(.top, adaptiveSpacing(16, for: geometry))
                        
                        Spacer()
                    }
                    .padding(.top, adaptiveSpacing(8, for: geometry))
                } else if processedImage == nil && !isProcessing {
                    // Step 2: Preview & Restore
                    ScrollView {
                        VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                            // Show selected image
                            Image(uiImage: selectedImage!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: geometry.size.height * 0.5)
                                .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                .shadow(color: .black.opacity(0.1), radius: 10)
                                .padding(.horizontal, adaptivePadding(for: geometry))
                                .padding(.top, adaptiveSpacing(8, for: geometry))
                            
                            VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                                Button(action: restorePhoto) {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(
                                                size: adaptiveFontSize(18, for: geometry),
                                                weight: .semibold
                                            ))
                                        Text("Restore Photo")
                                            .font(.system(
                                                size: adaptiveFontSize(17, for: geometry),
                                                weight: .semibold
                                            ))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(54, for: geometry))
                                    .background(Color.honeyGold)
                                    .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                }
                                
                                Button(action: { selectedImage = nil; showPhotoPicker = true }) {
                                    Text("Choose Different Photo")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .medium
                                        ))
                                        .foregroundColor(.charcoal.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                        }
                        .padding(.top, adaptiveSpacing(8, for: geometry))
                    }
                } else if isProcessing {
                    // Step 3: Processing
                    VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.honeyGold.opacity(0.3), lineWidth: 8)
                                .frame(
                                    width: adaptiveSize(100, for: geometry),
                                    height: adaptiveSize(100, for: geometry)
                                )
                            
                            Circle()
                                .trim(from: 0, to: processingProgress)
                                .stroke(Color.honeyGold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(
                                    width: adaptiveSize(100, for: geometry),
                                    height: adaptiveSize(100, for: geometry)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.3), value: processingProgress)
                            
                            Text("\(Int(processingProgress * 100))%")
                                .font(.system(
                                    size: adaptiveFontSize(20, for: geometry),
                                    weight: .semibold
                                ))
                                .foregroundColor(.charcoal)
                        }
                        
                        Text("Restoring your photo...")
                            .font(.system(
                                size: adaptiveFontSize(18, for: geometry),
                                weight: .semibold
                            ))
                            .foregroundColor(.charcoal)
                        
                        Text("This usually takes 10-30 seconds")
                            .font(.system(
                                size: adaptiveFontSize(14, for: geometry),
                                weight: .regular
                            ))
                            .foregroundColor(.charcoal.opacity(0.6))
                        
                        Spacer()
                    }
                } else if let processed = processedImage {
                    // Step 4: Result - Simple and Clean
                    ScrollView {
                        VStack(spacing: adaptiveSpacing(20, for: geometry)) {
                            // Main Image Display
                            VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                // Image
                                Image(uiImage: showingBefore ? selectedImage! : processed)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: geometry.size.height * 0.5)
                                    .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                    .shadow(color: .black.opacity(0.1), radius: 10)
                                    .animation(.easeInOut(duration: 0.3), value: showingBefore)
                                    .padding(.top, adaptiveSpacing(4, for: geometry))
                                
                                // Status Badge
                                HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                    Image(systemName: showingBefore ? "photo" : "sparkles")
                                        .font(.system(
                                            size: adaptiveFontSize(14, for: geometry),
                                            weight: .semibold
                                        ))
                                    Text(showingBefore ? "Original Photo" : "Restored Photo")
                                        .font(.system(
                                            size: adaptiveFontSize(15, for: geometry),
                                            weight: .semibold
                                        ))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                                .padding(.vertical, adaptiveSpacing(8, for: geometry))
                                .background(
                                    Capsule()
                                        .fill(showingBefore ? Color.gray.opacity(0.7) : Color.honeyGold)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 4)
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                            .padding(.top, adaptiveSpacing(20, for: geometry))
                            
                            // Compare Toggle Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingBefore.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .semibold
                                        ))
                                    Text(showingBefore ? "Show Restored" : "Show Original")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .semibold
                                        ))
                                }
                                .foregroundColor(.charcoal)
                                .frame(maxWidth: .infinity)
                                .frame(height: adaptiveSize(50, for: geometry))
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                        
                            // Action Buttons
                            VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                Button(action: savePhoto) {
                                    HStack {
                                        Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                                            .font(.system(
                                                size: adaptiveFontSize(18, for: geometry),
                                                weight: .semibold
                                            ))
                                        Text(showSaveSuccess ? "Saved!" : "Save to Photos")
                                            .font(.system(
                                                size: adaptiveFontSize(17, for: geometry),
                                                weight: .semibold
                                            ))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(54, for: geometry))
                                    .background(showSaveSuccess ? Color.green : Color.honeyGold)
                                    .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                }
                                .disabled(showSaveSuccess)
                                
                                HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                    Button(action: sharePhoto) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Share")
                                        }
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .medium
                                        ))
                                        .foregroundColor(.charcoal)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: adaptiveSize(50, for: geometry))
                                        .background(Color.white.opacity(0.7))
                                        .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                                    }
                                    
                                    Button(action: { 
                                        selectedImage = nil
                                        processedImage = nil
                                        showingBefore = false
                                        showPhotoPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "photo.badge.plus")
                                            Text("New Photo")
                                        }
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .medium
                                        ))
                                        .foregroundColor(.charcoal)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: adaptiveSize(50, for: geometry))
                                        .background(Color.white.opacity(0.7))
                                        .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                                    }
                                }
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                            .padding(.bottom, max(geometry.safeAreaInsets.bottom, adaptiveSpacing(20, for: geometry)))
                        }
                        .padding(.top, adaptiveSpacing(8, for: geometry))
                    }
                }
            }
            .background(Color.warmLinen)
            .ignoresSafeArea(.all, edges: .all)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: Binding(
            get: { nil },
            set: { newValue in
                if let item = newValue {
                    loadPhoto(from: item)
                }
            }
        ), matching: .images)
        .onReceive(imageProcessingService.$processingProgress) { progress in
            if let p = progress {
                processingProgress = Double(p.currentStepIndex) / Double(p.totalSteps)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                clearError()
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        }
    }
    
    private func restorePhoto() {
        guard let image = selectedImage else { return }
        
        Task {
            do {
                isProcessing = true
                
                let result = try await imageProcessingService.restorePhoto(
                    image: image,
                    qualityTarget: .standard,
                    outputFormat: .png,
                    aspectRatio: .original,
                    seed: nil
                )
                
                let restored = try await imageProcessingService.downloadProcessedImage(from: result.outputUrl)
                
                // Save to history
                do {
                    _ = try await imageProcessingService.saveToHistory(
                        imageType: "restore",
                        originalImageUrl: nil,  // We don't have the uploaded original URL here
                        processedImageUrl: result.outputUrl,
                        qualityTarget: "standard",
                        outputFormat: "png",
                        aspectRatio: "original"
                    )
                    print("✅ Image saved to history")
                } catch {
                    print("⚠️ Failed to save to history: \(error)")
                    // Don't fail the whole operation if history save fails
                }
                
                await MainActor.run {
                    processedImage = restored
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                print("❌ Restore failed: \(error)")
            }
        }
    }
    
    private func clearError() {
        errorMessage = nil
        showError = false
    }
    
    private func savePhoto() {
        guard let image = processedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        withAnimation {
            showSaveSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveSuccess = false
            }
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func sharePhoto() {
        guard let image = processedImage else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Adaptive Sizing Functions (matching HomeView)
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(12, min(16, screenWidth * 0.04))
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

#Preview {
    RestoreView()
}