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
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var sliderPosition: CGFloat = 0.5
    @State private var isColorizeEnabled = false
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var showPrivacyInfo = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavBarExpanded = true
    @State private var showPermissionRequest = false
    @State private var permissionState: PermissionState = .notRequested
    @State private var showImportView = false
    @State private var selectedPhotos: [ImportedPhoto] = []
    @State private var beforeImage: UIImage?
    @State private var afterImage: UIImage?
    @State private var showBackgroundGallery = false
    @State private var selectedBackground: BackgroundScene?
    
    private func navBarHeight(for geometry: GeometryProxy) -> CGFloat {
        ResponsiveDesign.adaptiveNavBarHeight(baseHeight: 80, for: geometry)
    }
    
    private func collapsedNavBarHeight(for geometry: GeometryProxy) -> CGFloat {
        ResponsiveDesign.adaptiveNavBarHeight(baseHeight: 60, for: geometry)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.warmLinen.opacity(0.3),
                        Color.sky.opacity(0.1),
                        Color.honeyGold.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                // Permission Check
                if !permissionManager.isPhotoLibraryAuthorized {
                    PermissionCheckView()
                        .padding(.top, geometry.safeAreaInsets.top)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                } else {
                
                VStack(spacing: 0) {
                    // Top Liquid Glass Accessory Bar
                    LiquidGlassAccessoryBar(
                        isColorizeEnabled: $isColorizeEnabled,
                        showPrivacyInfo: $showPrivacyInfo,
                        showBackgroundGallery: $showBackgroundGallery,
                        isProcessing: isProcessing,
                        isExpanded: isNavBarExpanded
                    )
                    .frame(height: isNavBarExpanded ? navBarHeight(for: geometry) : collapsedNavBarHeight(for: geometry))
                    .animation(.easeInOut(duration: 0.3), value: isNavBarExpanded)
                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Main Content Area
                    ScrollView {
                        VStack(spacing: 0) {
                            // Edge-to-edge Before/After Image
                            BeforeAfterImageView(
                                beforeImage: beforeImage,
                                afterImage: afterImage,
                                sliderPosition: $sliderPosition,
                                isProcessing: isProcessing,
                                processingProgress: processingProgress,
                                onSelectPhoto: {
                                    showImportView = true
                                }
                            )
                            .frame(height: geometry.size.height * 0.6)
                            .clipped()
                            
                            // Content below image
                            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                                // Image Info Section
                                ImageInfoSection()
                                
                                // Processing Status (when active)
                                if isProcessing {
                                    ProcessingStatusView(progress: processingProgress)
                                }
                                
                                // Action Buttons
                                ActionButtonsSection(
                                    isProcessing: isProcessing,
                                    onCreatePreview: createPreview
                                )
                            }
                            .padding(ModernDesignSystem.Spacing.lg)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + ResponsiveDesign.adaptiveSpacing(baseSpacing: ModernDesignSystem.Spacing.lg, for: geometry))
                        }
                    }
                    .scrollIndicators(.hidden)
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scroll")).minY)
                        }
                    )
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isNavBarExpanded = scrollOffset > -50
                        }
                    }
                    .coordinateSpace(name: "scroll")
                }
                }
            }
        }
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showPrivacyInfo) {
            PrivacyInfoSheet()
        }
        .sheet(isPresented: $showImportView) {
            ImportView(mode: .restore, isPresented: $showImportView, selectedPhotos: $selectedPhotos)
                .onDisappear {
                    // Handle imported photos when ImportView is dismissed
                    if !selectedPhotos.isEmpty {
                        loadImportedPhotos()
                    }
                }
        }
        .backgroundGallerySheet(
            isPresented: $showBackgroundGallery,
            selectedBackground: $selectedBackground
        )
        .onAppear {
            checkPermissions()
        }
    }
    
    // MARK: - Private Methods
    private func checkPermissions() {
        let result = permissionManager.checkRequiredPermissions(for: .photoRestore)
        if !result.canProceed {
            permissionState = .denied
        } else {
            permissionState = .granted
        }
    }
    
    private func loadImportedPhotos() {
        // Load the first imported photo as the before image
        if let firstPhoto = selectedPhotos.first {
            beforeImage = firstPhoto.image
            // For demo purposes, create a mock "after" image
            afterImage = createMockAfterImage(from: firstPhoto.image)
        }
    }
    
    private func createMockAfterImage(from image: UIImage) -> UIImage {
        // This is a mock implementation - in real app, this would be the AI-restored image
        // For now, we'll just return the same image with a slight color adjustment
        return image
    }
    
    // MARK: - Private Methods
    private func createPreview() {
        isProcessing = true
        processingProgress = 0.0
        
        // Simulate processing with progress updates
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            processingProgress += 0.05
            
            if processingProgress >= 1.0 {
                timer.invalidate()
                isProcessing = false
                processingProgress = 0.0
                
                // Show success state or navigate to results
                print("Preview created successfully!")
            }
        }
    }
}

