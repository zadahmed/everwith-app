//
//  MemoryMergeFlow.swift
//  EverWith
//
//  Memory Merge Mode Flow
//  Flow: Upload → Style Selection → Processing → Result
//

import SwiftUI
import PhotosUI

// MARK: - Memory Merge Flow Coordinator
struct MemoryMergeFlow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    
    @State private var currentStep: MergeStep = .upload
    @State private var selectedImages: [UIImage] = []
    @State private var selectedStyle: MergeStyle = .realistic
    @State private var processedImage: UIImage?
    @State private var processedImageUrl: String?
    @State private var subjectAUrl: String?
    @State private var subjectBUrl: String?
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var showError = false
    
    enum MergeStep {
        case upload
        case styleSelection
        case processing
        case result
    }
    
    enum MergeStyle: String, CaseIterable {
        case realistic = "Realistic"
        case warmVintage = "Warm Vintage"
        case softGlow = "Soft Glow"
        case filmLook = "Film Look"
        
        var icon: String {
            switch self {
            case .realistic: return "photo"
            case .warmVintage: return "sun.max"
            case .softGlow: return "sparkles"
            case .filmLook: return "film"
            }
        }
        
        var description: String {
            switch self {
            case .realistic: return "Natural and lifelike"
            case .warmVintage: return "Nostalgic sepia tones"
            case .softGlow: return "Gentle emotional haze"
            case .filmLook: return "Cinematic contrast"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .realistic: return [.blushPink.opacity(0.6), .roseMagenta.opacity(0.4)]
            case .warmVintage: return [.softCream.opacity(0.8), .lightBlush.opacity(0.6)]
            case .softGlow: return [.memoryViolet.opacity(0.5), .lightBlush.opacity(0.4)]
            case .filmLook: return [.deepPlum.opacity(0.6), .softPlum.opacity(0.4)]
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CleanWhiteBackground()
                    .ignoresSafeArea(.all)
                
                switch currentStep {
                case .upload:
                    MergeUploadView(
                        selectedImages: $selectedImages,
                        onContinue: { 
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentStep = .styleSelection
                            }
                        },
                        onDismiss: { dismiss() },
                        geometry: geometry
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                          removal: .move(edge: .leading).combined(with: .opacity)))
                    
                case .styleSelection:
                    MergeStyleSelectionView(
                        selectedStyle: $selectedStyle,
                        onContinue: { startProcessing() },
                        onBack: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentStep = .upload
                            }
                        },
                        geometry: geometry
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                          removal: .move(edge: .leading).combined(with: .opacity)))
                    
                case .processing:
                    MergeProcessingView(
                        progress: processingProgress,
                        geometry: geometry
                    )
                    .transition(.opacity)
                    
                case .result:
                    if let processed = processedImage {
                        MergeResultView(
                            mergedImage: processed,
                            onSave: { savePhoto() },
                            onShare: { sharePhoto() },
                            onTryAnother: { resetFlow() },
                            onDismiss: { dismiss() },
                            geometry: geometry
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                errorMessage = nil
                currentStep = .upload
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onReceive(imageProcessingService.$processingProgress) { progress in
            if let p = progress {
                processingProgress = Double(p.currentStepIndex) / Double(p.totalSteps)
            }
        }
    }
    
    private func startProcessing() {
        guard selectedImages.count >= 2 else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = .processing
        }
        
        Task {
            do {
                isProcessing = true
                
                // Determine background mode based on style
                let backgroundMode: TogetherBackground
                switch selectedStyle {
                case .realistic:
                    backgroundMode = TogetherBackground(mode: .gallery)
                case .warmVintage:
                    backgroundMode = TogetherBackground(mode: .generate, prompt: "warm nostalgic sepia tones, vintage photograph atmosphere")
                case .softGlow:
                    backgroundMode = TogetherBackground(mode: .generate, prompt: "soft glowing light, gentle emotional haze, dreamy atmosphere")
                case .filmLook:
                    backgroundMode = TogetherBackground(mode: .generate, prompt: "cinematic film look, dramatic contrast, movie scene lighting")
                }
                
                let (result, subjectA, subjectB) = try await imageProcessingService.togetherPhoto(
                    subjectA: selectedImages[0],
                    subjectB: selectedImages[1],
                    background: backgroundMode
                )
                
                let merged = try await imageProcessingService.downloadProcessedImage(from: result.outputUrl)
                
                // Save to history
                do {
                    _ = try await imageProcessingService.saveToHistory(
                        imageType: "together",
                        originalImageUrl: nil,
                        processedImageUrl: result.outputUrl,
                        subjectAUrl: subjectA,
                        subjectBUrl: subjectB,
                        backgroundPrompt: backgroundMode.prompt
                    )
                } catch {
                    print("⚠️ Failed to save to history: \(error)")
                }
                
                await MainActor.run {
                    processedImage = merged
                    processedImageUrl = result.outputUrl
                    subjectAUrl = subjectA
                    subjectBUrl = subjectB
                    isProcessing = false
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentStep = .result
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func savePhoto() {
        guard let image = processedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
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
    
    private func resetFlow() {
        selectedImages = []
        selectedStyle = .realistic
        processedImage = nil
        processedImageUrl = nil
        subjectAUrl = nil
        subjectBUrl = nil
        processingProgress = 0.0
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = .upload
        }
    }
}

// MARK: - Screen 1: Upload View
struct MergeUploadView: View {
    @Binding var selectedImages: [UIImage]
    let onContinue: () -> Void
    let onDismiss: () -> Void
    let geometry: GeometryProxy
    
    @State private var showPhotoPicker = false
    @State private var currentPickerSlot: Int = 0
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                            .foregroundColor(.deepPlum)
                        
                        Text("Merge Memories")
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
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : -20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: adaptiveSpacing(32, for: geometry)) {
                    // Title and Subtitle
                    VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                        Text("Combine two photos into one beautiful moment")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                            .foregroundColor(.softPlum)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                    }
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    
                    // Two Upload Slots
                    HStack(spacing: adaptiveSpacing(16, for: geometry)) {
                        // Photo 1
                        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            UploadCard(
                                label: "Photo 1",
                                image: selectedImages.count > 0 ? selectedImages[0] : nil,
                                onTap: {
                                    currentPickerSlot = 0
                                    showPhotoPicker = true
                                },
                                geometry: geometry
                            )
                            .frame(height: geometry.size.height * 0.35)
                        }
                        
                        // Photo 2
                        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            UploadCard(
                                label: "Photo 2",
                                image: selectedImages.count > 1 ? selectedImages[1] : nil,
                                onTap: {
                                    currentPickerSlot = 1
                                    showPhotoPicker = true
                                },
                                geometry: geometry
                            )
                            .frame(height: geometry.size.height * 0.35)
                        }
                    }
                    .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 30)
                    
                    // Hint
                    Text("Use clear portraits for best results")
                        .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, adaptiveSpacing(40, for: geometry))
                        .opacity(animateElements ? 1 : 0)
                }
                .padding(.top, adaptiveSpacing(20, for: geometry))
                .padding(.bottom, adaptiveSpacing(100, for: geometry))
            }
            
            Spacer()
            
            // Continue Button
            if selectedImages.count >= 2 {
                Button(action: onContinue) {
                    HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                        Text("Continue")
                            .font(.system(size: adaptiveFontSize(17, for: geometry), weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: adaptiveSize(56, for: geometry))
                    .background(LinearGradient.primaryBrand)
                    .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                    .shadow(color: Color.blushPink.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 40)
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
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateElements = true
            }
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if currentPickerSlot == 0 {
                            if selectedImages.count > 0 {
                                selectedImages[0] = image
                            } else {
                                selectedImages.append(image)
                            }
                        } else {
                            if selectedImages.count > 1 {
                                selectedImages[1] = image
                            } else {
                                selectedImages.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
    
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        // iPhone SE (375pt) = 12pt, iPhone 15 Pro (393pt) = 14pt, iPhone 15 Pro Max (430pt) = 16pt
        return max(12, min(16, screenWidth * 0.04))
    }
}

// MARK: - Screen 2: Style Selection View
struct MergeStyleSelectionView: View {
    @Binding var selectedStyle: MemoryMergeFlow.MergeStyle
    let onContinue: () -> Void
    let onBack: () -> Void
    let geometry: GeometryProxy
    
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                            .foregroundColor(.deepPlum)
                        
                        Text("Choose a Style")
                            .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
            .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 16 : 24)
            .padding(.bottom, adaptiveSpacing(16, for: geometry))
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : -20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: adaptiveSpacing(20, for: geometry)) {
                    ForEach(MemoryMergeFlow.MergeStyle.allCases, id: \.self) { style in
                        StyleCard(
                            style: style,
                            isSelected: selectedStyle == style,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedStyle = style
                                }
                            },
                            geometry: geometry
                        )
                    }
                }
                .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                .padding(.top, adaptiveSpacing(20, for: geometry))
                .padding(.bottom, adaptiveSpacing(100, for: geometry))
            }
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : 30)
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                    Text("Continue")
                        .font(.system(size: adaptiveFontSize(17, for: geometry), weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: adaptiveSize(56, for: geometry))
                .background(LinearGradient.primaryBrand)
                .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                .shadow(color: Color.blushPink.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateElements = true
            }
        }
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
}

