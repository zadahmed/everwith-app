//
//  MyCreationsView.swift
//  EverWith
//
//  History screen showing user's processed images
//

import SwiftUI

struct MyCreationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    @State private var creations: [ProcessedImage] = []
    @State private var isLoading = true
    @State private var selectedImage: ProcessedImage? = nil
    @State private var showClearCacheAlert = false
    @State private var animateElements = false
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    CleanWhiteBackground()
                        .ignoresSafeArea()
                    
                    if isLoading {
                        VStack(spacing: geometry.adaptiveSpacing(16)) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Loading your memories...")
                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                                .foregroundColor(.softPlum)
                        }
                    } else if creations.isEmpty {
                        EmptyStateView(geometry: geometry)
                    } else {
                        ScrollView {
                            VStack(spacing: geometry.adaptiveSpacing(24)) {
                                // Stats Header
                                HStack(spacing: geometry.adaptiveSpacing(20)) {
                                    StatCard(
                                        icon: "photo.stack",
                                        value: "\(creations.count)",
                                        label: "Memories",
                                        geometry: geometry
                                    )
                                    
                                    StatCard(
                                        icon: "sparkles",
                                        value: "\(creations.filter { $0.imageType == "restore" }.count)",
                                        label: "Restored",
                                        geometry: geometry
                                    )
                                    
                                    StatCard(
                                        icon: "heart.circle",
                                        value: "\(creations.filter { $0.imageType == "merge" }.count)",
                                        label: "Merged",
                                        geometry: geometry
                                    )
                                }
                                .padding(.horizontal, geometry.adaptivePadding())
                                .opacity(animateElements ? 1.0 : 0.0)
                                
                                // Grid of Creations
                                LazyVGrid(columns: columns, spacing: geometry.adaptiveSpacing(12)) {
                                    ForEach(creations) { creation in
                                        CreationCard(
                                            creation: creation,
                                            geometry: geometry
                                        )
                                        .onTapGesture {
                                            selectedImage = creation
                                        }
                                    }
                                }
                                .padding(.horizontal, geometry.adaptivePadding())
                                .opacity(animateElements ? 1.0 : 0.0)
                                
                                // Clear Cache Button
                                Button(action: {
                                    showClearCacheAlert = true
                                }) {
                                    HStack(spacing: geometry.adaptiveSpacing(8)) {
                                        Image(systemName: "trash")
                                            .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                                        
                                        Text("Clear Cache")
                                            .font(.system(size: geometry.adaptiveFontSize(15), weight: .medium))
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, geometry.adaptiveSpacing(20))
                                    .padding(.vertical, geometry.adaptiveSpacing(12))
                                    .background(
                                        RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(12))
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.top, geometry.adaptiveSpacing(16))
                                .opacity(animateElements ? 1.0 : 0.0)
                                
                                Spacer()
                                    .frame(height: geometry.adaptiveSpacing(32))
                            }
                            .padding(.top, geometry.adaptiveSpacing(16))
                            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
                        }
                    }
                }
                .navigationTitle("My Memories")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: geometry.adaptiveFontSize(24)))
                                .foregroundColor(.softPlum)
                        }
                    }
                }
            }
            .sheet(item: $selectedImage) { image in
                CreationDetailView(creation: image, geometry: geometry)
            }
            .alert("Clear Cache", isPresented: $showClearCacheAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("This will remove all cached images. Your original photos will not be affected.")
            }
            .onAppear {
                loadCreations()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                    animateElements = true
                }
            }
        }
    }
    
    private func loadCreations() {
        Task {
            do {
                let history = try await imageProcessingService.fetchImageHistory(page: 1, pageSize: 50)
                await MainActor.run {
                    creations = history.images
                    isLoading = false
                }
            } catch {
                print("❌ Failed to load creations: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func clearCache() {
        creations.removeAll()
        // Add actual cache clearing logic here
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: geometry.adaptiveSpacing(8)) {
            Image(systemName: icon)
                .font(.system(size: geometry.adaptiveFontSize(24), weight: .semibold))
                .foregroundStyle(LinearGradient.primaryBrand)
            
            Text(value)
                .font(.system(size: geometry.adaptiveFontSize(24), weight: .bold, design: .rounded))
                .foregroundColor(.deepPlum)
            
            Text(label)
                .font(.system(size: geometry.adaptiveFontSize(13), weight: .medium))
                .foregroundColor(.softPlum)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, geometry.adaptiveSpacing(16))
        .background(
            RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(16))
                .fill(Color.pureWhite)
                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Creation Card
struct CreationCard: View {
    let creation: ProcessedImage
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            AsyncImage(url: creation.processedImageUrl.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(3/4, contentMode: .fit)
                        .overlay(
                            ProgressView()
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: geometry.size.width * 0.6)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(3/4, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(8)) {
                HStack(spacing: geometry.adaptiveSpacing(6)) {
                    Image(systemName: creation.icon)
                        .font(.system(size: geometry.adaptiveFontSize(12), weight: .semibold))
                    Text(creation.displayType)
                        .font(.system(size: geometry.adaptiveFontSize(12), weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, geometry.adaptiveSpacing(8))
                .padding(.vertical, geometry.adaptiveSpacing(4))
                .background(
                    Capsule()
                        .fill(creation.color)
                )
                
                Text(formatDate(creation.createdAt ?? Date()))
                    .font(.system(size: geometry.adaptiveFontSize(12), weight: .regular))
                    .foregroundColor(.softPlum)
            }
            .padding(geometry.adaptiveSpacing(12))
        }
        .background(
            RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(16))
                .fill(Color.pureWhite)
                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Creation Detail View
struct CreationDetailView: View {
    let creation: ProcessedImage
    let geometry: GeometryProxy
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: creation.processedImageUrl.flatMap { URL(string: $0) }) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        ProgressView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: geometry.adaptiveFontSize(24)))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    HStack(spacing: geometry.adaptiveSpacing(32)) {
                        Button(action: {
                            // Share
                        }) {
                            VStack(spacing: geometry.adaptiveSpacing(4)) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: geometry.adaptiveFontSize(24)))
                                Text("Share")
                                    .font(.system(size: geometry.adaptiveFontSize(12)))
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Save
                        }) {
                            VStack(spacing: geometry.adaptiveSpacing(4)) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: geometry.adaptiveFontSize(24)))
                                Text("Save")
                                    .font(.system(size: geometry.adaptiveFontSize(12)))
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Delete
                        }) {
                            VStack(spacing: geometry.adaptiveSpacing(4)) {
                                Image(systemName: "trash")
                                    .font(.system(size: geometry.adaptiveFontSize(24)))
                                Text("Delete")
                                    .font(.system(size: geometry.adaptiveFontSize(12)))
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, geometry.adaptivePadding())
                }
            }
        }
    }
}

#Preview {
    MyCreationsView()
}

