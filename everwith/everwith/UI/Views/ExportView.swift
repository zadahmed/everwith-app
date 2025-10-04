//
//  ExportView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import AVKit
import PhotosUI
import Photos

struct ExportView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var selectedExportType: ExportType = .image
    @State private var selectedDuration: VideoDuration = .six
    @State private var isMusicEnabled = false
    @State private var watermarkStatus: WatermarkStatus = .on
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var showShareSheet = false
    @State private var exportedItem: Any? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavBarExpanded = true
    @State private var permissionState: PermissionState = .notRequested
    @State private var showImportView = false
    @State private var selectedPhotos: [ImportedPhoto] = []
    @State private var previewImage: UIImage?
    @State private var previewVideoURL: URL?
    @State private var showBackgroundGallery = false
    @State private var selectedBackground: BackgroundScene? = nil
    @State private var showShareLinkView = false
    
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
                if !hasRequiredPermissions() {
                    ExportPermissionCheckView()
                        .padding(.top, geometry.safeAreaInsets.top)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                } else {
                VStack(spacing: 0) {
                    // Top Simplified Toolbar
                    SimplifiedToolbar(
                        showBackgroundGallery: $showBackgroundGallery,
                        isExpanded: isNavBarExpanded,
                        isExporting: isExporting
                    )
                    .frame(height: isNavBarExpanded ? navBarHeight(for: geometry) : collapsedNavBarHeight(for: geometry))
                    .animation(.easeInOut(duration: 0.3), value: isNavBarExpanded)
                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Main Content Area
                    ScrollView {
                        VStack(spacing: 0) {
                            // Export Type Segmented Control
                            ExportTypeSelector(selectedType: $selectedExportType)
                                .padding(.top, ModernDesignSystem.Spacing.lg)
                            
                            // Preview Section
                            PreviewSection(
                                exportType: selectedExportType,
                                previewImage: previewImage,
                                previewVideoURL: previewVideoURL,
                                onSelectPhoto: {
                                    showImportView = true
                                }
                            )
                            .padding(.top, ModernDesignSystem.Spacing.lg)
                            
                            // Options Section
                            OptionsSection(
                                exportType: selectedExportType,
                                selectedDuration: $selectedDuration,
                                isMusicEnabled: $isMusicEnabled,
                                watermarkStatus: $watermarkStatus
                            )
                            .padding(.top, ModernDesignSystem.Spacing.lg)
                            
                            // Export Status (when exporting)
                            if isExporting {
                                ExportProgressView(progress: exportProgress)
                                    .padding(.top, ModernDesignSystem.Spacing.lg)
                            }
                            
                            // Action Buttons
                            ExportActionButtonsSection(
                                exportType: selectedExportType,
                                isExporting: isExporting,
                                onSave: saveExport,
                                onShare: shareExport,
                                onCreateLink: {
                                    showShareLinkView = true
                                }
                            )
                            .padding(.top, ModernDesignSystem.Spacing.lg)
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
        .sheet(isPresented: $showShareSheet) {
            if let item = exportedItem {
                ShareSheet(items: [item])
            }
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
        .sheet(isPresented: $showShareLinkView) {
            ShareLinkView(isPresented: $showShareLinkView)
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    // MARK: - Private Methods
    private func hasRequiredPermissions() -> Bool {
        let feature: AppFeature = selectedExportType == .video ? .videoExport : .photoExport
        let result = permissionManager.checkRequiredPermissions(for: feature)
        return result.canProceed
    }
    
    private func checkPermissions() {
        let feature: AppFeature = selectedExportType == .video ? .videoExport : .photoExport
        let result = permissionManager.checkRequiredPermissions(for: feature)
        if !result.canProceed {
            permissionState = .denied
        } else {
            permissionState = .granted
        }
    }
    
    private func loadImportedPhotos() {
        // Load the first imported photo as the preview image
        if let firstPhoto = selectedPhotos.first {
            previewImage = firstPhoto.image
        }
    }
    
    // MARK: - Private Methods
    private func saveExport() {
        isExporting = true
        exportProgress = 0.0
        
        // Simulate export process
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            exportProgress += 0.05
            
            if exportProgress >= 1.0 {
                timer.invalidate()
                isExporting = false
                exportProgress = 0.0
                
                // Set exported item for sharing
                exportedItem = selectedExportType == .image ? previewImage : previewVideoURL
                
                // Show success feedback
                print("Export completed successfully!")
            }
        }
    }
    
    private func shareExport() {
        if let item = exportedItem {
            showShareSheet = true
        } else {
            // If no exported item, create one for sharing
            exportedItem = selectedExportType == .image ? previewImage : previewVideoURL
            showShareSheet = true
        }
    }
}

// MARK: - Export Type Enum
enum ExportType: String, CaseIterable {
    case image = "image"
    case video = "video"
    
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        }
    }
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        }
    }
}

