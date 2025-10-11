//
//  EditorView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import PhotosUI

struct EditorView: View {
    let mode: EditorMode
    @State private var selectedPhotos: [ImportedPhoto]
    @State private var isProcessing = false
    @State private var isReady = false
    @State private var showConsentSheet = false
    @State private var showAdvancedSheet = false
    @State private var hasConsent = false
    @State private var colorizeEnabled = true
    @State private var selectedBackground = "default"
    @State private var autoBalanceEnabled = true
    @State private var isFirstTimeSave = true
    @Environment(\.dismiss) private var dismiss
    
    init(mode: EditorMode, selectedPhotos: [ImportedPhoto] = []) {
        self.mode = mode
        self._selectedPhotos = State(initialValue: selectedPhotos)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Elegant background
                ElegantBackground()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top Controls
                    EditorTopControls(
                        mode: mode,
                        colorizeEnabled: $colorizeEnabled,
                        showAdvancedSheet: $showAdvancedSheet,
                        geometry: geometry
                    )
                    .padding(.top, geometry.safeAreaInsets.top + ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                    
                    // Main Content - Full Screen
                    ZStack {
                        if isProcessing {
                            ProcessingView(mode: mode, geometry: geometry)
                        } else if isReady {
                            EditorContentView(
                                mode: mode,
                                colorizeEnabled: colorizeEnabled,
                                selectedBackground: $selectedBackground,
                                autoBalanceEnabled: $autoBalanceEnabled,
                                geometry: geometry
                            )
                        } else {
                            // Initial state - start processing immediately
                            Color.clear
                                .onAppear {
                                    startProcessing()
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom Actions
                    if isReady {
                        EditorBottomActions(
                            mode: mode,
                            showConsentSheet: $showConsentSheet,
                            hasConsent: $hasConsent,
                            isFirstTimeSave: $isFirstTimeSave,
                            geometry: geometry
                        )
                        .padding(.bottom, geometry.safeAreaInsets.bottom + ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showConsentSheet) {
            ConsentSheet(hasConsent: $hasConsent)
        }
        .sheet(isPresented: $showAdvancedSheet) {
            AdvancedControlsSheet()
        }
    }
    
    private func startProcessing() {
        isProcessing = true
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isProcessing = false
                isReady = true
            }
        }
    }
}

// MARK: - Editor Mode
enum EditorMode {
    case restore
    case togetherScene
    
    var title: String {
        switch self {
        case .restore: return "Restore"
        case .togetherScene: return "Together Scene"
        }
    }
    
    var icon: String {
        switch self {
        case .restore: return "photo.badge.plus"
        case .togetherScene: return "heart.circle"
        }
    }
}

// MARK: - Editor Top Controls
struct EditorTopControls: View {
    let mode: EditorMode
    @Binding var colorizeEnabled: Bool
    @Binding var showAdvancedSheet: Bool
    let geometry: GeometryProxy
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            // Back button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal)
                    .frame(
                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 40, for: geometry),
                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 40, for: geometry)
                    )
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
            
            Spacer()
            
            // Mode-specific controls
            if mode == .restore {
                // Colorize toggle
                Button(action: {
                    colorizeEnabled.toggle()
                }) {
                    HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                        Image(systemName: "paintbrush")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                        Text("Colorize")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                        Text(colorizeEnabled ? "On" : "Off")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry), weight: .semibold))
                            .foregroundColor(colorizeEnabled ? .honeyGold : .charcoal.opacity(0.6))
                    }
                    .foregroundColor(.charcoal)
                    .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry))
                    .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .background(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            } else {
                // Advanced controls button
                Button(action: {
                    showAdvancedSheet = true
                }) {
                    HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                        Text("Advanced")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                    }
                    .foregroundColor(.charcoal)
                    .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry))
                    .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .background(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
        .padding(.bottom, ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
    }
}

