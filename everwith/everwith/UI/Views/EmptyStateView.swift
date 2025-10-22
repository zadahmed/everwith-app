//
//  EmptyStateView.swift
//  EverWith
//
//  Empty state for when user has no creations
//

import SwiftUI

struct EmptyStateView: View {
    let geometry: GeometryProxy
    @State private var animateIcon = false
    @State private var animateText = false
    var onGetStarted: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: geometry.adaptiveSpacing(32)) {
            Spacer()
            
            // Animated Icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blushPink.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: geometry.adaptiveSize(200), height: geometry.adaptiveSize(200))
                    .blur(radius: 20)
                    .scaleEffect(animateIcon ? 1.1 : 0.9)
                
                // Main icon
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: geometry.adaptiveFontSize(80), weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blushPink.opacity(0.6),
                                Color.roseMagenta.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateIcon ? 1.0 : 0.8)
            }
            
            // Message
            VStack(spacing: geometry.adaptiveSpacing(12)) {
                Text("No memories yet")
                    .font(.system(size: geometry.adaptiveFontSize(28), weight: .bold, design: .rounded))
                    .foregroundColor(.deepPlum)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Text("Start by restoring a photo or\nmerging two together")
                    .font(.system(size: geometry.adaptiveFontSize(17), weight: .medium))
                    .foregroundColor(.softPlum)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateText ? 1.0 : 0.0)
            }
            .padding(.horizontal, geometry.adaptivePadding())
            
            // CTA Button
            if let action = onGetStarted {
                Button(action: action) {
                    HStack(spacing: geometry.adaptiveSpacing(12)) {
                        Text("Get Started")
                            .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: geometry.size.width * 0.7)
                    .frame(height: geometry.adaptiveSize(56))
                    .background(LinearGradient.primaryBrand)
                    .cornerRadius(geometry.adaptiveCornerRadius(16))
                    .shadow(color: Color.blushPink.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .opacity(animateText ? 1.0 : 0.0)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                animateIcon = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateText = true
            }
            
            // Continuous breathing animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(0.5)
            ) {
                animateIcon = true
            }
        }
    }
}

#Preview {
    GeometryReader { geometry in
        EmptyStateView(geometry: geometry) {
            print("Get Started tapped")
        }
    }
}

