//
//  PhotoPickerView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    let mode: PhotoPickerMode
    @Binding var selectedPhotos: [ImportedPhoto]
    @State private var showEditor = false
    @Environment(\.dismiss) private var dismiss
    
    init(mode: PhotoPickerMode, selectedPhotos: Binding<[ImportedPhoto]> = .constant([])) {
        self.mode = mode
        self._selectedPhotos = selectedPhotos
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Elegant background
                ElegantBackground()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    PhotoPickerHeader(mode: mode, geometry: geometry)
                        .padding(.top, geometry.safeAreaInsets.top + ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                    
                    ScrollView {
                        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry)) {
                            // Instructions
                            PhotoPickerInstructions(mode: mode, geometry: geometry)
                                .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
                            
                            // Photo Selection Area
                            PhotoSelectionArea(
                                mode: mode,
                                selectedPhotos: $selectedPhotos,
                                geometry: geometry
                            )
                            .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
                            
                            // Action Buttons
                            PhotoPickerActions(
                                mode: mode,
                                selectedPhotos: selectedPhotos,
                                showEditor: $showEditor,
                                geometry: geometry
                            )
                            .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: geometry.safeAreaInsets.bottom + ResponsiveDesign.adaptiveSpacing(baseSpacing: 40, for: geometry))
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showEditor) {
            EditorView(mode: mode.editorMode, selectedPhotos: selectedPhotos)
        }
    }
}

// MARK: - Photo Picker Mode
enum PhotoPickerMode {
    case restore
    case togetherScene
    
    var editorMode: EditorMode {
        switch self {
        case .restore: return .restore
        case .togetherScene: return .togetherScene
        }
    }
    
    var title: String {
        switch self {
        case .restore: return "Restore a Photo"
        case .togetherScene: return "Together Scene"
        }
    }
    
    var icon: String {
        switch self {
        case .restore: return "photo.badge.plus"
        case .togetherScene: return "heart.circle"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .restore: return [Color.honeyGold, Color.honeyGold.opacity(0.8)]
        case .togetherScene: return [Color.sky, Color.fern]
        }
    }
    
    var requiredPhotoCount: Int {
        switch self {
        case .restore: return 1
        case .togetherScene: return 2
        }
    }
    
    var instructionText: String {
        switch self {
        case .restore: return "Choose a photo to restore"
        case .togetherScene: return "Choose two photos to create a tribute"
        }
    }
    
    var subtitleText: String {
        switch self {
        case .restore: return "Select one precious photo from your library"
        case .togetherScene: return "Pick two photos to compose together"
        }
    }
}

// MARK: - Photo Picker Header
struct PhotoPickerHeader: View {
    let mode: PhotoPickerMode
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
            
            // Mode indicator
            HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                Image(systemName: mode.icon)
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                    .foregroundColor(mode.gradient.first ?? .charcoal)
                
                Text(mode.title)
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
            }
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
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(
                    width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 40, for: geometry),
                    height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 40, for: geometry)
                )
        }
        .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
        .padding(.bottom, ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
    }
}

