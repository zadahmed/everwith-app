//
//  ErrorView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: ModernDesignSystem.Spacing.xl) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Something went wrong")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                Text(message)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onRetry) {
                    Text("Try Again")
                }
                .buttonStyle(ModernButtonStyle(style: .primary))
                .frame(maxWidth: 200)
                
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
    ErrorView(message: "Unable to connect to the server") {
        print("Retry tapped")
    }
}
