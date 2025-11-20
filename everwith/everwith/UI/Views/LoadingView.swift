//
//  LoadingView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: ModernDesignSystem.Spacing.xl) {
                Spacer()
                
                // App Logo
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                
                // Subtle white-to-brand gradient loading indicator
                SubtleGradientLoader()
                
                Text("Loading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.7))
                
                Spacer()
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .background(Color.warmLinen)
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Subtle Gradient Loader
struct SubtleGradientLoader: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle with subtle white
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 3)
                .frame(width: 40, height: 40)
            
            // Animated progress circle with subtle white-to-brand gradient
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.3),
                            Color.blushPink.opacity(0.4),
                            Color.roseMagenta.opacity(0.3),
                            Color.white.opacity(0.4)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                    ) {
                        rotation = 360
                    }
                }
        }
        .frame(width: 50, height: 50)
    }
}

#Preview {
    LoadingView()
}
