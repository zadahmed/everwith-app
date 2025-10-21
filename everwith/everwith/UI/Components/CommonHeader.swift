//
//  CommonHeader.swift
//  EverWith
//
//  Created by Zahid Ahmed on 21/10/2025.
//

import SwiftUI

struct CommonHeader: View {
    let title: String
    let onBack: () -> Void
    let geometry: GeometryProxy
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                    Image(systemName: "chevron.left")
                        .font(.system(
                            size: adaptiveFontSize(18, for: geometry),
                            weight: .semibold
                        ))
                    Text("Back")
                        .font(.system(
                            size: adaptiveFontSize(17, for: geometry),
                            weight: .regular
                        ))
                }
                .foregroundColor(.charcoal)
            }
            
            Spacer()
            
            Text(title)
                .font(.system(
                    size: adaptiveFontSize(17, for: geometry),
                    weight: .semibold
                ))
                .foregroundColor(.charcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
            
            Color.clear.frame(width: adaptiveSize(80, for: geometry))
        }
        .padding(.horizontal, adaptivePadding(for: geometry))
        .padding(.top, max(geometry.safeAreaInsets.top, 16))
        .padding(.bottom, adaptiveSpacing(12, for: geometry))
    }
    
    // MARK: - Adaptive Functions (matching HomeView)
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(12, min(16, screenWidth * 0.04))
    }
    
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
}

