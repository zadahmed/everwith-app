//
//  ModernPageHeader.swift
//  EverWith
//
//  Shared header component for consistent page headers
//

import SwiftUI

// MARK: - Modern Page Header
struct ModernPageHeader: View {
    let title: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 28, for: geometry), weight: .bold, design: .rounded))
                .foregroundColor(.deepPlum)
            
            Spacer()
        }
        .padding(.horizontal, geometry.adaptivePadding())
        .padding(.top, ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry))
        .padding(.bottom, ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
    }
}

#Preview {
    GeometryReader { geometry in
        ModernPageHeader(title: "Settings", geometry: geometry)
    }
}