// MARK: - Photo Picker Instructions
struct PhotoPickerInstructions: View {
    let mode: PhotoPickerMode
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            // Hero icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                mode.gradient.first?.opacity(0.3) ?? Color.clear,
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 60, for: geometry)
                        )
                    )
                    .frame(
                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry),
                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry)
                    )
                    .blur(radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: mode.gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 80, for: geometry),
                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 80, for: geometry)
                    )
                    .overlay(
                        Image(systemName: mode.icon)
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 32, for: geometry), weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(
                        color: mode.gradient.first?.opacity(0.4) ?? Color.clear,
                        radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 15, for: geometry),
                        x: 0,
                        y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)
                    )
            }
            
            // Instructions text
            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                Text(mode.instructionText)
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 24, for: geometry), weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text(mode.subtitleText)
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Photo Selection Area
struct PhotoSelectionArea: View {
    let mode: PhotoPickerMode
    @Binding var selectedPhotos: [ImportedPhoto]
    let geometry: GeometryProxy
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry)) {
            // Photo slots
            HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
                ForEach(0..<mode.requiredPhotoCount, id: \.self) { index in
                    PhotoSlot(
                        index: index,
                        selectedPhoto: index < selectedPhotos.count ? selectedPhotos[index] : nil,
                        geometry: geometry,
                        onPhotoSelected: { photo in
                            updatePhoto(at: index, with: photo)
                        }
                    )
                }
            }
            
            // Add photos button
            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: mode.requiredPhotoCount,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                    Image(systemName: "plus")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .semibold))
                    Text(selectedPhotos.isEmpty ? "Choose Photos" : "Add More Photos")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .semibold, design: .rounded))
                }
                .foregroundColor(.charcoal)
                .frame(maxWidth: .infinity)
                .frame(height: ResponsiveDesign.adaptiveButtonHeight(baseHeight: 56, for: geometry))
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                        .fill(Color.white.opacity(0.1))
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onChange(of: selectedPhotoItems) { newItems in
            Task {
                await loadSelectedPhotos(from: newItems)
                // Reset the selection to allow for future selections
                await MainActor.run {
                    selectedPhotoItems = []
                }
            }
        }
    }
    
    private func updatePhoto(at index: Int, with photo: ImportedPhoto) {
        // Ensure the array is large enough
        while selectedPhotos.count <= index {
            selectedPhotos.append(ImportedPhoto(
                image: UIImage(),
                fileName: nil,
                fileSize: nil,
                source: .library,
                importedAt: Date()
            ))
        }
        
        // Update the photo at the specific index
        selectedPhotos[index] = photo
    }
    
    private func loadSelectedPhotos(from items: [PhotosPickerItem]) async {
        var newPhotos: [ImportedPhoto] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let importedPhoto = ImportedPhoto(
                    image: image,
                    fileName: item.itemIdentifier,
                    fileSize: Int64(data.count),
                    source: .library,
                    importedAt: Date()
                )
                newPhotos.append(importedPhoto)
            }
        }
        
        await MainActor.run {
            selectedPhotos = newPhotos
        }
    }
}

// MARK: - Photo Slot
struct PhotoSlot: View {
    let index: Int
    let selectedPhoto: ImportedPhoto?
    let geometry: GeometryProxy
    let onPhotoSelected: (ImportedPhoto) -> Void
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    var body: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: 1,
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                    .fill(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(
                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry),
                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry)
                    )
                
                if let photo = selectedPhoto {
                    // Show selected photo preview
                    Image(uiImage: photo.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry),
                            height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry)
                        )
                        .clipped()
                        .cornerRadius(ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                        .overlay(
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("Photo \(index + 1)")
                                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry), weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.6))
                                        )
                                        .padding(.trailing, 8)
                                        .padding(.bottom, 8)
                                }
                            }
                        )
                } else {
                    // Show empty slot
                    VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 32, for: geometry), weight: .medium))
                            .foregroundColor(.charcoal.opacity(0.6))
                        
                        Text("Photo \(index + 1)")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry), weight: .medium))
                            .foregroundColor(.charcoal.opacity(0.6))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: selectedPhotoItems) { newItems in
            Task {
                await loadSelectedPhoto(from: newItems)
                // Reset the selection to allow for future selections
                await MainActor.run {
                    selectedPhotoItems = []
                }
            }
        }
    }
    
    private func loadSelectedPhoto(from items: [PhotosPickerItem]) async {
        guard let item = items.first else { return }
        
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            let importedPhoto = ImportedPhoto(
                image: image,
                fileName: item.itemIdentifier,
                fileSize: Int64(data.count),
                source: .library,
                importedAt: Date()
            )
            
            await MainActor.run {
                onPhotoSelected(importedPhoto)
            }
        }
    }
}

// MARK: - Photo Picker Actions
struct PhotoPickerActions: View {
    let mode: PhotoPickerMode
    let selectedPhotos: [ImportedPhoto]
    @Binding var showEditor: Bool
    let geometry: GeometryProxy
    @Environment(\.dismiss) private var dismiss
    
    var isReady: Bool {
        selectedPhotos.count >= mode.requiredPhotoCount
    }
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            // Primary action
            Button(action: {
                if isReady {
                    showEditor = true
                }
            }) {
                HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .semibold))
                    Text(isReady ? "Continue" : "Select Photos First")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .semibold, design: .rounded))
                }
                .foregroundColor(.charcoal)
                .frame(maxWidth: .infinity)
                .frame(height: ResponsiveDesign.adaptiveButtonHeight(baseHeight: 56, for: geometry))
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                        .fill(isReady ? Color.honeyGold : Color.charcoal.opacity(0.3))
                        .shadow(
                            color: isReady ? Color.honeyGold.opacity(0.4) : Color.clear,
                            radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry),
                            x: 0,
                            y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)
                        )
                )
            }
            .disabled(!isReady)
            .buttonStyle(PlainButtonStyle())
            
            // Secondary action
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.8))
            }
        }
    }
}

#Preview {
    PhotoPickerView(mode: .restore)
}
