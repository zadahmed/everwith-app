//
//  AdaptiveHelpers.swift
//  EverWith
//
//  Shared adaptive sizing functions for responsive design
//

import SwiftUI

// MARK: - Adaptive Helper Functions
public func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
    let screenWidth = geometry.size.width
    let scaleFactor = screenWidth / 375.0
    return base * scaleFactor
}

public func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
    let screenWidth = geometry.size.width
    let scaleFactor = screenWidth / 375.0
    return max(base * 0.9, min(base * 1.1, base * scaleFactor))
}

public func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
    let screenWidth = geometry.size.width
    let scaleFactor = screenWidth / 375.0
    return base * scaleFactor
}

public func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
    let screenWidth = geometry.size.width
    let scaleFactor = screenWidth / 375.0
    return base * scaleFactor
}

public func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
    let screenWidth = geometry.size.width
    // iPhone SE (375pt) = 12pt, iPhone 15 Pro (393pt) = 14pt, iPhone 15 Pro Max (430pt) = 16pt
    return max(12, min(16, screenWidth * 0.04))
}

