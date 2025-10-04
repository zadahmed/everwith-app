//
//  ResponsiveDesign.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

// MARK: - Responsive Design System
struct ResponsiveDesign {
    static func adaptivePadding(for geometry: GeometryProxy) -> EdgeInsets {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        
        // Base padding values
        let basePadding: CGFloat = ModernDesignSystem.Spacing.lg
        
        // Adaptive padding based on screen size
        let horizontalPadding: CGFloat = {
            if screenWidth < 375 { // iPhone SE and smaller
                return basePadding * 0.75
            } else if screenWidth < 414 { // iPhone standard
                return basePadding
            } else if screenWidth < 768 { // iPhone Plus/Max
                return basePadding * 1.25
            } else { // iPad and larger
                return basePadding * 1.5
            }
        }()
        
        let verticalPadding: CGFloat = {
            if screenHeight < 667 { // iPhone SE height
                return basePadding * 0.75
            } else if screenHeight < 812 { // iPhone standard height
                return basePadding
            } else if screenHeight < 896 { // iPhone Plus height
                return basePadding * 1.25
            } else { // iPhone Max and larger
                return basePadding * 1.5
            }
        }()
        
        return EdgeInsets(
            top: verticalPadding,
            leading: horizontalPadding,
            bottom: verticalPadding,
            trailing: horizontalPadding
        )
    }
    
    static func adaptiveFontSize(baseSize: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        
        if screenWidth < 375 { // iPhone SE and smaller
            return baseSize * 0.9
        } else if screenWidth < 414 { // iPhone standard
            return baseSize
        } else if screenWidth < 768 { // iPhone Plus/Max
            return baseSize * 1.1
        } else { // iPad and larger
            return baseSize * 1.2
        }
    }
    
    static func adaptiveSpacing(baseSpacing: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        
        if screenWidth < 375 { // iPhone SE and smaller
            return baseSpacing * 0.8
        } else if screenWidth < 414 { // iPhone standard
            return baseSpacing
        } else if screenWidth < 768 { // iPhone Plus/Max
            return baseSpacing * 1.2
        } else { // iPad and larger
            return baseSpacing * 1.4
        }
    }
    
    static func adaptiveCornerRadius(baseRadius: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        
        if screenWidth < 375 { // iPhone SE and smaller
            return baseRadius * 0.9
        } else if screenWidth < 414 { // iPhone standard
            return baseRadius
        } else if screenWidth < 768 { // iPhone Plus/Max
            return baseRadius * 1.1
        } else { // iPad and larger
            return baseRadius * 1.2
        }
    }
    
    static func adaptiveButtonHeight(baseHeight: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        if screenHeight < 667 { // iPhone SE height
            return baseHeight * 0.9
        } else if screenHeight < 812 { // iPhone standard height
            return baseHeight
        } else if screenHeight < 896 { // iPhone Plus height
            return baseHeight * 1.1
        } else { // iPhone Max and larger
            return baseHeight * 1.15
        }
    }
    
    static func adaptiveTabBarHeight(baseHeight: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        if screenHeight < 667 { // iPhone SE height
            return baseHeight * 0.9
        } else if screenHeight < 812 { // iPhone standard height
            return baseHeight
        } else if screenHeight < 896 { // iPhone Plus height
            return baseHeight * 1.1
        } else { // iPhone Max and larger
            return baseHeight * 1.15
        }
    }
    
    static func adaptiveNavBarHeight(baseHeight: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        if screenHeight < 667 { // iPhone SE height
            return baseHeight * 0.9
        } else if screenHeight < 812 { // iPhone standard height
            return baseHeight
        } else if screenHeight < 896 { // iPhone Plus height
            return baseHeight * 1.1
        } else { // iPhone Max and larger
            return baseHeight * 1.15
        }
    }
}

// MARK: - Responsive View Modifiers
struct ResponsivePadding: ViewModifier {
    let geometry: GeometryProxy
    
    func body(content: Content) -> some View {
        content
            .padding(ResponsiveDesign.adaptivePadding(for: geometry))
    }
}

struct ResponsiveFont: ViewModifier {
    let baseSize: CGFloat
    let geometry: GeometryProxy
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: baseSize, for: geometry)))
    }
}

struct ResponsiveSpacing: ViewModifier {
    let baseSpacing: CGFloat
    let geometry: GeometryProxy
    
    func body(content: Content) -> some View {
        content
            .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: baseSpacing, for: geometry))
    }
}

struct ResponsiveCornerRadius: ViewModifier {
    let baseRadius: CGFloat
    let geometry: GeometryProxy
    
    func body(content: Content) -> some View {
        content
            .cornerRadius(ResponsiveDesign.adaptiveCornerRadius(baseRadius: baseRadius, for: geometry))
    }
}

// MARK: - View Extensions
extension View {
    func responsivePadding(for geometry: GeometryProxy) -> some View {
        self.modifier(ResponsivePadding(geometry: geometry))
    }
    
    func responsiveFont(size: CGFloat, for geometry: GeometryProxy) -> some View {
        self.modifier(ResponsiveFont(baseSize: size, geometry: geometry))
    }
    
    func responsiveSpacing(_ spacing: CGFloat, for geometry: GeometryProxy) -> some View {
        self.modifier(ResponsiveSpacing(baseSpacing: spacing, geometry: geometry))
    }
    
    func responsiveCornerRadius(_ radius: CGFloat, for geometry: GeometryProxy) -> some View {
        self.modifier(ResponsiveCornerRadius(baseRadius: radius, geometry: geometry))
    }
}

// MARK: - Screen Size Detection
extension GeometryProxy {
    var isSmallScreen: Bool {
        size.width < 375 || size.height < 667
    }
    
    var isMediumScreen: Bool {
        (size.width >= 375 && size.width < 414) || (size.height >= 667 && size.height < 812)
    }
    
    var isLargeScreen: Bool {
        (size.width >= 414 && size.width < 768) || (size.height >= 812 && size.height < 896)
    }
    
    var isExtraLargeScreen: Bool {
        size.width >= 768 || size.height >= 896
    }
    
    var isLandscape: Bool {
        size.width > size.height
    }
    
    var isPortrait: Bool {
        size.height > size.width
    }
}
