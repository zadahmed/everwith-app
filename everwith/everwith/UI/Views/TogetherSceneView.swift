//
//  TogetherSceneView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct TogetherSceneView: View {
    @State private var selectedBackground: BackgroundScene?
    @State private var warmth: Double = 0.5
    @State private var shadow: Double = 0.5
    @State private var grain: Double = 0.3
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var showBackgroundGallery = false
    @State private var showConsentModal = false
    @State private var firstCompositeConsentGiven = false
    @State private var showExportView = false
    
    // Mock data for demonstration
    @State private var subjectA: UIImage? = UIImage(systemName: "person.circle.fill")
    @State private var subjectB: UIImage? = UIImage(systemName: "person.circle.fill")
    @State private var previewImage: UIImage?
    
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
                
                VStack(spacing: 0) {
                    // Top Navigation Bar
                    TogetherNavigationBar(
                        onBack: {
                            // Navigate back to Home
                        },
                        onExport: {
                            if !firstCompositeConsentGiven {
                                showConsentModal = true
                            } else {
                                showExportView = true
                            }
                        }
                    )
                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Main Canvas Area
                    ZStack {
                        // Background Preview
                        if let background = selectedBackground {
                            BackgroundPreviewView(background: background)
                                .ignoresSafeArea()
                        } else {
                            // Default background
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.warmLinen.opacity(0.5),
                                    Color.sky.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .ignoresSafeArea()
                        }
                        
                        // Canvas with cutouts
                        TogetherCanvas(
                            subjectA: subjectA,
                            subjectB: subjectB,
                            warmth: warmth,
                            shadow: shadow,
                            grain: grain,
                            isProcessing: isProcessing,
                            processingProgress: processingProgress
                        )
                        
                        // Floating Controls
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                VStack(spacing: ModernDesignSystem.Spacing.md) {
                                    // Background Picker
                                    Button(action: {
                                        showBackgroundGallery = true
                                    }) {
                                        HStack(spacing: ModernDesignSystem.Spacing.sm) {
                                            Image(systemName: "photo.on.rectangle")
                                                .font(.system(size: 16, weight: .medium))
                                            
                                            Text("Background")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.charcoal)
                                        .padding(.horizontal, ModernDesignSystem.Spacing.md)
                                        .padding(.vertical, ModernDesignSystem.Spacing.sm)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.9))
                                                .background(.ultraThinMaterial)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Parameter Controls
                                    VStack(spacing: ModernDesignSystem.Spacing.sm) {
                                        ParameterControl(
                                            title: "Warmth",
                                            value: $warmth,
                                            icon: "sun.max.fill",
                                            color: .honeyGold
                                        )
                                        
                                        ParameterControl(
                                            title: "Shadow",
                                            value: $shadow,
                                            icon: "moon.fill",
                                            color: .charcoal
                                        )
                                        
                                        ParameterControl(
                                            title: "Grain",
                                            value: $grain,
                                            icon: "sparkles",
                                            color: .sky
                                        )
                                    }
                                    .padding(ModernDesignSystem.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                                            .fill(Color.white.opacity(0.9))
                                            .background(.ultraThinMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    
                                    // Auto-balance Button
                                    Button(action: {
                                        autoBalanceParameters()
                                    }) {
                                        HStack(spacing: ModernDesignSystem.Spacing.sm) {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 16, weight: .medium))
                                            
                                            Text("Auto-balance")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.charcoal)
                                        .padding(.horizontal, ModernDesignSystem.Spacing.md)
                                        .padding(.vertical, ModernDesignSystem.Spacing.sm)
                                        .background(
                                            Capsule()
                                                .fill(Color.honeyGold.opacity(0.9))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.trailing, ModernDesignSystem.Spacing.lg)
                                .padding(.bottom, geometry.safeAreaInsets.bottom + ModernDesignSystem.Spacing.lg)
                            }
                        }
                    }
                }
            }
        }
        .backgroundGallerySheet(
            isPresented: $showBackgroundGallery,
            selectedBackground: $selectedBackground
        )
        .sheet(isPresented: $showConsentModal) {
            ConsentModal(
                isPresented: $showConsentModal,
                onConfirm: {
                    firstCompositeConsentGiven = true
                    showExportView = true
                }
            )
        }
        .sheet(isPresented: $showExportView) {
            ExportView()
        }
        .onAppear {
            // Auto-run initial preview
            runInitialPreview()
        }
    }
    
    // MARK: - Private Methods
    private func runInitialPreview() {
        isProcessing = true
        processingProgress = 0.0
        
        // Simulate processing
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            processingProgress += 0.05
            
            if processingProgress >= 1.0 {
                timer.invalidate()
                isProcessing = false
                processingProgress = 0.0
                // Set preview image
                previewImage = UIImage(systemName: "photo.fill")
            }
        }
    }
    
    private func autoBalanceParameters() {
        withAnimation(.easeInOut(duration: 0.5)) {
            warmth = 0.6
            shadow = 0.4
            grain = 0.2
        }
        
        // Trigger preview update
        updatePreview()
    }
    
    private func updatePreview() {
        // Simulate preview update
        isProcessing = true
        processingProgress = 0.0
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            processingProgress += 0.1
            
            if processingProgress >= 1.0 {
                timer.invalidate()
                isProcessing = false
                processingProgress = 0.0
            }
        }
    }
}