// MARK: - Video Duration Enum
enum VideoDuration: String, CaseIterable {
    case six = "6s"
    case eight = "8s"
    case twelve = "12s"
    
    var displayName: String {
        return self.rawValue
    }
    
    var duration: TimeInterval {
        switch self {
        case .six: return 6.0
        case .eight: return 8.0
        case .twelve: return 12.0
        }
    }
}

// MARK: - Watermark Status Enum
enum WatermarkStatus: String, CaseIterable {
    case on = "on"
    case off = "off"
    
    var displayName: String {
        switch self {
        case .on: return "On"
        case .off: return "Off"
        }
    }
    
    var isVisible: Bool {
        return self == .on
    }
}

// MARK: - Simplified Toolbar
struct SimplifiedToolbar: View {
    @Binding var showBackgroundGallery: Bool
    let isExpanded: Bool
    let isExporting: Bool
    
    var body: some View {
        HStack {
            // Back button
            Button(action: {
                // Handle back action
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.charcoal)
            }
            
            Spacer()
            
            // Title
            if isExpanded {
                Text("Export")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
            }
            
            Spacer()
            
            // Background Selection Button
            Button(action: {
                showBackgroundGallery = true
            }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 16, weight: .medium))
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
            
            // Export status indicator
            if isExporting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .honeyGold))
                    .scaleEffect(0.8)
            } else {
                // Invisible spacer to balance the back button
                Color.clear
                    .frame(width: 18, height: 18)
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

// MARK: - Export Type Selector
struct ExportTypeSelector: View {
    @Binding var selectedType: ExportType
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ExportType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = type
                    }
                }) {
                    HStack(spacing: ModernDesignSystem.Spacing.sm) {
                        Image(systemName: type.icon)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(type.displayName)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(selectedType == type ? .charcoal : .charcoal.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernDesignSystem.Spacing.md)
                    .background(
                        Rectangle()
                            .fill(selectedType == type ? Color.honeyGold.opacity(0.15) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Preview Section
struct PreviewSection: View {
    let exportType: ExportType
    let previewImage: UIImage?
    let previewVideoURL: URL?
    let onSelectPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Preview Container
            ZStack {
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                    .fill(Color.charcoal.opacity(0.1))
                    .aspectRatio(exportType == .image ? 4/3 : 9/16, contentMode: .fit)
                
                if let previewImage = previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                } else if exportType == .video, let videoURL = previewVideoURL {
                    VideoPreviewPlayer(videoURL: videoURL)
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                } else {
                    // Show photo selection prompt
                    PhotoSelectionPrompt(onSelectPhoto: onSelectPhoto)
                }
            }
            .frame(maxHeight: 400)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
            
            // Preview Info
            HStack {
                Image(systemName: exportType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                Text("Preview")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Text(exportType == .image ? "High Resolution" : "HD Quality")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.fern)
                    .padding(.horizontal, ModernDesignSystem.Spacing.md)
                    .padding(.vertical, ModernDesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                            .fill(Color.fern.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Video Preview Player
struct VideoPreviewPlayer: View {
    let videoURL: URL?
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                        isPlaying = true
                    }
                    .onDisappear {
                        player.pause()
                        isPlaying = false
                    }
            } else {
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    Image(systemName: "video")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.6))
                    
                    Text("Video Preview")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.8))
                }
            }
            
            // Playhead Scrub Overlay
            VStack {
                Spacer()
                
                VideoScrubber(
                    currentTime: $currentTime,
                    duration: duration,
                    isPlaying: $isPlaying
                )
                .padding(.horizontal, ModernDesignSystem.Spacing.md)
                .padding(.bottom, ModernDesignSystem.Spacing.md)
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        // Mock video setup - in real implementation, use actual video URL
        if let url = videoURL {
            player = AVPlayer(url: url)
            duration = 8.0 // Mock duration
        }
    }
}

