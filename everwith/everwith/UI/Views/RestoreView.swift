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
    @State private var sliderPosition: CGFloat = 0.5
    @State private var showSaveSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.warmLinen
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Simple Header
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 17, weight: .regular))
                            }
                            .foregroundColor(.charcoal)
                        }
                        
                        Spacer()
                        
                        Text("Restore Photo")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.charcoal)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    
                    // Main Content
                    if selectedImage == nil {
                        // Step 1: Select Photo
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 64, weight: .light))
                                .foregroundColor(.honeyGold.opacity(0.6))
                            
                            Text("Select a photo to restore")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.charcoal)
                            
                            Text("Choose a photo from your library")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.charcoal.opacity(0.7))
                            
                            Button(action: { showPhotoPicker = true }) {
                                Text("Choose Photo")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: 280)
                                    .frame(height: 54)
                                    .background(Color.honeyGold)
                                    .cornerRadius(16)
                            }
                            .padding(.top, 16)
                            
                            Spacer()
                        }
                    } else if processedImage == nil && !isProcessing {
                        // Step 2: Preview & Restore
                        ScrollView {
                            VStack(spacing: 24) {
                                // Show selected image
                                Image(uiImage: selectedImage!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: geometry.size.height * 0.5)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.1), radius: 10)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 16) {
                                    Button(action: restorePhoto) {
                                        HStack {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 18, weight: .semibold))
                                            Text("Restore Photo")
                                                .font(.system(size: 17, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(Color.honeyGold)
                                        .cornerRadius(16)
                                    }
                                    
                                    Button(action: { selectedImage = nil; showPhotoPicker = true }) {
                                        Text("Choose Different Photo")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.charcoal.opacity(0.7))
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 20)
                        }
                    } else if isProcessing {
                        // Step 3: Processing
                        VStack(spacing: 24) {
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.honeyGold.opacity(0.3), lineWidth: 8)
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .trim(from: 0, to: processingProgress)
                                    .stroke(Color.honeyGold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.3), value: processingProgress)
                                
                                Text("\(Int(processingProgress * 100))%")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.charcoal)
                            }
                            
                            Text("Restoring your photo...")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.charcoal)
                            
                            Text("This usually takes 10-30 seconds")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.charcoal.opacity(0.6))
                            
                            Spacer()
                        }
                    } else if let processed = processedImage {
                        // Step 4: Result with Before/After
                        VStack(spacing: 0) {
                            // Before/After Comparison
                            GeometryReader { imageGeometry in
                                ZStack(alignment: .leading) {
                                    // After image (full)
                                    Image(uiImage: processed)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                    
                                    // Before image (masked)
                                    Image(uiImage: selectedImage!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .mask(
                                            Rectangle()
                                                .frame(width: imageGeometry.size.width * sliderPosition)
                                        )
                                    
                                    // Labels
                                    HStack {
                                        if sliderPosition > 0.1 {
                                            Text("Before")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.black.opacity(0.6))
                                                .cornerRadius(8)
                                                .padding(.leading, 12)
                                        }
                                        
                                        Spacer()
                                        
                                        if sliderPosition < 0.9 {
                                            Text("After")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.black.opacity(0.6))
                                                .cornerRadius(8)
                                                .padding(.trailing, 12)
                                        }
                                    }
                                    .padding(.top, 12)
                                    
                                    // Slider
                                    VStack {
                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(width: 3)
                                            .shadow(color: .black.opacity(0.3), radius: 2)
                                            .overlay(
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 44, height: 44)
                                                    .shadow(color: .black.opacity(0.3), radius: 8)
                                                    .overlay(
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "chevron.left")
                                                                .font(.system(size: 10, weight: .bold))
                                                            Image(systemName: "chevron.right")
                                                                .font(.system(size: 10, weight: .bold))
                                                        }
                                                        .foregroundColor(.charcoal.opacity(0.6))
                                                    )
                                            )
                                    }
                                    .offset(x: imageGeometry.size.width * sliderPosition - 22)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                sliderPosition = min(max(value.location.x / imageGeometry.size.width, 0), 1)
                                            }
                                    )
                                }
                            }
                            .frame(height: geometry.size.height * 0.55)
                            
                            Spacer()
                            
                            // Instructions
                            Text("← Swipe to compare →")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.charcoal.opacity(0.5))
                                .padding(.bottom, 16)
                            
                            // Action Buttons
                            VStack(spacing: 12) {
                                Button(action: savePhoto) {
                                    HStack {
                                        Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                        Text(showSaveSuccess ? "Saved!" : "Save to Photos")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(showSaveSuccess ? Color.green : Color.honeyGold)
                                    .cornerRadius(16)
                                }
                                .disabled(showSaveSuccess)
                                
                                HStack(spacing: 12) {
                                    Button(action: sharePhoto) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Share")
                                        }
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.charcoal)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.white.opacity(0.5))
                                        .cornerRadius(14)
                                    }
                                    
                                    Button(action: { 
                                        selectedImage = nil
                                        processedImage = nil
                                        showPhotoPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "photo.badge.plus")
                                            Text("New Photo")
                                        }
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.charcoal)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.white.opacity(0.5))
                                        .cornerRadius(14)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                        }
                    }
                }
            }
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
                
                await MainActor.run {
                    processedImage = restored
                    isProcessing = false
                    sliderPosition = 0.5
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
}

#Preview {
    RestoreView()
}