// MARK: - Together Navigation Bar
struct TogetherNavigationBar: View {
    let onBack: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        HStack {
            // Back Button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.charcoal)
            }
            
            Spacer()
            
            // Title
            Text("Together Scene")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.charcoal)
            
            Spacer()
            
            // Export Button
            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.charcoal)
            }
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

// MARK: - Together Canvas
struct TogetherCanvas: View {
    let subjectA: UIImage?
    let subjectB: UIImage?
    let warmth: Double
    let shadow: Double
    let grain: Double
    let isProcessing: Bool
    let processingProgress: Double
    
    var body: some View {
        ZStack {
            // Canvas Background
            Rectangle()
                .fill(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Subject Cutouts
            HStack(spacing: ModernDesignSystem.Spacing.xl) {
                // Subject A
                SubjectCutout(
                    image: subjectA,
                    warmth: warmth,
                    shadow: shadow,
                    grain: grain
                )
                
                // Subject B
                SubjectCutout(
                    image: subjectB,
                    warmth: warmth,
                    shadow: shadow,
                    grain: grain
                )
            }
            .padding(ModernDesignSystem.Spacing.xl)
            
            // Processing Overlay
            if isProcessing {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .ignoresSafeArea()
                    
                    VStack(spacing: ModernDesignSystem.Spacing.lg) {
                        ProgressView(value: processingProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .honeyGold))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .frame(width: 200)
                        
                        Text("Updating preview...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - Subject Cutout
struct SubjectCutout: View {
    let image: UIImage?
    let warmth: Double
    let shadow: Double
    let grain: Double
    
    var body: some View {
        ZStack {
            // Cutout Shape
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(Color.white.opacity(0.1))
                .frame(width: 150, height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            // Subject Image
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 190)
                    .clipped()
                    .cornerRadius(ModernDesignSystem.CornerRadius.md)
            } else {
                VStack(spacing: ModernDesignSystem.Spacing.sm) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.5))
                    
                    Text("Subject")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Parameter Control
struct ParameterControl: View {
    let title: String
    @Binding var value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.charcoal)
                
                Spacer()
            }
            
            Slider(value: $value, in: 0...1)
                .accentColor(color)
        }
    }
}

// MARK: - Consent Modal
struct ConsentModal: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.honeyGold.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.honeyGold)
            }
            
            // Content
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                Text("Create Together Scene")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text("This will create a composite image using AI. By continuing, you consent to processing your photos for this purpose.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // Actions
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                Button(action: {
                    onConfirm()
                    isPresented = false
                }) {
                    Text("I Understand")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.charcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.honeyGold)
                        .cornerRadius(ModernDesignSystem.CornerRadius.md)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.6))
                }
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
        .background(Color.warmLinen)
        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 20,
            x: 0,
            y: 10
        )
        .padding(ModernDesignSystem.Spacing.lg)
    }
}

#Preview {
    TogetherSceneView()
}