// MARK: - Style Card Component
struct StyleCard: View {
    let style: MemoryMergeFlow.MergeStyle
    let isSelected: Bool
    let onSelect: () -> Void
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: adaptiveSpacing(16, for: geometry)) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: style.gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: adaptiveSize(60, for: geometry), height: adaptiveSize(60, for: geometry))
                    
                    Image(systemName: style.icon)
                        .font(.system(size: adaptiveFontSize(24, for: geometry), weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                    Text(style.rawValue)
                        .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .bold))
                        .foregroundColor(.deepPlum)
                    
                    Text(style.description)
                        .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .regular))
                        .foregroundColor(.softPlum)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: adaptiveFontSize(24, for: geometry), weight: .semibold))
                        .foregroundStyle(LinearGradient.primaryBrand)
                }
            }
            .padding(adaptiveSpacing(20, for: geometry))
            .background(Color.pureWhite)
            .overlay(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                    .stroke(isSelected ? LinearGradient.primaryBrand : LinearGradient.cardGlow, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(adaptiveCornerRadius(16, for: geometry))
            .shadow(
                color: isSelected ? Color.blushPink.opacity(0.2) : Color.cardShadow,
                radius: isSelected ? 12 : 4,
                x: 0,
                y: isSelected ? 6 : 2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
}

// MARK: - Screen 3: Processing View
struct MergeProcessingView: View {
    let progress: Double
    let geometry: GeometryProxy
    
    var body: some View {
        ProgressAnimation(
            title: "Creating your merged memory…",
            subtitle: "Aligning faces, matching lighting, blending details…",
            progress: progress,
            geometry: geometry
        )
    }
}

// MARK: - Screen 4: Result View
struct MergeResultView: View {
    let mergedImage: UIImage
    let onSave: () -> Void
    let onShare: () -> Void
    let onTryAnother: () -> Void
    let onDismiss: () -> Void
    let geometry: GeometryProxy
    
    @State private var animateElements = false
    @State private var isSaved = false
    @State private var imageScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                            .foregroundColor(.deepPlum)
                        
                        Text("Your Merged Photo")
                            .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
            .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 16 : 24)
            .padding(.bottom, adaptiveSpacing(16, for: geometry))
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : -20)
            
            // Merged Image with Zoom
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                Image(uiImage: mergedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width - adaptiveSpacing(40, for: geometry))
                    .scaleEffect(imageScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale in
                                imageScale = min(max(scale, 1.0), 3.0)
                            }
                    )
            }
            .frame(height: geometry.size.height * 0.6)
            .opacity(animateElements ? 1 : 0)
            .scaleEffect(animateElements ? 1.0 : 0.95)
            
            // Pinch hint
            Text("Pinch to zoom")
                .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .medium))
                .foregroundColor(.softPlum)
                .padding(.top, adaptiveSpacing(16, for: geometry))
                .opacity(animateElements ? 1 : 0)
            
            Spacer()
            
            // Action Buttons
            ResultActionButtons(
                onSave: {
                    onSave()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isSaved = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isSaved = false
                        }
                    }
                },
                onShare: onShare,
                onTryAnother: onTryAnother,
                geometry: geometry,
                isSaved: isSaved
            )
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateElements = true
            }
        }
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return base * (screenWidth / 375.0)
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
}

#Preview {
    MemoryMergeFlow()
        .environmentObject(ImageProcessingService.shared)
}

