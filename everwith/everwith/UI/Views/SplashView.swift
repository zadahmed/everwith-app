//
//  SplashView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var animateGradient = false
    @State private var animateOrbs = false
    @State private var animateColors = false
    @State private var showContent = false
    
    let onComplete: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background matching your design system
                SplashBackground()
                    .opacity(backgroundOpacity)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo container with animations
                    VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                        // EverWith Logo
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: min(adaptiveSize(120, for: geometry), geometry.size.width * 0.3), 
                                   height: min(adaptiveSize(120, for: geometry), geometry.size.width * 0.3))
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                            .shadow(
                                color: Color.black.opacity(0.08),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        
                        // App name with gradient
                        Text("EverWith")
                            .font(.system(size: adaptiveFontSize(32, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                            .opacity(logoOpacity)
                            .offset(y: showContent ? 0 : 20)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: geometry.size.width * 0.9)
                        
                        // Tagline
                        Text("Preserve Your Memories")
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                            .foregroundColor(.softPlum)
                            .opacity(logoOpacity * 0.8)
                            .offset(y: showContent ? 0 : 30)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: geometry.size.width * 0.9)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, adaptivePadding(for: geometry))
                    
                    Spacer()
                    
                    // Loading indicator
                    VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .softPlum))
                            .scaleEffect(0.8)
                            .opacity(showContent ? 1 : 0)
                        
                        Text("Loading...")
                            .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                            .foregroundColor(.softPlum.opacity(0.6))
                            .opacity(showContent ? 1 : 0)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, adaptivePadding(for: geometry))
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 40 : 60)
                }
                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Background fade in
        withAnimation(.easeOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        // Logo entrance animation
        withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Content slide up
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            showContent = true
        }
        
        // Note: Dismissal is controlled by the parent coordinator
        // No auto-dismiss here - wait for parent to set showSplash = false
    }
    
    // MARK: - Adaptive Sizing Functions
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(8, min(16, screenWidth * 0.03))
    }
}

// MARK: - Splash Background Component
struct SplashBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Clean white base
            Color.pureWhite
                .ignoresSafeArea()
            
            // Very subtle gradient at top
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.lightBlush.opacity(0.08),
                    Color.pureWhite
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)
            .ignoresSafeArea(.all, edges: .top)
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animateGradient)
            
            // Subtle floating elements
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.lightBlush.opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: CGFloat(60 + index * 40), height: CGFloat(60 + index * 40))
                    .offset(
                        x: animateGradient ? CGFloat(-50 + index * 100) : CGFloat(50 + index * 80),
                        y: animateGradient ? CGFloat(-100 + index * 120) : CGFloat(-150 + index * 100)
                    )
                    .blur(radius: 20)
                    .opacity(0.3)
            }
        }
        .onAppear {
            animateGradient = true
        }
    }
}

#Preview {
    SplashView {
        print("Splash completed")
    }
}
