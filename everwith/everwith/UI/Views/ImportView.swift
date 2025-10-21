//
//  ImportView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ImportView: View {
    let mode: ImportMode
    @Binding var isPresented: Bool
    @Binding var selectedPhotos: [ImportedPhoto]
    @State private var selectedSource: ImportSource = .library
    @State private var importState: ImportState = .idle
    @State private var importProgress: ImportProgress?
    @State private var showPhotosPicker = false
    @State private var showFilesPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var processingSettings: ProcessingSettings = ProcessingSettings()
    @State private var showSettingsSheet = false
    @State private var showResultView = false
    @State private var processedResult: ProcessedPhoto?
    
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    
    private let configuration: ImportConfiguration
    
    init(mode: ImportMode, isPresented: Binding<Bool>, selectedPhotos: Binding<[ImportedPhoto]>) {
        self.mode = mode
        self._isPresented = isPresented
        self._selectedPhotos = selectedPhotos
        self.configuration = ImportConfiguration.forMode(mode)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header
                    ImportHeaderView(mode: mode)
                        .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Tab Selection
                    ImportTabSelector(selectedSource: $selectedSource)
                    
                    // Content Area
                    ImportContentView(
                        source: selectedSource,
                        mode: mode,
                        selectedPhotos: selectedPhotos,
                        showPhotosPicker: $showPhotosPicker,
                        onPhotosSelected: { _ in },
                        onFilesSelected: handleFilesSelected
                    )
                    
                    // Inline Tip
                    ImportTipView()
                    
                    // Progress Row (when processing)
                    if case .uploading = importState, let progress = importProgress {
                        ImportProgressView(
                            progress: progress,
                            onCancel: cancelImport
                        )
                    } else if case .processing = importState, let progress = importProgress {
                        ImportProgressView(
                            progress: progress,
                            onCancel: cancelImport
                        )
                    }
                    
                    // Action Buttons
                    ImportActionButtons(
                        mode: mode,
                        selectedPhotos: selectedPhotos,
                        importState: importState,
                        onImport: startImport,
                        onSettings: { showSettingsSheet = true },
                        onCancel: { isPresented = false }
                    )
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
            .navigationBarHidden(true)
            .background(Color.warmLinen)
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotoItems,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await loadPhotosFromPicker(newItems)
            }
        }
        .fileImporter(
            isPresented: $showFilesPicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: mode == .together
        ) { result in
            handleFileImportResult(result)
        }
        .sheet(isPresented: $showSettingsSheet) {
            ProcessingSettingsView(
                mode: mode,
                settings: $processingSettings,
                isPresented: $showSettingsSheet
            )
        }
        .fullScreenCover(isPresented: $showResultView) {
            if let result = processedResult {
                ProcessedPhotoResultView(
                    processedPhoto: result,
                    isPresented: $showResultView,
                    onDismiss: {
                        showResultView = false
                        isPresented = false
                    }
                )
            }
        }
        .onChange(of: imageProcessingService.processingState) { _, newState in
            handleProcessingStateChange(newState)
        }
    }
    
    // MARK: - Private Methods
    private func loadPhotosFromPicker(_ items: [PhotosPickerItem]) async {
        importState = .selecting
        importProgress = ImportProgress(current: 0, total: items.count, fileName: nil)
        
        var newPhotos: [ImportedPhoto] = []
        
        for (index, item) in items.enumerated() {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let importedPhoto = ImportedPhoto(
                        image: image,
                        fileName: "Photo \(index + 1)",
                        fileSize: Int64(data.count),
                        source: .library,
                        importedAt: Date()
                    )
                    newPhotos.append(importedPhoto)
                    
                    await MainActor.run {
                        importProgress = ImportProgress(
                            current: index + 1,
                            total: items.count,
                            fileName: "Photo \(index + 1)"
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    importState = .failed(error)
                }
                return
            }
            
            // Simulate processing delay
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
        await MainActor.run {
            selectedPhotos = newPhotos
            importState = .idle
            importProgress = nil
        }
    }
    
    private func handleFilesSelected() {
        showFilesPicker = true
    }
    
    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importFilesFromURLs(urls)
        case .failure(let error):
            importState = .failed(error)
        }
    }
    
    private func importFilesFromURLs(_ urls: [URL]) {
        importState = .selecting
        importProgress = ImportProgress(current: 0, total: urls.count, fileName: nil)
        
        // Simulate file import process
        Task {
            for (index, url) in urls.enumerated() {
                do {
                    let data = try Data(contentsOf: url)
                    if let image = UIImage(data: data) {
                        let importedPhoto = ImportedPhoto(
                            image: image,
                            fileName: url.lastPathComponent,
                            fileSize: Int64(data.count),
                            source: .files,
                            importedAt: Date()
                        )
                        
                        await MainActor.run {
                            selectedPhotos.append(importedPhoto)
                            importProgress = ImportProgress(
                                current: index + 1,
                                total: urls.count,
                                fileName: url.lastPathComponent
                            )
                        }
                    }
                } catch {
                    await MainActor.run {
                        importState = .failed(error)
                    }
                    return
                }
                
                // Simulate processing delay
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            await MainActor.run {
                importState = .completed(nil)
                importProgress = nil
            }
        }
    }
    
    private func startImport() {
        print("🚀 startImport called for mode: \(mode)")
        guard !selectedPhotos.isEmpty else { 
            print("❌ No photos selected")
            return 
        }
        
        print("📸 Starting import with \(selectedPhotos.count) photos")
        
        Task {
            do {
                switch mode {
                case .restore:
                    guard let photo = selectedPhotos.first else { return }
                    let result = try await imageProcessingService.restorePhoto(
                        image: photo.image,
                        qualityTarget: processingSettings.qualityTarget,
                        outputFormat: processingSettings.outputFormat,
                        aspectRatio: processingSettings.aspectRatio,
                        seed: processingSettings.seed
                    )
                    
                    // Download the processed image
                    let processedImage = try await imageProcessingService.downloadProcessedImage(from: result.outputUrl)
                    
                    await MainActor.run {
                        let processedPhoto = ProcessedPhoto(
                            originalImage: photo.image,
                            processedImage: processedImage,
                            mode: mode,
                            processingSettings: processingSettings,
                            processedAt: Date(),
                            outputUrl: result.outputUrl
                        )
                        importState = .completed(processedPhoto)
                        processedResult = processedPhoto
                        showResultView = true
                    }
                    
                case .together:
                    guard selectedPhotos.count >= 2 else { return }
                    let subjectA = selectedPhotos[0].image
                    let subjectB = selectedPhotos[1].image
                    
                    let background = processingSettings.background ?? TogetherBackground(
                        mode: .generate,
                        prompt: "soft warm tribute background with gentle bokeh"
                    )
                    
                    let result = try await imageProcessingService.togetherPhoto(
                        subjectA: subjectA,
                        subjectB: subjectB,
                        background: background,
                        aspectRatio: processingSettings.aspectRatio,
                        seed: processingSettings.seed,
                        lookControls: processingSettings.lookControls
                    )
                    
                    // Download the processed image
                    let processedImage = try await imageProcessingService.downloadProcessedImage(from: result.outputUrl)
                    
                    await MainActor.run {
                        let processedPhoto = ProcessedPhoto(
                            originalImage: subjectA, // Use first image as reference
                            processedImage: processedImage,
                            mode: mode,
                            processingSettings: processingSettings,
                            processedAt: Date(),
                            outputUrl: result.outputUrl
                        )
                        importState = .completed(processedPhoto)
                        processedResult = processedPhoto
                        showResultView = true
                    }
                }
            } catch {
                await MainActor.run {
                    importState = .failed(error)
                }
            }
        }
    }
    
    private func cancelImport() {
        importState = .idle
        importProgress = nil
        selectedPhotos.removeAll()
        imageProcessingService.resetState()
    }
    
    private func handleProcessingStateChange(_ newState: ImageProcessingState) {
        switch newState {
        case .idle:
            importState = .idle
        case .uploading:
            importState = .uploading
        case .processing:
            importState = .processing
        case .completed:
            // Completion is handled in startImport method
            break
        case .failed(let error):
            importState = .failed(error)
        }
        
        // Update progress from service
        if let serviceProgress = imageProcessingService.processingProgress {
            importProgress = ImportProgress(
                current: serviceProgress.currentStepIndex,
                total: serviceProgress.totalSteps,
                fileName: serviceProgress.currentStep
            )
        } else {
            importProgress = nil
        }
    }
}

