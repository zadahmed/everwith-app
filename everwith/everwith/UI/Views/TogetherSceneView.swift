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
    @State private var showingOriginals = false
    @State private var showSaveSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var pickedItems: [PhotosPickerItem] = []
    @State private var backgroundMode: BackgroundOption = .photoA
    @State private var customPrompt: String = ""
    @State private var showBackgroundOptions = false
    
    enum BackgroundOption: String, CaseIterable {
        case photoA = "Use Photo A Background"
        case photoB = "Use Photo B Background"
        case custom = "Generate Custom Background"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean White Background with Subtle Gradient Band
                CleanWhiteBackground()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea(.all, edges: .all)
                
                VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                                .foregroundColor(.deepPlum)
                            
                            Text("Memory Merge")
                                .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                                .foregroundColor(.deepPlum)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal, adaptivePadding(for: geometry))
                .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 28 : 38)
                .padding(.bottom, adaptiveSpacing(16, for: geometry))
                
                // Main Content
                if selectedImages.count < 2 {
                    // Step 1: Select Photos
                    VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(
                                size: adaptiveFontSize(64, for: geometry),
                                weight: .light
                            ))
                            .foregroundColor(.eternalRose.opacity(0.6))
                        
                        Text("Create a Memory Merge")
                            .font(.system(
                                size: adaptiveFontSize(20, for: geometry),
                                weight: .semibold
                            ))
                            .foregroundColor(.shadowPlum)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("Select 2 photos to combine")
                            .font(.system(
                                size: adaptiveFontSize(16, for: geometry),
                                weight: .regular
                            ))
                            .foregroundColor(.shadowPlum.opacity(0.7))
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                        
                        // Show selected photos if any
                        if !selectedImages.isEmpty {
                            HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: min(adaptiveSize(80, for: geometry), geometry.size.width * 0.35), height: min(adaptiveSize(100, for: geometry), geometry.size.width * 0.4))
                                        .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry)))
                                }
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                        }
                        
                        Button(action: { showPhotoPicker = true }) {
                            Text(selectedImages.isEmpty ? "Choose 2 Photos" : "Choose \(2 - selectedImages.count) More")
                                .font(.system(
                                    size: adaptiveFontSize(17, for: geometry),
                                    weight: .semibold
                                ))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: adaptiveSize(280, for: geometry))
                                .frame(height: adaptiveSize(54, for: geometry))
                                .background(Color.eternalRose)
                                .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                        }
                        .padding(.top, adaptiveSpacing(16, for: geometry))
                        
                        Spacer()
                    }
                    .padding(.top, adaptiveSpacing(8, for: geometry))
                } else if processedImage == nil && !isProcessing {
                    // Step 2: Preview & Create
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                            // Show selected images
                            HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: min(geometry.size.height * 0.25, 200))
                                            .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry)))
                                            .shadow(color: .black.opacity(0.1), radius: 10)
                                        
                                        Text("Photo \(index == 0 ? "A" : "B")")
                                            .font(.system(size: adaptiveFontSize(12, for: geometry), weight: .medium))
                                            .foregroundColor(.shadowPlum.opacity(0.7))
                                    }
                                }
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                            .padding(.top, adaptiveSpacing(4, for: geometry))
                            
                            // Background Options Section
                            BackgroundOptionsView(
                                backgroundMode: $backgroundMode,
                                customPrompt: $customPrompt,
                                geometry: geometry
                            )
                            
                            VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                                Button(action: createTogetherScene) {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(
                                                size: adaptiveFontSize(18, for: geometry),
                                                weight: .semibold
                                            ))
                                        Text("Create Memory Merge")
                                            .font(.system(
                                                size: adaptiveFontSize(17, for: geometry),
                                                weight: .semibold
                                            ))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(54, for: geometry))
                                    .background(Color.eternalRose)
                                    .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                }
                                
                                Button(action: { 
                                    selectedImages = []
                                    backgroundMode = .photoA
                                    customPrompt = ""
                                    showPhotoPicker = true 
                                }) {
                                    Text("Choose Different Photos")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .medium
                                        ))
                                        .foregroundColor(.shadowPlum.opacity(0.7))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
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
                                .stroke(Color.eternalRose.opacity(0.3), lineWidth: 8)
                                .frame(
                                    width: adaptiveSize(100, for: geometry),
                                    height: adaptiveSize(100, for: geometry)
                                )
                            
                            Circle()
                                .trim(from: 0, to: processingProgress)
                                .stroke(Color.eternalRose, style: StrokeStyle(lineWidth: 8, lineCap: .round))
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
                                .foregroundColor(.shadowPlum)
                        }
                        
                        Text("Creating your scene...")
                            .font(.system(
                                size: adaptiveFontSize(18, for: geometry),
                                weight: .semibold
                            ))
                            .foregroundColor(.shadowPlum)
                        
                        Text("This may take up to a minute")
                            .font(.system(
                                size: adaptiveFontSize(14, for: geometry),
                                weight: .regular
                            ))
                            .foregroundColor(.shadowPlum.opacity(0.6))
                        
                        Spacer()
                    }
                } else if let processed = processedImage {
                    // Step 4: Result - Simple and Clean
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: adaptiveSpacing(20, for: geometry)) {
                            // Main Image Display
                            VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                // Image
                                if showingOriginals && selectedImages.count >= 2 {
                                    // Show side-by-side originals
                                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                        Image(uiImage: selectedImages[0])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: min(geometry.size.height * 0.3, 250))
                                            .cornerRadius(adaptiveCornerRadius(12, for: geometry))
                                            .clipped()
                                        
                                        Image(uiImage: selectedImages[1])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: min(geometry.size.height * 0.3, 250))
                                            .cornerRadius(adaptiveCornerRadius(12, for: geometry))
                                            .clipped()
                                    }
                                    .padding(.top, adaptiveSpacing(4, for: geometry))
                                } else {
                                    // Show together scene result
                                    Image(uiImage: processed)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: min(geometry.size.height * 0.4, 300))
                                        .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                        .shadow(color: .black.opacity(0.1), radius: 10)
                                        .padding(.top, adaptiveSpacing(4, for: geometry))
                                }
                                
                                // Status Badge
                                HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                    Image(systemName: showingOriginals ? "photo.stack" : "heart.circle.fill")
                                        .font(.system(
                                            size: adaptiveFontSize(14, for: geometry),
                                            weight: .semibold
                                        ))
                                    Text(showingOriginals ? "Original Photos" : "Memory Merge")
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
                                        .fill(showingOriginals ? Color.gray.opacity(0.7) : Color.eternalRose)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 4)
                                .animation(.easeInOut(duration: 0.3), value: showingOriginals)
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                            .padding(.top, adaptiveSpacing(20, for: geometry))
                            .animation(.easeInOut(duration: 0.3), value: showingOriginals)
                            
                            // Compare Toggle Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingOriginals.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .semibold
                                        ))
                                    Text(showingOriginals ? "Show Memory Merge" : "Show Original Photos")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .semibold
                                        ))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundColor(.shadowPlum)
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
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(54, for: geometry))
                                    .background(showSaveSuccess ? Color.green : Color.eternalRose)
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
                                        .foregroundColor(.shadowPlum)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: adaptiveSize(50, for: geometry))
                                        .background(Color.white.opacity(0.7))
                                        .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                                    }
                                    
                                    Button(action: {
                                        selectedImages = []
                                        processedImage = nil
                                        showingOriginals = false
                                        pickedItems.removeAll()
                                        backgroundMode = .photoA
                                        customPrompt = ""
                                        showPhotoPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "photo.badge.plus")
                                            Text("New Scene")
                                        }
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .medium
                                        ))
                                        .foregroundColor(.shadowPlum)
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
            .background(Color.softCream)
            .ignoresSafeArea(.all, edges: .all)
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
    
    // MARK: - Private Methods
    private func createTogetherScene() {
        guard selectedImages.count >= 2 else { return }
        
        Task {
            do {
                isProcessing = true
                
                // Determine background based on user selection
                let background: TogetherBackground
                let backgroundPromptForHistory: String?
                
                switch backgroundMode {
                case .photoA:
                    // Use Photo A's background by extracting and describing it
                    background = TogetherBackground(
                        mode: .generate,
                        prompt: "natural background from photo A, preserve original lighting and atmosphere, photorealistic"
                    )
                    backgroundPromptForHistory = "Photo A Background"
                    
                case .photoB:
                    // Use Photo B's background by extracting and describing it
                    background = TogetherBackground(
                        mode: .generate,
                        prompt: "natural background from photo B, preserve original lighting and atmosphere, photorealistic"
                    )
                    backgroundPromptForHistory = "Photo B Background"
                    
                case .custom:
                    // Use custom user prompt or default if empty
                    let prompt = customPrompt.isEmpty 
                        ? "soft warm tribute background with gentle bokeh and natural lighting" 
                        : customPrompt
                    background = TogetherBackground(
                        mode: .generate,
                        prompt: prompt
                    )
                    backgroundPromptForHistory = prompt
                }
                
                let lookControls = LookControls(
                    warmth: 0.5,
                    shadows: 0.5,
                    grain: 0.3
                )
                
                let (result, subjectAUrl, subjectBUrl) = try await imageProcessingService.togetherPhoto(
                    subjectA: selectedImages[0],
                    subjectB: selectedImages[1],
                    background: background,
                    aspectRatio: .fourFive,
                    seed: nil,
                    lookControls: lookControls
                )
                
                let together = try await imageProcessingService.downloadProcessedImage(from: result.outputUrl)
                
                // Save to history
                do {
                    _ = try await imageProcessingService.saveToHistory(
                        imageType: "together",
                        originalImageUrl: nil, // For together, we don't have a single "original" image
                        processedImageUrl: result.outputUrl,
                        qualityTarget: nil,
                        outputFormat: nil,
                        aspectRatio: "4:5",
                        subjectAUrl: subjectAUrl,
                        subjectBUrl: subjectBUrl,
                        backgroundPrompt: backgroundPromptForHistory
                    )
                    print("✅ Together scene saved to history")
                } catch {
                    print("⚠️ Failed to save to history: \(error)")
                    // Don't fail the whole operation if history save fails
                }
                
                await MainActor.run {
                    processedImage = together
                    isProcessing = false
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

// MARK: - Background Options View
struct BackgroundOptionsView: View {
    @Binding var backgroundMode: TogetherSceneView.BackgroundOption
    @Binding var customPrompt: String
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing(12, for: geometry)) {
            Text("Background")
                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                .foregroundColor(.shadowPlum)
            
            // Background Selection Buttons
            VStack(spacing: adaptiveSpacing(10, for: geometry)) {
                ForEach(TogetherSceneView.BackgroundOption.allCases, id: \.self) { option in
                    BackgroundOptionButton(
                        option: option,
                        isSelected: backgroundMode == option,
                        onTap: {
                            withAnimation {
                                backgroundMode = option
                            }
                        },
                        geometry: geometry
                    )
                }
            }
            
            // Custom Prompt Field (shown when custom mode is selected)
            if backgroundMode == .custom {
                CustomPromptField(
                    customPrompt: $customPrompt,
                    geometry: geometry
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, adaptivePadding(for: geometry))
        .padding(.vertical, adaptiveSpacing(12, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                .fill(Color.white.opacity(0.3))
        )
        .padding(.horizontal, adaptivePadding(for: geometry))
    }
    
    // MARK: - Adaptive Functions
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
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Background Option Button
struct BackgroundOptionButton: View {
    let option: TogetherSceneView.BackgroundOption
    let isSelected: Bool
    let onTap: () -> Void
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: adaptiveFontSize(18, for: geometry)))
                    .foregroundColor(isSelected ? .eternalRose : .shadowPlum.opacity(0.3))
                
                Text(option.rawValue)
                    .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .medium))
                    .foregroundColor(.shadowPlum)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, adaptiveSpacing(16, for: geometry))
            .padding(.vertical, adaptiveSpacing(12, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                    .fill(isSelected ? Color.eternalRose.opacity(0.1) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                    .stroke(isSelected ? Color.eternalRose : Color.shadowPlum.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Adaptive Functions
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
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Custom Prompt Field
struct CustomPromptField: View {
    @Binding var customPrompt: String
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
            Text("Describe your background")
                .font(.system(size: adaptiveFontSize(13, for: geometry), weight: .medium))
                .foregroundColor(.shadowPlum.opacity(0.7))
            
            TextField("e.g., sunset beach, garden party, starry night...", text: $customPrompt)
                .font(.system(size: adaptiveFontSize(15, for: geometry)))
                .padding(.horizontal, adaptiveSpacing(12, for: geometry))
                .padding(.vertical, adaptiveSpacing(10, for: geometry))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .background(
                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(10, for: geometry))
                        .fill(Color.white.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(10, for: geometry))
                        .stroke(Color.shadowPlum.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Adaptive Functions
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
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

#Preview {
    TogetherSceneView()
}