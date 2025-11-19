//
//  ViralShareModal.swift
//  EverWith
//
//  Created by Zahid Ahmed on 19/11/2025.
//

import SwiftUI

struct ViralShareModal: View {
    let baseImage: UIImage
    let flowType: ShareFlowType
    let onDismiss: () -> Void
    let onVerified: () -> Void
    
    @State private var selectedPlatform: SharePlatform?
    @State private var shareURL: String = ""
    @State private var hasShared: Bool = false
    @State private var isSharing: Bool = false
    @State private var isVerifying: Bool = false
    @State private var confirmedHashtag: Bool = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var showAlert: Bool = false
    @FocusState private var urlFieldFocused: Bool
    
    private let hashtag = "#EverwithApp"
    private let shareService = ShareVerificationService.shared
    private let monetizationManager = MonetizationManager.shared
    
    private var shareImage: UIImage {
        monetizationManager.shareReadyImage(from: baseImage)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.adaptiveSpacing(16)) {
                Capsule()
                    .fill(Color.subtleBorder)
                    .frame(width: geometry.adaptiveSize(60), height: 5)
                    .padding(.top, geometry.adaptiveSpacing(12))
                
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: geometry.adaptiveFontSize(24), weight: .bold))
                            .foregroundColor(.softPlum)
                    }
                }
                .padding(.horizontal, geometry.adaptiveSpacing(20))
                .padding(.top, geometry.adaptiveSpacing(4))
                
                VStack(spacing: geometry.adaptiveSpacing(8)) {
                    Text("Share to unlock +1 credit")
                        .font(.system(size: geometry.adaptiveFontSize(24), weight: .bold, design: .rounded))
                        .foregroundColor(.deepPlum)
                    
                    Text("Post this memory on TikTok or Instagram with \(hashtag) to earn a free credit.")
                        .font(.system(size: geometry.adaptiveFontSize(15), weight: .medium))
                        .foregroundColor(.softPlum)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, geometry.adaptiveSpacing(24))
                }
                .padding(.top, geometry.adaptiveSpacing(8))
                
                Image(uiImage: shareImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(26)))
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Label("Made with Everwith", systemImage: "sparkles")
                                    .font(.system(size: geometry.adaptiveFontSize(14), weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Capsule())
                                    .padding()
                                Spacer()
                            }
                        }
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, geometry.adaptiveSpacing(20))
                
                VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(12)) {
                    Text("Choose a platform")
                        .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                        .foregroundColor(.deepPlum)
                    
                    HStack(spacing: geometry.adaptiveSpacing(12)) {
                        ForEach(SharePlatform.allCases) { platform in
                            Button {
                                startShare(on: platform)
                            } label: {
                                HStack(spacing: geometry.adaptiveSpacing(8)) {
                                    Image(systemName: platform.systemIcon)
                                        .font(.system(size: geometry.adaptiveFontSize(20), weight: .medium))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(platform.displayName)
                                            .font(.system(size: geometry.adaptiveFontSize(15), weight: .semibold))
                                        Text("Share now")
                                            .font(.system(size: geometry.adaptiveFontSize(12), weight: .medium))
                                            .opacity(0.8)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, geometry.adaptiveSpacing(14))
                                .padding(.horizontal, geometry.adaptiveSpacing(20))
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        colors: platform.accentColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(20))
                                        .stroke(selectedPlatform == platform ? Color.white.opacity(0.6) : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(geometry.adaptiveCornerRadius(20))
                            }
                            .disabled(isSharing || isVerifying)
                            .opacity(selectedPlatform == platform || selectedPlatform == nil ? 1.0 : 0.6)
                        }
                    }
                }
                .padding(.horizontal, geometry.adaptiveSpacing(20))
                
                VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(12)) {
                    Text("Share link (optional)")
                        .font(.system(size: geometry.adaptiveFontSize(15), weight: .semibold))
                        .foregroundColor(.deepPlum)
                    
                    TextField("https://", text: $shareURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .focused($urlFieldFocused)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(geometry.adaptiveCornerRadius(16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    
                    Toggle(isOn: $confirmedHashtag) {
                        Text("I posted publicly with \(hashtag)")
                            .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                            .foregroundColor(.softPlum)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.honeyGold))
                }
                .padding(.horizontal, geometry.adaptiveSpacing(20))
                
                if let info = infoMessage {
                    Text(info)
                        .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                        .foregroundColor(.honeyGold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, geometry.adaptiveSpacing(20))
                }
                
                Button(action: verifyShare) {
                    HStack(spacing: geometry.adaptiveSpacing(10)) {
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isVerifying ? "Verifying..." : "Verify & Claim +1 Credit")
                            .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.adaptiveSize(56))
                    .background(LinearGradient.primaryBrand)
                    .cornerRadius(geometry.adaptiveCornerRadius(18))
                    .shadow(color: Color.blushPink.opacity(0.35), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, geometry.adaptiveSpacing(20))
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : geometry.adaptiveSpacing(20))
                .disabled(!canVerify)
                .opacity(canVerify ? 1.0 : 0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.pureWhite.ignoresSafeArea(.all))
        }
        .interactiveDismissDisabled(isVerifying)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Share Verification"),
                message: Text(errorMessage ?? "Something went wrong."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var canVerify: Bool {
        selectedPlatform != nil && hasShared && confirmedHashtag && !isVerifying
    }
    
    private func startShare(on platform: SharePlatform) {
        guard !isSharing else { return }
        isSharing = true
        errorMessage = nil
        infoMessage = nil
        
        SocialShareManager.shared.share(image: shareImage, platform: platform, hashtag: hashtag) { result in
            DispatchQueue.main.async {
                self.isSharing = false
                switch result {
                case .success:
                    self.selectedPlatform = platform
                    self.hasShared = true
                    self.infoMessage = "Shared to \(platform.displayName). Paste your link (optional) and tap verify."
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
    
    private func verifyShare() {
        guard canVerify, let platform = selectedPlatform else {
            errorMessage = "Please share first."
            showAlert = true
            return
        }
        
        isVerifying = true
        errorMessage = nil
        
        let trimmedURL = shareURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = ShareVerificationPayload(
            platform: platform.rawValue,
            shareUrl: trimmedURL.isEmpty ? nil : trimmedURL,
            caption: hashtag,
            hashtags: [hashtag],
            shareType: flowType.identifier
        )
        
        Task {
            do {
                let response = try await shareService.verifyShare(payload: payload)
                infoMessage = response.message
                await monetizationManager.fetchRealCredits()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isVerifying = false
                onVerified()
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
                isVerifying = false
            }
        }
    }
}

#Preview {
    ViralShareModal(
        baseImage: UIImage(named: "best_friends_reunion_image") ?? UIImage(),
        flowType: .restore,
        onDismiss: {},
        onVerified: {}
    )
}

