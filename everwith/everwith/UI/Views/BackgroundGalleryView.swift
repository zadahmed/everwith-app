//
//  BackgroundGalleryView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct BackgroundGalleryView: View {
    @Binding var isPresented: Bool
    @Binding var selectedBackground: BackgroundScene?
    @State private var selectedFilter: BackgroundFilter = .all
    @State private var previewBackground: BackgroundScene?
    
    let backgrounds: [BackgroundScene] = BackgroundScene.allScenes
    
    var filteredBackgrounds: [BackgroundScene] {
        if selectedFilter == .all {
            return backgrounds
        } else {
            return backgrounds.filter { $0.category == selectedFilter }
        }
    }
    
    var body: some View {
        ZStack {
            // Background with live preview
            if let previewBackground = previewBackground {
                BackgroundPreviewView(background: previewBackground)
                    .ignoresSafeArea()
            } else if let selectedBackground = selectedBackground {
                BackgroundPreviewView(background: selectedBackground)
                    .ignoresSafeArea()
            } else {
                // Default background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.warmLinen.opacity(0.3),
                        Color.sky.opacity(0.1),
                        Color.honeyGold.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Liquid Glass Scrim
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 0) {
                // Header
                BackgroundGalleryHeader(
                    selectedFilter: $selectedFilter,
                    onClose: {
                        isPresented = false
                    }
                )
                
                // Background Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(filteredBackgrounds) { background in
                            BackgroundTile(
                                background: background,
                                isSelected: selectedBackground?.id == background.id,
                                onTap: {
                                    selectedBackground = background
                                    isPresented = false
                                },
                                onPreview: {
                                    previewBackground = background
                                },
                                onPreviewEnd: {
                                    previewBackground = nil
                                }
                            )
                        }
                    }
                    .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                    .padding(.bottom, ModernDesignSystem.Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .interactiveDismissDisabled(false)
    }
}

// MARK: - Background Scene Model
struct BackgroundScene: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: BackgroundFilter
    let isPremium: Bool
    let thumbnailName: String
    let previewName: String
    
    static let allScenes: [BackgroundScene] = [
        // Indoor Scenes
        BackgroundScene(name: "Cozy Living Room", category: .indoor, isPremium: false, thumbnailName: "living_room_thumb", previewName: "living_room_preview"),
        BackgroundScene(name: "Study Corner", category: .indoor, isPremium: false, thumbnailName: "study_thumb", previewName: "study_preview"),
        BackgroundScene(name: "Kitchen Window", category: .indoor, isPremium: true, thumbnailName: "kitchen_thumb", previewName: "kitchen_preview"),
        BackgroundScene(name: "Bedroom", category: .indoor, isPremium: true, thumbnailName: "bedroom_thumb", previewName: "bedroom_preview"),
        
        // Outdoor Scenes
        BackgroundScene(name: "Garden Path", category: .outdoor, isPremium: false, thumbnailName: "garden_thumb", previewName: "garden_preview"),
        BackgroundScene(name: "Beach Sunset", category: .outdoor, isPremium: false, thumbnailName: "beach_thumb", previewName: "beach_preview"),
        BackgroundScene(name: "Mountain View", category: .outdoor, isPremium: true, thumbnailName: "mountain_thumb", previewName: "mountain_preview"),
        BackgroundScene(name: "Forest Clearing", category: .outdoor, isPremium: true, thumbnailName: "forest_thumb", previewName: "forest_preview"),
        
        // Symbolic Scenes
        BackgroundScene(name: "Memorial Garden", category: .symbolic, isPremium: false, thumbnailName: "memorial_thumb", previewName: "memorial_preview"),
        BackgroundScene(name: "Candlelight", category: .symbolic, isPremium: false, thumbnailName: "candle_thumb", previewName: "candle_preview"),
        BackgroundScene(name: "Sacred Space", category: .symbolic, isPremium: true, thumbnailName: "sacred_thumb", previewName: "sacred_preview"),
        BackgroundScene(name: "Peaceful Chapel", category: .symbolic, isPremium: true, thumbnailName: "chapel_thumb", previewName: "chapel_preview")
    ]
}

// MARK: - Background Filter Enum
enum BackgroundFilter: String, CaseIterable {
    case all = "all"
    case indoor = "indoor"
    case outdoor = "outdoor"
    case symbolic = "symbolic"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .indoor: return "Indoor"
        case .outdoor: return "Outdoor"
        case .symbolic: return "Symbolic"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.3x3"
        case .indoor: return "house"
        case .outdoor: return "leaf"
        case .symbolic: return "heart"
        }
    }
}