// MARK: - Processed Photo Result View
struct ProcessedPhotoResultView: View {
    let processedPhoto: ProcessedPhoto
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    @State private var sliderPosition: CGFloat = 0.5
    @State private var animateIn = false
    @State private var showSavedMessage = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simple dark background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Simple Header
                    HStack {
                        Button(action: { onDismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Done")
                                    .font(.system(size: 17, weight: .regular))
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(processedPhoto.mode == .restore ? "✨ Restored" : "💫 Together")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(geometry.safeAreaInsets.top, 16))
                    .padding(.bottom, 16)
                    
                    // Main Image with Before/After Slider
                    ZStack {
                        // Result image
                        Image(uiImage: processedPhoto.processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: geometry.size.height * 0.6)
                        
                        // Before/After Comparison Overlay
                        GeometryReader { imageGeometry in
                            HStack(spacing: 0) {
                                // Original (left side)
                                Image(uiImage: processedPhoto.originalImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: geometry.size.height * 0.6)
                                    .mask(
                                        Rectangle()
                                            .frame(width: imageGeometry.size.width * sliderPosition)
                                    )
                                    .overlay(
                                        Text("Before")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(8)
                                            .offset(x: 12, y: 12)
                                            .opacity(sliderPosition > 0.1 ? 1 : 0)
                                        , alignment: .topLeading
                                    )
                                
                                Spacer()
                            }
                            
                            // Slider handle
                            VStack {
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3)
                                    .overlay(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 44, height: 44)
                                            .shadow(color: .black.opacity(0.3), radius: 8)
                                            .overlay(
                                                HStack(spacing: 4) {
                                                    Image(systemName: "chevron.left")
                                                        .font(.system(size: 12, weight: .bold))
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 12, weight: .bold))
                                                }
                                                .foregroundColor(.black.opacity(0.6))
                                            )
                                    )
                            }
                            .frame(width: 44)
                            .offset(x: imageGeometry.size.width * sliderPosition - 22)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        sliderPosition = min(max(value.location.x / imageGeometry.size.width, 0), 1)
                                    }
                            )
                        }
                        
                        // "After" label
                        if sliderPosition < 0.9 {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("After")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(8)
                                        .padding(.trailing, 12)
                                        .padding(.top, 12)
                                }
                                Spacer()
                            }
                        }
                    }
                    .scaleEffect(animateIn ? 1.0 : 0.95)
                    .opacity(animateIn ? 1.0 : 0.0)
                    
                    Spacer()
                    
                    // Simple instructions
                    Text("← Swipe to compare →")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 20)
                    
                    // Action Buttons - Simple and Clear
                    VStack(spacing: 12) {
                        // Primary: Save
                        Button(action: savePhoto) {
                            HStack(spacing: 12) {
                                Image(systemName: showSavedMessage ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                Text(showSavedMessage ? "Saved!" : "Save to Photos")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                showSavedMessage ? Color.green : Color.honeyGold
                            )
                            .cornerRadius(14)
                        }
                        .disabled(showSavedMessage)
                        
                        // Secondary: Share
                        Button(action: sharePhoto) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Share")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                animateIn = true
            }
        }
    }
    
    private func savePhoto() {
        UIImageWriteToSavedPhotosAlbum(processedPhoto.processedImage, nil, nil, nil)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSavedMessage = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSavedMessage = false
            }
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func sharePhoto() {
        let activityVC = UIActivityViewController(
            activityItems: [processedPhoto.processedImage],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Import Header View
struct ImportHeaderView: View {
    let mode: ImportMode
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text("Import Photos")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                    
                    Text(mode.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
                
                Spacer()
                
                // Mode Icon
                ZStack {
                    Circle()
                        .fill(Color.honeyGold.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.honeyGold)
                }
            }
            
            // Photo Count Indicator
            HStack {
                Image(systemName: "photo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
                
                Text("\(mode.maxPhotos) photo\(mode.maxPhotos == 1 ? "" : "s") needed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
                
                Spacer()
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.top, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Import Tab Selector
struct ImportTabSelector: View {
    @Binding var selectedSource: ImportSource
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImportSource.allCases, id: \.self) { source in
                Button(action: {
                    selectedSource = source
                }) {
                    HStack(spacing: ModernDesignSystem.Spacing.sm) {
                        Image(systemName: source.icon)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(source.displayName)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(selectedSource == source ? .honeyGold : .charcoal.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernDesignSystem.Spacing.md)
                    .background(
                        Rectangle()
                            .fill(selectedSource == source ? Color.honeyGold.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(ModernDesignSystem.CornerRadius.md)
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.top, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Import Content View
struct ImportContentView: View {
    let source: ImportSource
    let mode: ImportMode
    let selectedPhotos: [ImportedPhoto]
    @Binding var showPhotosPicker: Bool
    let onPhotosSelected: ([ImportedPhoto]) -> Void
    let onFilesSelected: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            switch source {
            case .library:
                LibraryContentView(
                    mode: mode,
                    selectedPhotos: selectedPhotos,
                    showPhotosPicker: $showPhotosPicker,
                    onPhotosSelected: onPhotosSelected
                )
            case .files:
                FilesContentView(
                    mode: mode,
                    selectedPhotos: selectedPhotos,
                    onFilesSelected: onFilesSelected
                )
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.top, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Library Content View
struct LibraryContentView: View {
    let mode: ImportMode
    let selectedPhotos: [ImportedPhoto]
    @Binding var showPhotosPicker: Bool
    let onPhotosSelected: ([ImportedPhoto]) -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            if selectedPhotos.isEmpty {
                // Empty State
                VStack(spacing: ModernDesignSystem.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.honeyGold.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.honeyGold)
                    }
                    
                    VStack(spacing: ModernDesignSystem.Spacing.sm) {
                        Text("Select from Library")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.charcoal)
                        
                        Text("Choose \(mode.maxPhotos) photo\(mode.maxPhotos == 1 ? "" : "s") from your photo library")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.charcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(ModernDesignSystem.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                        .fill(Color.white.opacity(0.05))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            } else {
                // Selected Photos Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ModernDesignSystem.Spacing.md) {
                    ForEach(selectedPhotos) { photo in
                        ImportedPhotoCard(photo: photo)
                    }
                }
            }
            
            // Select Button
            Button(action: {
                showPhotosPicker = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(selectedPhotos.isEmpty ? "Select Photos" : "Add More Photos")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.charcoal)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.honeyGold.opacity(0.15))
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                        .stroke(Color.honeyGold.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(selectedPhotos.count >= mode.maxPhotos)
        }
    }
}

// MARK: - Files Content View
struct FilesContentView: View {
    let mode: ImportMode
    let selectedPhotos: [ImportedPhoto]
    let onFilesSelected: () -> Void
    @State private var showFilesPicker = false
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            if selectedPhotos.isEmpty {
                // Empty State
                VStack(spacing: ModernDesignSystem.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.sky.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "folder")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.sky)
                    }
                    
                    VStack(spacing: ModernDesignSystem.Spacing.sm) {
                        Text("Select from Files")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.charcoal)
                        
                        Text("Choose \(mode.maxPhotos) photo\(mode.maxPhotos == 1 ? "" : "s") from your files")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.charcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(ModernDesignSystem.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                        .fill(Color.white.opacity(0.05))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            } else {
                // Selected Photos Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ModernDesignSystem.Spacing.md) {
                    ForEach(selectedPhotos) { photo in
                        ImportedPhotoCard(photo: photo)
                    }
                }
            }
            
            // Select Button
            Button(action: {
                showFilesPicker = true
                onFilesSelected()
            }) {
                HStack {
                    Image(systemName: "folder")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(selectedPhotos.isEmpty ? "Select Files" : "Add More Files")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.charcoal)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.sky.opacity(0.15))
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                        .stroke(Color.sky.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(selectedPhotos.count >= mode.maxPhotos)
        }
        .fileImporter(
            isPresented: $showFilesPicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: mode == .together
        ) { _ in
            // Handle file selection
        }
    }
}

// MARK: - Imported Photo Card
struct ImportedPhotoCard: View {
    let photo: ImportedPhoto
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.sm) {
            // Photo Thumbnail
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipped()
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
            
            // Photo Info
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                if let fileName = photo.fileName {
                    Text(fileName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.charcoal)
                        .lineLimit(1)
                }
                
                HStack {
                    Image(systemName: photo.source.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.6))
                    
                    Text(photo.source.displayName)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.6))
                    
                    Spacer()
                }
            }
        }
        .padding(ModernDesignSystem.Spacing.sm)
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

// MARK: - Import Tip View
struct ImportTipView: View {
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            Image(systemName: "lightbulb")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.honeyGold)
            
            Text("Best results from originals (3000px+).")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.charcoal.opacity(0.7))
            
            Spacer()
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.top, ModernDesignSystem.Spacing.md)
    }
}

