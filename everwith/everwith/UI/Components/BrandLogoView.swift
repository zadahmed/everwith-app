//
//  BrandLogoView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct BrandLogoView: View {
    let size: CGFloat
    let showTagline: Bool
    
    init(size: CGFloat = 200, showTagline: Bool = true) {
        self.size = size
        self.showTagline = showTagline
    }
    
    var body: some View {
        VStack(spacing: size * 0.08) {
            // Main wordmark
            HStack(spacing: size * 0.02) {
                Text("Ever")
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                // Heart ligature between 'r' and 'W'
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                Text("With")
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
            }
            
            // Tagline
            if showTagline {
                Text("Together in every photo.")
                    .font(.system(size: size * 0.12, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.7))
            }
        }
    }
}

struct BrandMonogramView: View {
    let size: CGFloat
    
    init(size: CGFloat = 100) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.brandGradient)
                .frame(width: size, height: size)
            
            // App Logo
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.6, height: size * 0.6)
        }
    }
}

struct BrandLogoView_Previews: PreviewProvider {
    static var previews: some View {
    VStack(spacing: 40) {
        BrandLogoView(size: 200)
        
        HStack(spacing: 20) {
            BrandMonogramView(size: 80)
            BrandMonogramView(size: 60)
            BrandMonogramView(size: 40)
        }
        
        BrandLogoView(size: 120, showTagline: false)
    }
    .padding()
    .background(Color.warmLinen)
}
}