// MARK: - Video Scrubber
struct VideoScrubber: View {
    @Binding var currentTime: Double
    let duration: Double
    @Binding var isPlaying: Bool
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.sm) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.honeyGold)
                        .frame(width: geometry.size.width * (currentTime / duration), height: 4)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: geometry.size.width * (currentTime / duration) - 8)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newTime = max(0, min(duration, value.location.x / geometry.size.width * duration))
                                    currentTime = newTime
                                }
                        )
                }
            }
            .frame(height: 16)
            
            // Time Labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.sm)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .fill(Color.black.opacity(0.3))
                .background(.ultraThinMaterial)
        )
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Options Section
struct OptionsSection: View {
    let exportType: ExportType
    @Binding var selectedDuration: VideoDuration
    @Binding var isMusicEnabled: Bool
    @Binding var watermarkStatus: WatermarkStatus
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            if exportType == .video {
                // Video Duration Options
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
                    Text("Duration")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.charcoal)
                    
                    HStack(spacing: ModernDesignSystem.Spacing.md) {
                        ForEach(VideoDuration.allCases, id: \.self) { duration in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDuration = duration
                                }
                            }) {
                                Text(duration.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selectedDuration == duration ? .charcoal : .charcoal.opacity(0.6))
                                    .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                                    .padding(.vertical, ModernDesignSystem.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                                            .fill(selectedDuration == duration ? Color.honeyGold.opacity(0.15) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                                            .stroke(selectedDuration == duration ? Color.honeyGold.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Music Toggle
                HStack {
                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                        Text("Background Music")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.charcoal)
                        
                        Text("Add gentle background music")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.charcoal.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isMusicEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .honeyGold))
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
            
            // Watermark Chip
            WatermarkChip(status: $watermarkStatus)
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Watermark Chip
struct WatermarkChip: View {
    @Binding var status: WatermarkStatus
    
    var body: some View {
        HStack {
            Image(systemName: "textformat")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.charcoal.opacity(0.7))
            
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                Text("Watermark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.charcoal)
                
                Text(status == .on ? "Shows 'Made with EverWith'" : "Hidden for Pro users")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.7))
            }
            
            Spacer()
            
            // Status Chip
            Text(status.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(status == .on ? .charcoal : .fern)
                .padding(.horizontal, ModernDesignSystem.Spacing.md)
                .padding(.vertical, ModernDesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                        .fill(status == .on ? Color.honeyGold.opacity(0.15) : Color.fern.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                        .stroke(status == .on ? Color.honeyGold.opacity(0.3) : Color.fern.opacity(0.3), lineWidth: 1)
                )
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

// MARK: - Export Progress View
struct ExportProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                Text("Exporting...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Spacer()
            }
            
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .honeyGold))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("This usually takes 5-15 seconds")
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
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Export Action Buttons Section
struct ExportActionButtonsSection: View {
    let exportType: ExportType
    let isExporting: Bool
    let onSave: () -> Void
    let onShare: () -> Void
    let onCreateLink: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // Primary Save Button
            Button(action: onSave) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Save")
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
            .disabled(isExporting)
            .opacity(isExporting ? 0.6 : 1.0)
            
            // Secondary Action Buttons
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                // Share Button
                Button(action: onShare) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Share...")
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
                .disabled(isExporting)
                
                // Create Link Button
                Button(action: onCreateLink) {
                    HStack {
                        Image(systemName: "link")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Create Link")
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
                .disabled(isExporting)
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export Permission Check View
struct ExportPermissionCheckView: View {
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

#Preview {
}
