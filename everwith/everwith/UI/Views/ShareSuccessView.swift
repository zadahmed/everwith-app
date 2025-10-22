//
//  ShareSuccessView.swift
//  EverWith
//
//  Celebration screen after sharing
//

import SwiftUI

struct ShareSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    let geometry: GeometryProxy
    @State private var animateCheckmark = false
    @State private var showConfetti = false
    @State private var animateText = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.pureWhite,
                    Color.lightBlush.opacity(0.2),
                    Color.blushPink.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: geometry.adaptiveSpacing(32)) {
                Spacer()
                
                // Success Animation
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.honeyGold.opacity(0.4),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: geometry.adaptiveSize(200), height: geometry.adaptiveSize(200))
                        .blur(radius: 30)
                        .scaleEffect(animateCheckmark ? 1.2 : 0.8)
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.honeyGold,
                                        Color.honeyGold.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: geometry.adaptiveSize(120), height: geometry.adaptiveSize(120))
                            .shadow(color: Color.honeyGold.opacity(0.4), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: geometry.adaptiveFontSize(56), weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animateCheckmark ? 1.0 : 0.3)
                            .rotationEffect(.degrees(animateCheckmark ? 0 : -45))
                    }
                }
                
                // Message
                VStack(spacing: geometry.adaptiveSpacing(16)) {
                    Text("Your memory has been shared 🎉")
                        .font(.system(size: geometry.adaptiveFontSize(28), weight: .bold, design: .rounded))
                        .foregroundColor(.deepPlum)
                        .multilineTextAlignment(.center)
                        .opacity(animateText ? 1.0 : 0.0)
                    
                    VStack(spacing: geometry.adaptiveSpacing(8)) {
                        Text("You've earned 1 free credit for")
                            .font(.system(size: geometry.adaptiveFontSize(17), weight: .medium))
                            .foregroundColor(.softPlum)
                        
                        Text("sharing Everwith!")
                            .font(.system(size: geometry.adaptiveFontSize(17), weight: .bold))
                            .foregroundStyle(LinearGradient.primaryBrand)
                    }
                    .opacity(animateText ? 1.0 : 0.0)
                    
                    // Credit Badge
                    HStack(spacing: geometry.adaptiveSpacing(8)) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: geometry.adaptiveFontSize(20)))
                            .foregroundColor(.honeyGold)
                        
                        Text("+1 Credit")
                            .font(.system(size: geometry.adaptiveFontSize(16), weight: .bold))
                            .foregroundColor(.deepPlum)
                    }
                    .padding(.horizontal, geometry.adaptiveSpacing(20))
                    .padding(.vertical, geometry.adaptiveSpacing(12))
                    .background(
                        Capsule()
                            .fill(Color.honeyGold.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.honeyGold.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .scaleEffect(animateText ? 1.0 : 0.8)
                }
                .padding(.horizontal, geometry.adaptivePadding())
                
                Spacer()
                
                // Actions
                VStack(spacing: geometry.adaptiveSpacing(12)) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: geometry.adaptiveSpacing(12)) {
                            Text("Create Another")
                                .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.adaptiveSize(56))
                        .background(LinearGradient.primaryBrand)
                        .cornerRadius(geometry.adaptiveCornerRadius(16))
                        .shadow(color: Color.blushPink.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                            .foregroundColor(.softPlum)
                    }
                }
                .padding(.horizontal, geometry.adaptivePadding())
                .opacity(animateText ? 1.0 : 0.0)
                
                Spacer()
                    .frame(height: geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 32)
            }
            
            // Confetti
            if showConfetti {
                ConfettiView(geometry: geometry)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                animateCheckmark = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                animateText = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

#Preview {
    GeometryReader { geometry in
        ShareSuccessView(geometry: geometry)
    }
}

