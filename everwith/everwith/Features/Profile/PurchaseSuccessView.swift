//
//  PurchaseSuccessView.swift
//  EverWith
//
//  Purchase confirmation and success screen
//

import SwiftUI

struct PurchaseSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    var creditCount: Int? = nil
    @State private var animateCheckmark = false
    @State private var animateConfetti = false
    @State private var autoRedirect = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Success Background
                SuccessBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: geometry.adaptiveSpacing(32)) {
                    Spacer()
                    
                    // Success Animation
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.honeyGold.opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: geometry.adaptiveSize(200), height: geometry.adaptiveSize(200))
                            .blur(radius: 30)
                            .scaleEffect(animateCheckmark ? 1.2 : 0.8)
                        
                        // Checkmark Circle
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.honeyGold,
                                            Color.honeyGold.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: geometry.adaptiveSize(120), height: geometry.adaptiveSize(120))
                                .shadow(
                                    color: Color.honeyGold.opacity(0.4),
                                    radius: 20,
                                    x: 0,
                                    y: 10
                                )
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: geometry.adaptiveFontSize(60), weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(animateCheckmark ? 1.0 : 0.3)
                        }
                    }
                    
                    // Success Message
                    VStack(spacing: geometry.adaptiveSpacing(16)) {
                        Text(creditCount != nil ? "Credits Purchased!" : "You're Now Premium!")
                            .font(.system(size: geometry.adaptiveFontSize(32), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                            .multilineTextAlignment(.center)
                        
                        if let credits = creditCount {
                            Text("You now have \(credits) credits to use")
                                .font(.system(size: geometry.adaptiveFontSize(18), weight: .medium))
                                .foregroundColor(.softPlum)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Enjoy unlimited HD memories")
                                .font(.system(size: geometry.adaptiveFontSize(18), weight: .medium))
                                .foregroundColor(.softPlum)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .opacity(animateCheckmark ? 1.0 : 0.0)
                    
                    Spacer()
                    
                    // CTA Button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: geometry.adaptiveSpacing(12)) {
                            Text("Start Creating")
                                .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.adaptiveSize(56))
                        .background(LinearGradient.primaryBrand)
                        .cornerRadius(geometry.adaptiveCornerRadius(16))
                        .shadow(color: Color.blushPink.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, geometry.adaptivePadding())
                    .opacity(animateCheckmark ? 1.0 : 0.0)
                    
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 32 : 48)
                }
                
                // Confetti
                if animateConfetti {
                    ConfettiView(geometry: geometry)
                }
            }
            .onAppear {
                // Animate checkmark
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                    animateCheckmark = true
                }
                
                // Show confetti
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateConfetti = true
                }
                
                // Auto redirect after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    autoRedirect = true
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled(false)
    }
}

// MARK: - Success Background
struct SuccessBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.pureWhite,
                Color.honeyGold.opacity(0.15),
                Color.lightBlush.opacity(0.1)
            ]),
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animateGradient)
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    let geometry: GeometryProxy
    @State private var confettiItems: [ConfettiItem] = []
    
    struct ConfettiItem: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var color: Color
        var scale: CGFloat
    }
    
    var body: some View {
        ZStack {
            ForEach(confettiItems) { item in
                Circle()
                    .fill(item.color)
                    .frame(width: item.scale * 8, height: item.scale * 8)
                    .position(x: item.x, y: item.y)
                    .rotationEffect(.degrees(item.rotation))
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.blushPink, .roseMagenta, .honeyGold, .lightBlush, .memoryViolet]
        
        for _ in 0..<30 {
            let item = ConfettiItem(
                x: CGFloat.random(in: 0...geometry.size.width),
                y: CGFloat.random(in: 0...geometry.size.height),
                rotation: Double.random(in: 0...360),
                color: colors.randomElement() ?? .blushPink,
                scale: CGFloat.random(in: 0.5...1.5)
            )
            
            withAnimation(
                .easeOut(duration: Double.random(in: 2.0...4.0))
                .delay(Double.random(in: 0...0.5))
            ) {
                confettiItems.append(item)
            }
        }
    }
}

#Preview {
    PurchaseSuccessView()
}

#Preview("Credits") {
    PurchaseSuccessView(creditCount: 15)
}

