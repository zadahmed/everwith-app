//
//  TogetherSceneView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import PhotosUI

struct TogetherSceneView: View {
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImages: [UIImage] = []
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var showPhotoPicker = false
    @State private var sliderPosition: CGFloat = 0.5
    @State private var showSaveSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var pickedItems: [PhotosPickerItem] = []
    
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
                        
                        Text("Together Scene")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.charcoal)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    
                    // Main Content
                    if selectedImages.count < 2 {
                        // Step 1: Select Photos
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 64, weight: .light))
                                .foregroundColor(.sky.opacity(0.6))
                            
                            Text("Create a Together Scene")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.charcoal)
                            
                            Text("Select 2 photos to combine")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.charcoal.opacity(0.7))
                            
                            // Show selected photos if any
                            if !selectedImages.isEmpty {
                                HStack(spacing: 12) {
                                    ForEach(selectedImages.indices, id: \.self) { index in
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            
                            Button(action: { showPhotoPicker = true }) {
                                Text(selectedImages.isEmpty ? "Choose 2 Photos" : "Choose \(2 - selectedImages.count) More")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: 280)
                                    .frame(height: 54)
                                    .background(Color.sky)
                                    .cornerRadius(16)
                            }
                            .padding(.top, 16)
                            
                            Spacer()
                        }
                    } else if processedImage == nil && !isProcessing {
                        // Step 2: Preview & Create
                        ScrollView {
                            VStack(spacing: 24) {
                                // Show selected images
                                HStack(spacing: 16) {
                                    ForEach(selectedImages.indices, id: \.self) { index in
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: geometry.size.height * 0.3)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(color: .black.opacity(0.1), radius: 10)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                VStack(spacing: 16) {
                                    Button(action: createTogetherScene) {
                            HStack {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 18, weight: .semibold))
                                            Text("Create Together Scene")
                                                .font(.system(size: 17, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(Color.sky)
                                        .cornerRadius(16)
                                    }
                                    
                                    Button(action: { selectedImages = []; showPhotoPicker = true }) {
                                        Text("Choose Different Photos")
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
                                    .stroke(Color.sky.opacity(0.3), lineWidth: 8)
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .trim(from: 0, to: processingProgress)
                                    .stroke(Color.sky, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.3), value: processingProgress)
                                
                                Text("\(Int(processingProgress * 100))%")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.charcoal)
                            }
                            
                            Text("Creating your scene...")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.charcoal)
                            
                            Text("This may take up to a minute")
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
                                    
                                    // Before image (masked) - show first image
                                    if !selectedImages.isEmpty {
                                        HStack(spacing: 8) {
                                            Image(uiImage: selectedImages[0])
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: imageGeometry.size.width * 0.45 * sliderPosition)
                                                .clipped()
                                            
                                            if selectedImages.count > 1 {
                                                Image(uiImage: selectedImages[1])
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: imageGeometry.size.width * 0.45 * sliderPosition)
                                                    .clipped()
                                            }
                                        }
                                        .mask(
                                            Rectangle()
                                                .frame(width: imageGeometry.size.width * sliderPosition)
                                        )
                                    }
                                    
                                    // Labels
                                    HStack {
                                        if sliderPosition > 0.1 {
                                            Text("Original")
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
                                            Text("Together")
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
                                    .background(showSaveSuccess ? Color.green : Color.sky)
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
                                        selectedImages = []
                                        processedImage = nil
                                        pickedItems.removeAll()
                                        showPhotoPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "photo.badge.plus")
                                            Text("New Scene")
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
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickedItems, maxSelectionCount: 2 - selectedImages.count, matching: .images)
        .onChange(of: pickedItems) { oldValue, newValue in
            Task {
                // Load images from the newly picked items, respecting the remaining slots
                let remaining = max(0, 2 - selectedImages.count)
                let toLoad = Array(newValue.prefix(remaining))
                for item in toLoad {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            if selectedImages.count < 2 {
                                selectedImages.append(uiImage)
                            }
                        }
                    }
                }
                await MainActor.run {
                    // Clear picked items after processing to avoid duplicate loads
                    pickedItems.removeAll()
                    // Auto-hide picker if we've reached 2 images
                    if selectedImages.count >= 2 {
                        showPhotoPicker = false
                    }
                }
            }
        }
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
    
    private func createTogetherScene() {
        guard selectedImages.count >= 2 else { return }
        
        Task {
            do {
                isProcessing = true
                
                let background = TogetherBackground(
                    mode: .generate,
                    prompt: "soft warm tribute background with gentle bokeh and natural lighting"
                )
                
                let lookControls = LookControls(
                    warmth: 0.5,
                    shadows: 0.5,
                    grain: 0.3
                )
                
                let result = try await imageProcessingService.togetherPhoto(
                    subjectA: selectedImages[0],
                    subjectB: selectedImages[1],
                    background: background,
                    aspectRatio: .fourFive,
                    seed: nil,
                    lookControls: lookControls
                )
                
                let together = try await imageProcessingService.downloadProcessedImage(from: result.outputUrl)
                
                await MainActor.run {
                    processedImage = together
                    isProcessing = false
                    sliderPosition = 0.5
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                print("❌ Together failed: \(error)")
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
    TogetherSceneView()
}