// MARK: - Processing View
struct ProcessingView: View {
    let mode: EditorMode
    let geometry: GeometryProxy
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry)) {
            // Processing animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                mode == .restore ? Color.honeyGold.opacity(0.3) : Color.sky.opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 80, for: geometry)
                        )
                    )
                    .frame(
                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 160, for: geometry),
                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 160, for: geometry)
                    )
                    .blur(radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: mode == .restore ? 
                                [Color.honeyGold, Color.honeyGold.opacity(0.8)] :
                                [Color.sky, Color.fern]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry),
                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry)
                    )
                    .overlay(
                        Image(systemName: mode.icon)
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 48, for: geometry), weight: .medium))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            
            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
                Text(mode == .restore ? "Restoring your photo..." : "Creating your scene...")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 24, for: geometry), weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text(mode == .restore ? 
                     "Our AI is carefully restoring every detail" :
                     "Composing your photos with beautiful backgrounds")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Editor Content View
struct EditorContentView: View {
    let mode: EditorMode
    let colorizeEnabled: Bool
    @Binding var selectedBackground: String
    @Binding var autoBalanceEnabled: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            if mode == .restore {
                RestorePreviewView(colorizeEnabled: colorizeEnabled, geometry: geometry)
            } else {
                TogetherScenePreviewView(
                    selectedBackground: $selectedBackground,
                    autoBalanceEnabled: $autoBalanceEnabled,
                    geometry: geometry
                )
            }
        }
    }
}

// MARK: - Restore Preview View
struct RestorePreviewView: View {
    let colorizeEnabled: Bool
    let geometry: GeometryProxy
    @State private var sliderPosition: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 0) {
            // Before/After Slider
            ZStack {
                // Before image (placeholder)
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                    .fill(Color.charcoal.opacity(0.1))
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 60, for: geometry), weight: .medium))
                                .foregroundColor(.charcoal.opacity(0.6))
                            Text("Before")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                                .foregroundColor(.charcoal.opacity(0.6))
                        }
                    )
                
                // After image (placeholder)
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                    .fill(Color.honeyGold.opacity(0.1))
                    .overlay(
                        VStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 60, for: geometry), weight: .medium))
                                .foregroundColor(.honeyGold)
                            Text("After")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                                .foregroundColor(.honeyGold)
                        }
                    )
                    .mask(
                        Rectangle()
                            .offset(x: sliderPosition * UIScreen.main.bounds.width)
                    )
                
                // Slider handle
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 4, height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 100, for: geometry))
                            .overlay(
                                Circle()
                                    .fill(Color.honeyGold)
                                    .frame(
                                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry),
                                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry)
                                    )
                                    .overlay(
                                        Image(systemName: "chevron.left.chevron.right")
                                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 8, for: geometry), weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            )
                            .offset(x: sliderPosition * UIScreen.main.bounds.width)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newPosition = value.location.x / UIScreen.main.bounds.width
                        sliderPosition = max(0, min(1, newPosition))
                    }
            )
            
            Spacer()
        }
    }
}

// MARK: - Together Scene Preview View
struct TogetherScenePreviewView: View {
    @Binding var selectedBackground: String
    @Binding var autoBalanceEnabled: Bool
    let geometry: GeometryProxy
    @State private var showToolbar = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Canvas
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.sky.opacity(0.3),
                                Color.fern.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        VStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 60, for: geometry), weight: .medium))
                                .foregroundColor(.sky)
                            Text("Canvas Preview")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                                .foregroundColor(.sky)
                        }
                    )
                    .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
                
                // Compact toolbar chip
                VStack {
                    HStack {
                        Spacer()
                        CompactToolbarChip(
                            showToolbar: $showToolbar,
                            selectedBackground: $selectedBackground,
                            autoBalanceEnabled: $autoBalanceEnabled,
                            geometry: geometry
                        )
                    }
                    Spacer()
                }
                .padding(.top, ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                .padding(.trailing, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
            }
            
            Spacer()
        }
    }
}