// MARK: - Background Gallery Header
struct BackgroundGalleryHeader: View {
    @Binding var selectedFilter: BackgroundFilter
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // Top Bar
            HStack {
                Text("Background Gallery")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .background(.ultraThinMaterial)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Filter Tabs
            HStack(spacing: 0) {
                ForEach(BackgroundFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }) {
                        HStack(spacing: ModernDesignSystem.Spacing.sm) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(filter.displayName)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(selectedFilter == filter ? .charcoal : .charcoal.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernDesignSystem.Spacing.sm)
                        .background(
                            Rectangle()
                                .fill(selectedFilter == filter ? Color.white.opacity(0.2) : Color.clear)
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
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.top, ModernDesignSystem.Spacing.lg)
        .padding(.bottom, ModernDesignSystem.Spacing.md)
    }
}

// MARK: - Background Tile
struct BackgroundTile: View {
    let background: BackgroundScene
    let isSelected: Bool
    let onTap: () -> Void
    let onPreview: () -> Void
    let onPreviewEnd: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background Image
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.honeyGold.opacity(0.3),
                                Color.sky.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                
                // Mock image placeholder (in real app, use actual images)
                VStack(spacing: ModernDesignSystem.Spacing.xs) {
                    Image(systemName: background.category.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.7))
                    
                    Text(background.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.charcoal)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // Premium Lock
                if background.isPremium {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.honeyGold)
                                .padding(4)
                                .background(
                                    Circle()
                                        .fill(Color.charcoal.opacity(0.8))
                                )
                        }
                        Spacer()
                    }
                    .padding(4)
                }
                
                // Selection Indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                        .stroke(Color.honeyGold, lineWidth: 3)
                        .background(
                            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                                .fill(Color.honeyGold.opacity(0.1))
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1) {
            onPreview()
        } onPressingChanged: { pressing in
            if !pressing {
                onPreviewEnd()
            }
        }
    }
}

// MARK: - Background Preview View
struct BackgroundPreviewView: View {
    let background: BackgroundScene
    
    var body: some View {
        ZStack {
            // Background gradient based on category
            LinearGradient(
                gradient: backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Mock background content (in real app, use actual background images)
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                Image(systemName: background.category.icon)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.3))
                
                Text(background.name)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var backgroundGradient: Gradient {
        switch background.category {
        case .indoor:
            return Gradient(colors: [
                Color.warmLinen.opacity(0.8),
                Color.honeyGold.opacity(0.3),
                Color.charcoal.opacity(0.1)
            ])
        case .outdoor:
            return Gradient(colors: [
                Color.sky.opacity(0.6),
                Color.fern.opacity(0.4),
                Color.honeyGold.opacity(0.2)
            ])
        case .symbolic:
            return Gradient(colors: [
                Color.softBlush.opacity(0.5),
                Color.warmLinen.opacity(0.7),
                Color.charcoal.opacity(0.2)
            ])
        case .all:
            return Gradient(colors: [
                Color.warmLinen.opacity(0.3),
                Color.sky.opacity(0.1),
                Color.honeyGold.opacity(0.05)
            ])
        }
    }
}

// MARK: - Background Gallery Sheet Modifier
struct BackgroundGallerySheet: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedBackground: BackgroundScene?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                BackgroundGalleryView(
                    isPresented: $isPresented,
                    selectedBackground: $selectedBackground
                )
            }
    }
}

// MARK: - View Extension
extension View {
    func backgroundGallerySheet(
        isPresented: Binding<Bool>,
        selectedBackground: Binding<BackgroundScene?>
    ) -> some View {
        self.modifier(BackgroundGallerySheet(
            isPresented: isPresented,
            selectedBackground: selectedBackground
        ))
    }
}

#Preview {
    ZStack {
        Color.warmLinen.ignoresSafeArea()
        
        VStack(spacing: 20) {
            Text("Background Gallery Preview")
                .font(.title)
                .foregroundColor(.charcoal)
            
            Button("Open Background Gallery") {
                // Preview action
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
    .backgroundGallerySheet(
        isPresented: .constant(true),
        selectedBackground: .constant(nil)
    )
}
