# iOS App Authentication Integration Guide

This guide will help you integrate the new authentication system into your iOS app.

## Prerequisites

1. **Google Sign-In SDK**: Add Google Sign-In to your iOS project
2. **GoogleService-Info.plist**: Download from Google Cloud Console
3. **Backend Running**: Ensure your backend server is running

## Setup Steps

### 1. Add Google Sign-In SDK

Add the Google Sign-In SDK to your project:

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the URL: `https://github.com/google/GoogleSignIn-iOS`
3. Select the latest version and add to your target

### 2. Configure Google Sign-In

1. Download `GoogleService-Info.plist` from your Google Cloud Console project
2. Add it to your Xcode project (make sure it's added to your app target)
3. The file should contain your `CLIENT_ID` and other Google configuration

### 3. Update Info.plist

Add the following URL scheme to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the value from your `GoogleService-Info.plist`.

### 4. Configure AppDelegate

Update your `AppDelegate.swift` to configure Google Sign-In:

```swift
import GoogleSignIn

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Configure Google Sign-In
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let clientId = plist["CLIENT_ID"] as? String else {
        fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
    }
    
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    
    return true
}

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}
```

### 5. Update Authentication View

The `AuthenticationService` now supports multiple authentication methods:

```swift
// Email/Password Sign Up
let result = await authService.signUpWithEmail(
    email: "user@example.com", 
    password: "password123", 
    name: "John Doe"
)

// Email/Password Sign In
let result = await authService.signInWithEmail(
    email: "user@example.com", 
    password: "password123"
)

// Google Sign In
let result = await authService.signInWithGoogle()

// Apple Sign In
let result = await authService.signInWithApple()

// Guest Sign In
let result = await authService.signInAsGuest()
```

### 6. Handle Authentication Results

```swift
switch result {
case .success(let user):
    // User successfully authenticated
    print("Welcome, \(user.name)!")
    
case .failure(let error):
    // Handle authentication error
    if let authError = error as? AuthenticationError {
        print("Authentication error: \(authError.localizedDescription)")
    }
    
case .cancelled:
    // User cancelled authentication
    print("Authentication cancelled")
}
```

## Authentication Flow

### Email/Password Authentication
1. User enters email, password, and name
2. App sends registration/login request to backend
3. Backend validates credentials and returns JWT token
4. App stores user data and token locally

### Google Sign-In Authentication
1. User taps Google Sign-In button
2. Google Sign-In SDK presents authentication flow
3. User authenticates with Google
4. App receives Google ID token
5. App sends ID token to backend for verification
6. Backend verifies token and returns user data + JWT token
7. App stores user data and token locally

### Apple Sign-In Authentication
1. User taps Apple Sign-In button
2. Apple Sign-In presents authentication flow
3. User authenticates with Apple ID
4. App receives Apple ID token
5. App can send token to backend for verification (optional)
6. App stores user data locally

## Security Features

- **JWT Tokens**: Secure token-based authentication
- **Token Storage**: Tokens stored securely in UserDefaults
- **Backend Verification**: Google tokens verified server-side
- **Automatic Logout**: Proper cleanup on sign out
- **Error Handling**: Comprehensive error handling and user feedback

## Testing

### Backend Testing
1. Start your backend server: `python main.py`
2. Test endpoints at `http://localhost:8000/docs`

### iOS Testing
1. Update the `baseURL` in `AuthenticationService.swift` to match your backend URL
2. Test authentication flows in the iOS app
3. Verify tokens are stored and used correctly

## Production Considerations

1. **HTTPS**: Use HTTPS URLs in production
2. **Token Expiration**: Implement token refresh logic
3. **Error Handling**: Add proper error handling and user feedback
4. **Security**: Store sensitive data in Keychain instead of UserDefaults
5. **Analytics**: Add authentication analytics and monitoring

## Troubleshooting

### Common Issues

1. **Google Sign-In Not Working**
   - Verify `GoogleService-Info.plist` is properly configured
   - Check URL scheme in `Info.plist`
   - Ensure `CLIENT_ID` matches your Google Cloud Console project

2. **Backend Connection Issues**
   - Verify backend server is running
   - Check network connectivity
   - Verify CORS settings in backend

3. **Token Issues**
   - Check token expiration
   - Verify token format and structure
   - Ensure proper token storage and retrieval

### Debug Tips

- Enable network logging to see API requests
- Check console logs for authentication errors
- Verify user data is properly stored and retrieved
- Test with different authentication methods