// MARK: - Liquid Glass Accessory Bar
struct LiquidGlassAccessoryBar: View {
    @Binding var isColorizeEnabled: Bool
    @Binding var showPrivacyInfo: Bool
    @Binding var showBackgroundGallery: Bool
    let isProcessing: Bool
    let isExpanded: Bool
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            ColorizeToggleSection(
                isColorizeEnabled: $isColorizeEnabled,
                isExpanded: isExpanded
            )
            
            BackgroundSelectionButton(
                showBackgroundGallery: $showBackgroundGallery,
                isExpanded: isExpanded
            )
            
            Spacer()
            
            InfoIconButton(showPrivacyInfo: $showPrivacyInfo)
            
            PrimaryActionButton(
                isProcessing: isProcessing,
                isExpanded: isExpanded
            )
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: -2
        )
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.top, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Liquid Glass Accessory Bar Components
struct ColorizeToggleSection: View {
    @Binding var isColorizeEnabled: Bool
    let isExpanded: Bool
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.charcoal.opacity(0.7))
            
            if isExpanded {
                Text("Gentle colorize")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.8))
            }
            
            Toggle("", isOn: $isColorizeEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .honeyGold))
                .scaleEffect(0.8)
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.md)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct BackgroundSelectionButton: View {
    @Binding var showBackgroundGallery: Bool
    let isExpanded: Bool
    
    var body: some View {
        Button(action: {
            showBackgroundGallery = true
        }) {
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.7))
                
                if isExpanded {
                    Text("Background")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.8))
                }
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoIconButton: View {
    @Binding var showPrivacyInfo: Bool
    
    var body: some View {
        Button(action: {
            showPrivacyInfo = true
        }) {
            Image(systemName: "info.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.charcoal.opacity(0.7))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PrimaryActionButton: View {
    let isProcessing: Bool
    let isExpanded: Bool
    
    var body: some View {
        Button(action: {
            // Handle create preview action
        }) {
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .charcoal))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .medium))
                }
                
                if isExpanded {
                    Text(isProcessing ? "Processing..." : "Create Preview")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.charcoal)
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(Color.honeyGold)
                    .shadow(
                        color: Color.honeyGold.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isProcessing)
    }
}

// MARK: - Before/After Image View
struct BeforeAfterImageView: View {
    let beforeImage: UIImage?
    let afterImage: UIImage?
    @Binding var sliderPosition: CGFloat
    let isProcessing: Bool
    let processingProgress: Double
    let onSelectPhoto: () -> Void
    
    var body: some View {
        ZStack {
            if let beforeImage = beforeImage, let afterImage = afterImage {
                // Show before/after comparison
                ZStack {
                    // Background image (before)
                    Image(uiImage: beforeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    
                    // Foreground image (after) with mask
                    Image(uiImage: afterImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .mask(
                            Rectangle()
                                .frame(width: UIScreen.main.bounds.width * sliderPosition)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        )
                    
                    // Slider Line
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .position(x: UIScreen.main.bounds.width * sliderPosition, y: UIScreen.main.bounds.height * 0.3)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 0)
                    
                    // Slider Thumb with Tactile Shadow
                    SliderThumbView()
                        .position(x: UIScreen.main.bounds.width * sliderPosition, y: UIScreen.main.bounds.height * 0.3)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newPosition = max(0, min(1, value.location.x / UIScreen.main.bounds.width))
                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                        sliderPosition = newPosition
                                    }
                                }
                        )
                }
            } else {
                // Show photo selection prompt
                PhotoSelectionPrompt(onSelectPhoto: onSelectPhoto)
            }
            
            // Processing Overlay
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: ModernDesignSystem.Spacing.lg) {
                        // Progress Ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 6)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: processingProgress)
                                .stroke(Color.honeyGold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.2), value: processingProgress)
                            
                            Text("\(Int(processingProgress * 100))%")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Creating your preview...")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - Slider Thumb View
