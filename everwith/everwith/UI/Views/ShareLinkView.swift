//
//  ShareLinkView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct ShareLinkView: View {
    @Binding var isPresented: Bool
    @State private var visibility: ShareVisibility = .privateAccess
    @State private var isCreatingLink = false
    @State private var shareLink: ShareLink?
    @State private var showShareSheet = false
    @State private var isFlagged = false
    
    // Mock data for demonstration
    let projectThumbnail: UIImage? = UIImage(systemName: "photo.fill")
    let projectTitle: String = "Restored Memory"
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header
                    ShareLinkHeader(
                        projectTitle: projectTitle,
                        projectThumbnail: projectThumbnail,
                        onClose: {
                            isPresented = false
                        }
                    )
                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: ModernDesignSystem.Spacing.lg) {
                            // Visibility Section
                            VisibilitySection(
                                visibility: $visibility,
                                isFlagged: isFlagged
                            )
                            
                            // Share Link Section
                            if let shareLink = shareLink {
                                ShareLinkSection(
                                    shareLink: shareLink,
                                    onCopy: copyLink,
                                    onShare: shareLinkAction
                                )
                            } else {
                                CreateLinkSection(
                                    isCreating: isCreatingLink,
                                    onCreateLink: createShareLink
                                )
                            }
                            
                            // Status Section
                            if isFlagged {
                                FlaggedStatusSection()
                            }
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: geometry.safeAreaInsets.bottom + ModernDesignSystem.Spacing.lg)
                        }
                        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                        .padding(.top, ModernDesignSystem.Spacing.lg)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color.warmLinen)
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareLink = shareLink {
                ShareSheet(items: [shareLink.url])
            }
        }
    }
    
    // MARK: - Private Methods
    private func createShareLink() {
        isCreatingLink = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let mockShareLink = ShareLink(
                slug: "abc123",
                url: "https://everwith.app/share/abc123",
                visibility: visibility,
                flagged: false,
                createdAt: Date()
            )
            
            self.shareLink = mockShareLink
            self.isCreatingLink = false
            
            // Simulate moderation check
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Randomly flag some links for demo
                if Bool.random() {
                    self.isFlagged = true
                    self.shareLink?.flagged = true
                }
            }
        }
    }
    
    private func copyLink() {
        if let shareLink = shareLink {
            UIPasteboard.general.string = shareLink.url
            // Show success feedback
        }
    }
    
    private func shareLinkAction() {
        showShareSheet = true
    }
}

// MARK: - Share Link Header
struct ShareLinkHeader: View {
    let projectTitle: String
    let projectThumbnail: UIImage?
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                    Text("Create Share Link")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                    
                    Text("Share your restored memory with others")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
                
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
            
            // Project Preview
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                if let thumbnail = projectThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(ModernDesignSystem.CornerRadius.md)
                }
                
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text(projectTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.charcoal)
                    
                    Text("Restored Photo")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(ModernDesignSystem.Spacing.md)
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
    }
}

// MARK: - Visibility Section
struct VisibilitySection: View {
    @Binding var visibility: ShareVisibility
    let isFlagged: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            Text("Visibility")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.charcoal)
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                ForEach(ShareVisibility.allCases, id: \.self) { option in
                    Button(action: {
                        visibility = option
                    }) {
                        HStack {
                            Image(systemName: visibility == option ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(visibility == option ? .honeyGold : .charcoal.opacity(0.4))
                            
                            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                                Text(option.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.charcoal)
                                
                                Text(option.description)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.charcoal.opacity(0.6))
                            }
                            
                            Spacer()
                        }
                        .padding(ModernDesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                                .fill(visibility == option ? Color.honeyGold.opacity(0.1) : Color.white.opacity(0.05))
                                .background(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                                .stroke(visibility == option ? Color.honeyGold.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isFlagged && option == .publicAccess)
                }
            }
        }
    }
}

// MARK: - Create Link Section
struct CreateLinkSection: View {
    let isCreating: Bool
    let onCreateLink: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            Button(action: onCreateLink) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .charcoal))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "link")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isCreating ? "Creating Link..." : "Create Link")
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
            .buttonStyle(PlainButtonStyle())
            .disabled(isCreating)
            
            Text("Your link will be created and ready to share")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.charcoal.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Share Link Section
struct ShareLinkSection: View {
    let shareLink: ShareLink
    let onCopy: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Link Display
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                Text("Your Share Link")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                HStack {
                    Text(shareLink.url)
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(.charcoal.opacity(0.8))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.honeyGold)
                    }
                }
                .padding(ModernDesignSystem.Spacing.md)
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
            
            // Action Buttons
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                Button(action: onCopy) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Copy")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.charcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .cornerRadius(ModernDesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onShare) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Share")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.charcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.honeyGold)
                    .cornerRadius(ModernDesignSystem.CornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Flagged Status Section
struct FlaggedStatusSection: View {
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                Text("Under Review")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.charcoal)
                
                Spacer()
            }
            
            Text("Your content is being reviewed for compliance. Public sharing is temporarily disabled, but you can still save locally.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.charcoal.opacity(0.7))
                .multilineTextAlignment(.leading)
        }
        .padding(ModernDesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .fill(Color.honeyGold.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(Color.honeyGold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Share Models
struct ShareLink: Identifiable {
    let id = UUID()
    let slug: String
    let url: String
    var visibility: ShareVisibility
    var flagged: Bool
    let createdAt: Date
}

enum ShareVisibility: String, CaseIterable {
    case privateAccess = "private"
    case publicAccess = "public"
    
    var displayName: String {
        switch self {
        case .privateAccess: return "Private"
        case .publicAccess: return "Public"
        }
    }
    
    var description: String {
        switch self {
        case .privateAccess: return "Only people with the link can view"
        case .publicAccess: return "Anyone can discover and view"
        }
    }
}

#Preview {
    ShareLinkView(isPresented: .constant(true))
}