// MARK: - Compact Toolbar Chip
struct CompactToolbarChip: View {
    @Binding var showToolbar: Bool
    @Binding var selectedBackground: String
    @Binding var autoBalanceEnabled: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 0) {
            // Main chip
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showToolbar.toggle()
                }
            }) {
                HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                    Text("Tools")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                    Image(systemName: showToolbar ? "chevron.up" : "chevron.down")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry), weight: .medium))
                }
                .foregroundColor(.charcoal)
                .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry))
                .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 10, for: geometry))
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Expanded toolbar
            if showToolbar {
                VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                    // Background button
                    Button(action: {
                        // Handle background selection
                    }) {
                        HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                            Image(systemName: "photo")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                            Text("Background")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                        }
                        .foregroundColor(.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry))
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 12, for: geometry))
                                .fill(Color.white.opacity(0.1))
                                .background(.ultraThinMaterial)
                        )
                    }
                    
                    // Auto-balance toggle
                    Button(action: {
                        autoBalanceEnabled.toggle()
                    }) {
                        HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                            Image(systemName: "sun.max")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                            Text("Auto-balance")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                            Spacer()
                            Text(autoBalanceEnabled ? "On" : "Off")
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry), weight: .semibold))
                                .foregroundColor(autoBalanceEnabled ? .honeyGold : .charcoal.opacity(0.6))
                        }
                        .foregroundColor(.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry))
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 12, for: geometry))
                                .fill(Color.white.opacity(0.1))
                                .background(.ultraThinMaterial)
                        )
                    }
                }
                .padding(.top, ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .scale(scale: 0.8))
                ))
            }
        }
    }
}

// MARK: - Editor Bottom Actions
struct EditorBottomActions: View {
    let mode: EditorMode
    @Binding var showConsentSheet: Bool
    @Binding var hasConsent: Bool
    @Binding var isFirstTimeSave: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            // Primary button
            Button(action: {
                if isFirstTimeSave && !hasConsent {
                    showConsentSheet = true
                } else {
                    // Handle save & share
                    isFirstTimeSave = false
                }
            }) {
                HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .semibold))
                    Text("Save & Share")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .semibold, design: .rounded))
                }
                .foregroundColor(.charcoal)
                .frame(maxWidth: .infinity)
                .frame(height: ResponsiveDesign.adaptiveButtonHeight(baseHeight: 56, for: geometry))
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                        .fill(Color.honeyGold)
                        .shadow(
                            color: Color.honeyGold.opacity(0.4),
                            radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry),
                            x: 0,
                            y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Secondary button
            Button(action: {
                // Handle replace photo
            }) {
                Text("Replace photo")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.8))
            }
        }
        .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
    }
}

// MARK: - Consent Sheet
struct ConsentSheet: View {
    @Binding var hasConsent: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.honeyGold)
                    
                    VStack(spacing: 8) {
                        Text("Consent Required")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.charcoal)
                            .multilineTextAlignment(.center)
                        
                        Text("Before sharing, please confirm you have permission")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.charcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 32)
                
                // Consent checkbox
                VStack(spacing: 16) {
                    Button(action: {
                        hasConsent.toggle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: hasConsent ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(hasConsent ? .honeyGold : .charcoal.opacity(0.6))
                            
                            Text("I have consent from any living person in this photo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.charcoal)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.charcoal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.honeyGold)
                                    .shadow(
                                        color: Color.honeyGold.opacity(0.3),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            )
                    }
                    .disabled(!hasConsent)
                    .opacity(hasConsent ? 1.0 : 0.6)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.charcoal.opacity(0.8))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color.warmLinen)
            .navigationTitle("Consent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Advanced Controls Sheet
struct AdvancedControlsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Advanced Controls")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                    .padding(.top, 32)
                
                VStack(spacing: 16) {
                    // Warmth slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Warmth")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.charcoal)
                        
                        Slider(value: .constant(0.5), in: 0...1)
                            .accentColor(.honeyGold)
                    }
                    
                    // Shadow slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shadow")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.charcoal)
                        
                        Slider(value: .constant(0.5), in: 0...1)
                            .accentColor(.honeyGold)
                    }
                    
                    // Grain slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grain")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.charcoal)
                        
                        Slider(value: .constant(0.5), in: 0...1)
                            .accentColor(.honeyGold)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(ModernButtonStyle(style: .primary))
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color.warmLinen)
            .navigationTitle("Advanced")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    EditorView(mode: .restore)
}

