# SwiftUI Bridge Not Found - Diagnostic Steps

The error "SwiftUI bridge not available" means the `BlueShiftSwiftUIBridge` class is not being loaded at runtime. Let's diagnose:

## Step 1: Verify Podfile Changes

**Check your sample app's Podfile:**
```ruby
# Should be:
pod 'BlueShift-iOS-SDK/SwiftUI'

# NOT:
pod 'BlueShift-iOS-SDK'
# or
pod 'BlueShift-iOS-SDK/Core'
```

## Step 2: Verify Pod Install Output

After running `pod install`, check the output. You should see:
```
Installing BlueShift-iOS-SDK 2.6.0 (was X.X.X)
```

And in your `Podfile.lock`, you should see:
```yaml
PODS:
  - BlueShift-iOS-SDK/Core (2.6.0)
  - BlueShift-iOS-SDK/SwiftUI (2.6.0):
    - BlueShift-iOS-SDK/Core
```

## Step 3: Check Build Settings

**In your sample app's Xcode project:**

1. Open your `.xcworkspace` (NOT `.xcodeproj`)
2. Select your app target
3. Go to Build Phases → Link Binary With Libraries
4. Verify `BlueShift-iOS-SDK` is listed

## Step 4: Check if Swift Files are Compiled

**In Xcode:**
1. Go to Build Phases → Compile Sources
2. Search for "BlueShiftSwiftUIBridge.swift"
3. If it's NOT there, the SwiftUI subspec wasn't installed

## Step 5: Clean Build

```bash
# In your sample app directory
rm -rf ~/Library/Developer/Xcode/DerivedData/*
pod deintegrate
pod install
```

Then in Xcode:
- Product → Clean Build Folder (Cmd+Shift+K)
- Product → Build (Cmd+B)

## Step 6: Verify Bridging Header

Since you're mixing Objective-C and Swift, check if your app has a bridging header. The SwiftUI classes should be automatically available to Objective-C via `@objc` attributes.

## Step 7: Check Module Import

The SDK's SwiftUI module should be automatically imported. Verify in your Pods project:
- Open Pods.xcodeproj
- Find BlueShift-iOS-SDK target
- Check Build Settings → Defines Module = YES

## Step 8: Add Debug Logging

**Temporarily add this to your AppDelegate to verify:**

```swift
import BlueShift_iOS_SDK

// In application(_:didFinishLaunchingWithOptions:)
print("=== BLUESHIFT DEBUG ===")
print("Config useSwiftUIForInApp:", config.useSwiftUIForInApp)

// Check if class exists
if let bridgeClass = NSClassFromString("BlueShiftSwiftUIBridge") {
    print("✅ BlueShiftSwiftUIBridge class found:", bridgeClass)
} else {
    print("❌ BlueShiftSwiftUIBridge class NOT found")
}

// Try direct import
if #available(iOS 13.0, *) {
    let bridge = BlueShiftSwiftUIBridge.shared
    print("✅ Direct access to bridge works:", bridge)
}
```

## Step 9: Verify Podspec Source

Check your Podfile's source:
```ruby
source 'https://github.com/CocoaPods/Specs.git'

target 'YourApp' do
  use_frameworks!  # Important for Swift!
  pod 'BlueShift-iOS-SDK/SwiftUI'
end
```

**CRITICAL:** Make sure you have `use_frameworks!` in your Podfile for Swift code to work!

## Step 10: Check Pod Version

```bash
pod --version  # Should be 1.10.0 or higher
```

## Most Likely Issues:

### Issue 1: Missing `use_frameworks!`
**Solution:** Add to Podfile:
```ruby
target 'YourApp' do
  use_frameworks!  # Add this line
  pod 'BlueShift-iOS-SDK/SwiftUI'
end
```

### Issue 2: Using .xcodeproj instead of .xcworkspace
**Solution:** Always open the `.xcworkspace` file after pod install

### Issue 3: Old pod cache
**Solution:**
```bash
pod cache clean --all
pod deintegrate
pod install
```

### Issue 4: Subspec not actually installed
**Solution:** Check Podfile.lock - if you don't see "BlueShift-iOS-SDK/SwiftUI" listed, the subspec wasn't installed.

## What to Share for Further Help

If still not working, please share:
1. Your complete Podfile
2. Output of `pod install`
3. Contents of Podfile.lock (the BlueShift-iOS-SDK section)
4. Output of the debug logging from Step 8
5. Screenshot of Build Phases → Compile Sources showing Swift files
