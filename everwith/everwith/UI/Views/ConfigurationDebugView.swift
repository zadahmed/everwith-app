//
//  ConfigurationDebugView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct ConfigurationDebugView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("App Configuration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    ConfigurationRow(title: "Environment", value: AppConfiguration.currentEnvironment.displayName)
                    ConfigurationRow(title: "Base URL", value: AppConfiguration.API.baseURL)
                    ConfigurationRow(title: "Timeout", value: "\(AppConfiguration.API.timeout)s")
                }
                
                Divider()
                
                Text("Authentication Endpoints")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    ConfigurationRow(title: "Register", value: AppConfiguration.AuthEndpoints.register)
                    ConfigurationRow(title: "Login", value: AppConfiguration.AuthEndpoints.login)
                    ConfigurationRow(title: "Google", value: AppConfiguration.AuthEndpoints.google)
                    ConfigurationRow(title: "Logout", value: AppConfiguration.AuthEndpoints.logout)
                }
                
                Divider()
                
                Text("API Endpoints")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    ConfigurationRow(title: "Messages", value: AppConfiguration.APIEndpoints.messages)
                    ConfigurationRow(title: "Events", value: AppConfiguration.APIEndpoints.events)
                    ConfigurationRow(title: "Users", value: AppConfiguration.APIEndpoints.users)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    struct ConfigurationRow: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .textSelection(.enabled)
            }
        }
    }
}

struct ConfigurationDebugView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationDebugView()
    }
}