// MARK: - Import Progress View
struct ImportProgressView: View {
    let progress: ImportProgress
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.sm) {
            HStack {
                if let fileName = progress.fileName {
                    Text(fileName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.charcoal)
                } else {
                    Text("Processing...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.charcoal)
                }
                
                Spacer()
                
                Button("Cancel", action: onCancel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
            }
            
            // Progress Bar
            ProgressView(value: progress.percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .honeyGold))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.top, ModernDesignSystem.Spacing.md)
    }
}

// MARK: - Import Action Buttons
struct ImportActionButtons: View {
    let mode: ImportMode
    let selectedPhotos: [ImportedPhoto]
    let importState: ImportState
    let onImport: () -> Void
    let onSettings: () -> Void
    let onCancel: () -> Void
    
    private var isProcessing: Bool {
        switch importState {
        case .uploading, .processing:
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // Import Button
            Button(action: onImport) {
                HStack {
                    Image(systemName: mode.icon)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Import \(mode.displayName)")
                        .font(.system(size: 16, weight: .semibold))
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
            .disabled(selectedPhotos.isEmpty || isProcessing)
            
            // Settings Button
            if !selectedPhotos.isEmpty && !isProcessing {
                Button(action: onSettings) {
                    HStack {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Settings")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.charcoal.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(ModernDesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Cancel Button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.bottom, ModernDesignSystem.Spacing.lg)
    }
}

#Preview {
    ImportView(mode: .restore, isPresented: .constant(true), selectedPhotos: .constant([]))
}