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
                
                Circle()
                    .fill(Color.brandGradient)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text("EW")
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .cleanGlassmorphism(
                        style: ModernDesignSystem.GlassEffect.subtle,
                        shadow: ModernDesignSystem.Shadow.light
                    )
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .honeyGold))
                    .scaleEffect(1.2)
                
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

#Preview {
    LoadingView()
}
