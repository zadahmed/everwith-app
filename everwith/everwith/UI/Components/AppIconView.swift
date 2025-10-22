//
//  AppIconView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct AppIconView: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(Color.brandRadialGradient)
                .frame(width: size, height: size)
            
            // Inner glow effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size, height: size)
            
            // App Logo
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.6, height: size * 0.6)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        AppIconView(size: 120)
        AppIconView(size: 80)
        AppIconView(size: 60)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
