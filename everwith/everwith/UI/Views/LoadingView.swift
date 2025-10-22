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
                    .fill(LinearGradient.primaryBrand)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
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