struct SliderThumbView: View {
    var body: some View {
        ZStack {
            // Tactile shadow
            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: 32, height: 32)
                .offset(x: 2, y: 2)
            
            // Main thumb
            Circle()
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color.honeyGold, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Center dot
            Circle()
                .fill(Color.honeyGold)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Image Info Section
struct ImageInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                    Text("Restore Preview")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                    
                    Text("Drag the slider to compare before and after")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
                
                Spacer()
                
                // Quality indicator
                HStack(spacing: ModernDesignSystem.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.fern)
                    
                    Text("High Quality")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.fern)
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.md)
                .padding(.vertical, ModernDesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                        .fill(Color.fern.opacity(0.1))
                )
            }
            
            // Tips section
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                Text("Tips for best results:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    TipRow(icon: "photo", text: "Use original resolution photos (3000px+)")
                    TipRow(icon: "lightbulb", text: "Good lighting in original photos works best")
                    TipRow(icon: "eye", text: "Gentle colorize adds realistic colors")
                }
            }
            .padding(ModernDesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(Color.white.opacity(0.05))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.honeyGold)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.charcoal.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - Processing Status View
struct ProcessingStatusView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                Text("Processing your photo...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Spacer()
            }
            
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .honeyGold))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("This usually takes 10-30 seconds")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.charcoal.opacity(0.6))
        }
        .padding(ModernDesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    let isProcessing: Bool
    let onCreatePreview: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // Primary Action Button
            Button(action: onCreatePreview) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Create Preview")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.charcoal)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.honeyGold)
                .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                .shadow(
                    color: Color.honeyGold.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.6 : 1.0)
            
            // Secondary Actions
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                Button(action: {
                    // Handle save action
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Save")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.charcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .cornerRadius(ModernDesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)
                
                Button(action: {
                    // Handle share action
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Share")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.charcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .cornerRadius(ModernDesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)
            }
        }
    }
}

// MARK: - Privacy Info Sheet
struct PrivacyInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.honeyGold)
                    
                    Text("What happens to your photo")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ModernDesignSystem.Spacing.lg)
                
                // Content
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.lg) {
                    PrivacyPoint(
                        icon: "eye.slash",
                        title: "Your photos are private",
                        description: "We never share your photos with anyone. They're processed securely and deleted after restoration."
                    )
                    
                    PrivacyPoint(
                        icon: "lock.fill",
                        title: "Secure processing",
                        description: "All processing happens on secure servers with encryption. Your photos are never stored permanently."
                    )
                    
                    PrivacyPoint(
                        icon: "trash",
                        title: "Automatic deletion",
                        description: "Photos are automatically deleted from our servers within 24 hours of processing."
                    )
                    
                    PrivacyPoint(
                        icon: "checkmark.shield",
                        title: "No AI training",
                        description: "Your photos are never used to train our AI models. Each restoration is completely private."
                    )
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                
                Spacer()
                
                // Action Button
                Button(action: {
                    dismiss()
                }) {
                    Text("I understand")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.charcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.honeyGold)
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                .padding(.bottom, ModernDesignSystem.Spacing.lg)
            }
            .background(Color.warmLinen)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.honeyGold)
                }
            }
        }
    }
}

// MARK: - Privacy Point
struct PrivacyPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: ModernDesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.honeyGold)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Text(description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.8))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(ModernDesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Permission Check View
struct PermissionCheckView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var permissionState: PermissionState = .notRequested
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.xl) {
            Spacer()
            
            if permissionState == .denied {
                PermissionDeniedView(
                    permissionType: .photoLibrary,
                    onOpenSettings: {
                        permissionManager.openAppSettings()
                    },
                    onRetry: {
                        checkPermissions()
                    }
                )
            } else {
                PermissionRequestView(
                    permissionType: .photoLibrary,
                    onRequest: {
                        requestPermission()
                    }
                )
            }
            
            Spacer()
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        permissionManager.updatePermissionStatuses()
        if permissionManager.isPhotoLibraryAuthorized {
            permissionState = .granted
        } else if permissionManager.photoLibraryStatus == .denied || permissionManager.photoLibraryStatus == .restricted {
            permissionState = .denied
        } else {
            permissionState = .notRequested
        }
    }
    
    private func requestPermission() {
        Task {
            let status = await permissionManager.requestPhotoLibraryPermission()
            await MainActor.run {
                if status == .authorized || status == .limited {
                    permissionState = .granted
                } else {
                    permissionState = .denied
                }
            }
        }
    }
}

// MARK: - Photo Selection Prompt
struct PhotoSelectionPrompt: View {
    let onSelectPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.honeyGold.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.honeyGold)
                }
                
                // Content
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    Text("Select a Photo to Restore")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose a photo from your library to see the before and after restoration")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // Action Button
                Button(action: onSelectPhoto) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Choose Photo")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.charcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.honeyGold)
                    .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                    .shadow(
                        color: Color.honeyGold.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .buttonStyle(PlainButtonStyle())
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
            
            Spacer()
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
}
