# 🔧 EverWith IAP Testing Guide

## ✅ StoreKit Configuration File Fixed

The StoreKit configuration file is now properly set up for local testing in Xcode.

### **What Was Fixed**
1. Updated the scheme file path to point to the correct Configuration.storekit file
2. Configuration includes two subscription products:
   - **Premium Monthly**: $4.99/month
   - **Premium Yearly**: $69.99/year (40% savings)

---

## 🧪 How to Test In-App Purchases

### **Option 1: Local Testing with StoreKit Configuration File** (Recommended for Development)

1. **Open the project in Xcode**
   ```bash
   open everwith/everwith.xcodeproj
   ```

2. **Build and Run the app** (⌘R)
   - The app will automatically use the Configuration.storekit file for testing

3. **Test purchases**
   - Tap on any premium feature
   - You'll see the paywall
   - Tap "Purchase"
   - Local StoreKit will process the purchase instantly
   - No sandbox account needed!

4. **Verify subscription**
   - Go to Settings → Subscriptions
   - You'll see "Active Subscription"
   - Local purchases behave exactly like real ones

---

### **Option 2: Test with StoreKit Transaction Manager**

1. **Open Transaction Manager in Xcode**
   - Window → Testing → StoreKit Transaction Manager
   - Or press `⌘Shift⇧` and search "StoreKit"

2. **View transactions**
   - See all purchases made during testing
   - Clear transactions to test different scenarios
   - Refresh to check subscription status

3. **Test subscription renewal**
   - Use "Advance Time" to simulate subscription expiry
   - Test renewal behavior

---

### **Option 3: Sandbox Testing** (For App Store Testing)

1. **Create Sandbox Tester Account**
   - Go to App Store Connect
   - Users and Access → Sandbox Testers
   - Create a new tester account

2. **Sign Out of Production App Store**
   - Settings → App Store
   - Tap your Apple ID → Sign Out
   - (You'll sign in to sandbox when prompted)

3. **Test in the app**
   - Make test purchases
   - Sandbox accounts have their own balance
   - Use test credit cards for testing

---

## 📋 Test Scenarios to Cover

### **Basic Purchase Flow**
1. ✅ Launch app → See HomeView
2. ✅ Try to create a photo restore
3. ✅ See paywall (if no subscription/credits)
4. ✅ Tap "Purchase Monthly"
5. ✅ Verify purchase completes
6. ✅ Try photo restore again (should work)
7. ✅ Check Settings → Subscriptions shows active

### **Subscription Management**
1. ✅ Test monthly vs yearly subscriptions
2. ✅ Cancel subscription (Settings → Subscriptions)
3. ✅ Test grace period after cancellation
4. ✅ Test expiration and renewal

### **Restore Purchases**
1. ✅ Delete app
2. ✅ Reinstall app
3. ✅ Tap "Restore Purchases" in Settings
4. ✅ Verify subscription reactivates

### **Credit Purchase Flow**
1. ✅ Tap "Buy Credits" button
2. ✅ Select credit package
3. ✅ Complete purchase
4. ✅ Verify credits added to account
5. ✅ Use credits to process an image

---

## 🐛 Troubleshooting

### **StoreKit Configuration Not Working**

**Problem:** Purchases show "product not available"

**Solution:**
1. Check Xcode scheme: Product → Scheme → Edit Scheme
2. Verify "StoreKit Configuration" has the correct file selected
3. File should be: `everwith/Configuration.storekit`
4. Close and reopen Xcode

### **RevenueCat Issues**

**Problem:** "RevenueCat subscription status not updating"

**Solution:**
1. Check RevenueCat API key in `RevenueCatConfig.swift`
2. Verify RevenueCat dashboard is set up
3. Check network connectivity
4. Look for console errors

### **Subscription Not Restoring**

**Problem:** "Restore Purchases" doesn't work

**Solution:**
1. Make sure the app is using the same Apple ID
2. Check that purchases were made on the same device
3. Verify StoreKit Transaction Manager shows transactions
4. Try signing out and back into App Store

---

## 🔍 Debugging Tips

### **Enable StoreKit Debug Logging**
```swift
#if DEBUG
Purchases.logLevel = .debug
#endif
```

### **Check Transaction Status**
```swift
// In your code, add this to check status
Task {
    for await result in Transaction.updates {
        print("Transaction: \(result)")
    }
}
```

### **View StoreKit Logs**
- In Xcode Console, filter by "StoreKit"
- Look for purchase initiation, payment, and completion
- Check for any errors or warnings

---

## 📱 Testing on Real Device

### **For Real Device Testing:**

1. **Connect iPhone/iPad**
   - Use USB cable or network connection
   - Device should be trusted in Xcode

2. **Build for Device**
   - Product → Destination → Your Device
   - Build and Run (⌘R)

3. **Test IAP**
   - StoreKit Configuration works on real devices
   - No sandbox account needed for local testing
   - Purchases behave exactly like in simulator

---

## 🚀 Ready to Test!

### **Quick Start:**
```bash
# Open project
open everwith/everwith.xcodeproj

# Build and run
# Press ⌘R in Xcode

# Test IAP:
# 1. Open HomeView
# 2. Try to create a photo
# 3. Tap Purchase when prompted
# 4. Verify subscription activates
```

### **Monitor Success:**
- ✅ Purchases complete instantly (local testing)
- ✅ Subscriptions show as active in Settings
- ✅ Credit balance updates correctly
- ✅ App features unlock immediately
- ✅ RevenueCat dashboard shows events (if configured)

---

## 📞 Need Help?

If you encounter issues:
1. Check Xcode console for errors
2. Verify Configuration.storekit is in the project
3. Ensure scheme has StoreKit file reference
4. Try cleaning build folder (⌘Shift⇧K)
5. Restart Xcode

Happy testing! 🎉
