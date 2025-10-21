//
//  ProcessingSettingsView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct ProcessingSettingsView: View {
    let mode: ImportMode
    @Binding var settings: ProcessingSettings
    @Binding var isPresented: Bool
    
    @State private var selectedQuality: ImageProcessingQuality
    @State private var selectedFormat: ImageProcessingFormat
    @State private var selectedAspectRatio: AspectRatio
    @State private var backgroundMode: BackgroundMode
    @State private var backgroundPrompt: String
    @State private var useUltra: Bool
    @State private var warmth: Double
    @State private var shadows: Double
    @State private var grain: Double
    @State private var seed: String
    
    init(mode: ImportMode, settings: Binding<ProcessingSettings>, isPresented: Binding<Bool>) {
        self.mode = mode
        self._settings = settings
        self._isPresented = isPresented
        
        // Initialize state from current settings
        self._selectedQuality = State(initialValue: settings.wrappedValue.qualityTarget)
        self._selectedFormat = State(initialValue: settings.wrappedValue.outputFormat)
        self._selectedAspectRatio = State(initialValue: settings.wrappedValue.aspectRatio)
        self._backgroundMode = State(initialValue: settings.wrappedValue.background?.mode ?? .generate)
        self._backgroundPrompt = State(initialValue: settings.wrappedValue.background?.prompt ?? "")
        self._useUltra = State(initialValue: settings.wrappedValue.background?.useUltra ?? false)
        self._warmth = State(initialValue: settings.wrappedValue.lookControls?.warmth ?? 0.0)
        self._shadows = State(initialValue: settings.wrappedValue.lookControls?.shadows ?? 0.0)
        self._grain = State(initialValue: settings.wrappedValue.lookControls?.grain ?? 0.0)
        self._seed = State(initialValue: settings.wrappedValue.seed?.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernDesignSystem.Spacing.lg) {
                    // Quality Settings
                    SettingsSection(title: "Quality", icon: "star.fill") {
                        VStack(spacing: ModernDesignSystem.Spacing.md) {
                            ForEach(ImageProcessingQuality.allCases, id: \.self) { quality in
                                QualityOptionView(
                                    quality: quality,
                                    isSelected: selectedQuality == quality
                                ) {
                                    selectedQuality = quality
                                }
                            }
                        }
                    }
                    
                    // Format Settings
                    SettingsSection(title: "Output Format", icon: "photo") {
                        VStack(spacing: ModernDesignSystem.Spacing.sm) {
                            ForEach(ImageProcessingFormat.allCases, id: \.self) { format in
                                FormatOptionView(
                                    format: format,
                                    isSelected: selectedFormat == format
                                ) {
                                    selectedFormat = format
                                }
                            }
                        }
                    }
                    
                    // Aspect Ratio Settings
                    SettingsSection(title: "Aspect Ratio", icon: "rectangle") {
                        VStack(spacing: ModernDesignSystem.Spacing.sm) {
                            ForEach(AspectRatio.allCases, id: \.self) { aspectRatio in
                                AspectRatioOptionView(
                                    aspectRatio: aspectRatio,
                                    isSelected: selectedAspectRatio == aspectRatio
                                ) {
                                    selectedAspectRatio = aspectRatio
                                }
                            }
                        }
                    }
                    
                    // Background Settings (for Together mode)
                    if mode == .together {
                        SettingsSection(title: "Background", icon: "photo.stack") {
                            VStack(spacing: ModernDesignSystem.Spacing.md) {
                                // Background Mode
                                VStack(spacing: ModernDesignSystem.Spacing.sm) {
                                    ForEach(BackgroundMode.allCases, id: \.self) { mode in
                                        BackgroundModeOptionView(
                                            mode: mode,
                                            isSelected: backgroundMode == mode
                                        ) {
                                            backgroundMode = mode
                                        }
                                    }
                                }
                                
                                // Background Prompt (for generate mode)
                                if backgroundMode == .generate {
                                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                                        Text("Background Prompt")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.charcoal)
                                        
                                        TextField("Describe the background you want...", text: $backgroundPrompt)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .font(.system(size: 16))
                                    }
                                    
                                    Toggle("Use Ultra Model", isOn: $useUltra)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.charcoal)
                                }
                            }
                        }
                    }
                    
                    // Look Controls
                    SettingsSection(title: "Look Controls", icon: "slider.horizontal.3") {
                        VStack(spacing: ModernDesignSystem.Spacing.md) {
                            // Warmth
                            LookControlSlider(
                                title: "Warmth",
                                value: $warmth,
                                range: -1.0...1.0,
                                icon: "sun.max"
                            )
                            
                            // Shadows
                            LookControlSlider(
                                title: "Shadows",
                                value: $shadows,
                                range: 0.0...1.0,
                                icon: "moon"
                            )
                            
                            // Grain
                            LookControlSlider(
                                title: "Grain",
                                value: $grain,
                                range: 0.0...1.0,
                                icon: "sparkles"
                            )
                        }
                    }
                    
                    // Seed Settings
                    SettingsSection(title: "Random Seed", icon: "dice") {
                        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                            Text("Seed (optional)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.charcoal)
                            
                            TextField("Leave empty for random", text: $seed)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                                .keyboardType(.numberPad)
                            
                            Text("Use the same seed to get consistent results")
                                .font(.system(size: 12))
                                .foregroundColor(.charcoal.opacity(0.6))
                        }
                    }
                }
                .padding(ModernDesignSystem.Spacing.lg)
            }
            .navigationTitle("Processing Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveSettings() {
        let background = mode == .together ? TogetherBackground(
            mode: backgroundMode,
            prompt: backgroundMode == .generate ? backgroundPrompt : nil,
            useUltra: useUltra
        ) : nil
        
        let lookControls = LookControls(
            warmth: warmth,
            shadows: shadows,
            grain: grain
        )
        
        let seedValue = Int(seed.isEmpty ? "" : seed)
        
        settings = ProcessingSettings(
            qualityTarget: selectedQuality,
            outputFormat: selectedFormat,
            aspectRatio: selectedAspectRatio,
            background: background,
            lookControls: lookControls,
            seed: seedValue
        )
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Spacer()
            }
            
            content
        }
        .padding(ModernDesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Quality Option View
struct QualityOptionView: View {
    let quality: ImageProcessingQuality
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text(quality.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.charcoal)
                    
                    Text(quality.description)
                        .font(.system(size: 14))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.honeyGold)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.charcoal.opacity(0.3))
                }
            }
            .padding(ModernDesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(isSelected ? Color.honeyGold.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .stroke(isSelected ? Color.honeyGold.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Format Option View
struct FormatOptionView: View {
    let format: ImageProcessingFormat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(format.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.honeyGold)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.charcoal.opacity(0.3))
                }
            }
            .padding(ModernDesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(isSelected ? Color.honeyGold.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .stroke(isSelected ? Color.honeyGold.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Aspect Ratio Option View
struct AspectRatioOptionView: View {
    let aspectRatio: AspectRatio
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text(aspectRatio.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.charcoal)
                    
                    Text(aspectRatio.description)
                        .font(.system(size: 14))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.honeyGold)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.charcoal.opacity(0.3))
                }
            }
            .padding(ModernDesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(isSelected ? Color.honeyGold.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .stroke(isSelected ? Color.honeyGold.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Background Mode Option View
struct BackgroundModeOptionView: View {
    let mode: BackgroundMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.charcoal)
                    
                    Text(mode.description)
                        .font(.system(size: 14))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.honeyGold)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.charcoal.opacity(0.3))
                }
            }
            .padding(ModernDesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(isSelected ? Color.honeyGold.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .stroke(isSelected ? Color.honeyGold.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Look Control Slider
struct LookControlSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.7))
            }
            
            Slider(value: $value, in: range)
                .accentColor(.honeyGold)
        }
    }
}

#Preview {
    ProcessingSettingsView(
        mode: .restore,
        settings: .constant(ProcessingSettings()),
        isPresented: .constant(true)
    )
}
