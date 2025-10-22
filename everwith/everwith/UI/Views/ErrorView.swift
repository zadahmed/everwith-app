//
//  ErrorView.swift
//  EverWith
//
//  Error handling and retry screen
//

import SwiftUI

struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    let geometry: GeometryProxy
    @State private var animateIcon = false
    @State private var animateText = false
    
    var body: some View {
        ZStack {
            CleanWhiteBackground()
                .ignoresSafeArea()
            
            VStack(spacing: geometry.adaptiveSpacing(32)) {
                Spacer()
                
                // Error Icon
                ZStack {
                    // Pulsing background
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: geometry.adaptiveSize(160), height: geometry.adaptiveSize(160))
                        .blur(radius: 20)
                        .scaleEffect(animateIcon ? 1.1 : 0.9)
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: geometry.adaptiveSize(100), height: geometry.adaptiveSize(100))
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: geometry.adaptiveFontSize(48), weight: .medium))
                            .foregroundColor(.red)
                            .scaleEffect(animateIcon ? 1.0 : 0.8)
                    }
                }
                
                // Error Message
                VStack(spacing: geometry.adaptiveSpacing(16)) {
                    Text("Something went wrong")
                        .font(.system(size: geometry.adaptiveFontSize(28), weight: .bold, design: .rounded))
                        .foregroundColor(.deepPlum)
                        .multilineTextAlignment(.center)
                        .opacity(animateText ? 1.0 : 0.0)
                    
                    Text(error.isEmpty ? "Please try again. Sometimes AI needs a second to think." : error)
                        .font(.system(size: geometry.adaptiveFontSize(17), weight: .medium))
                        .foregroundColor(.softPlum)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, geometry.adaptivePadding())
                        .opacity(animateText ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: geometry.adaptiveSpacing(12)) {
                    Button(action: onRetry) {
                        HStack(spacing: geometry.adaptiveSpacing(12)) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                            
                            Text("Retry")
                                .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.adaptiveSize(56))
                        .background(LinearGradient.primaryBrand)
                        .cornerRadius(geometry.adaptiveCornerRadius(16))
                        .shadow(color: Color.blushPink.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    
                    Button(action: onDismiss) {
                        Text("Back to Home")
                            .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                            .foregroundColor(.softPlum)
                            .frame(maxWidth: .infinity)
                            .frame(height: geometry.adaptiveSize(48))
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(12))
                                    .stroke(Color.subtleBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, geometry.adaptivePadding())
                .opacity(animateText ? 1.0 : 0.0)
                
                // Help Link
                Button(action: {
                    // Open support
                }) {
                    HStack(spacing: geometry.adaptiveSpacing(6)) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: geometry.adaptiveFontSize(14)))
                        
                        Text("Need help? Contact Support")
                            .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                    }
                    .foregroundColor(.softPlum.opacity(0.8))
                }
                .opacity(animateText ? 1.0 : 0.0)
                
                Spacer()
                    .frame(height: geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 32)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                animateIcon = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateText = true
            }
            
            // Continuous pulsing
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                animateIcon = true
            }
        }
    }
}

// MARK: - Error Types Extension
extension Error {
    var userFriendlyMessage: String {
        switch self {
        case let urlError as URLError:
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection. Please check your network and try again."
            case .timedOut:
                return "The request took too long. Please try again."
            case .cannotFindHost, .cannotConnectToHost:
                return "Unable to connect to server. Please try again later."
            default:
                return "A network error occurred. Please check your connection."
            }
        default:
            return self.localizedDescription
        }
    }
}

#Preview {
    GeometryReader { geometry in
        ErrorView(
            error: "Network connection lost",
            onRetry: { print("Retry") },
            onDismiss: { print("Dismiss") },
            geometry: geometry
        )
    }
}

#Preview("Generic Error") {
    GeometryReader { geometry in
        ErrorView(
            error: "",
            onRetry: { print("Retry") },
            onDismiss: { print("Dismiss") },
            geometry: geometry
        )
    }
}
