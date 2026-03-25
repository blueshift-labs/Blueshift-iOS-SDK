# BlueShift SwiftUI Support

This module provides SwiftUI-based rendering for Blueshift in-app notifications.

## Requirements

- iOS 13.0+
- Swift 5.0+
- BlueShift-iOS-SDK Core

## Installation

### CocoaPods

Add the SwiftUI subspec to your Podfile:

```ruby
pod 'BlueShift-iOS-SDK/SwiftUI'
```

This will automatically include the Core SDK as a dependency.

## Usage

### 1. Enable SwiftUI Rendering

In your app configuration, enable SwiftUI rendering:

```swift
import BlueShift_iOS_SDK

let config = BlueShiftConfig()
config.apiKey = "YOUR_API_KEY"
config.enableInAppNotification = true
config.useSwiftUIForInApp = true  // Enable SwiftUI rendering

BlueShift.sharedInstance()?.initWithConfiguration(config)
```

### 2. That's It!

The SDK will automatically use SwiftUI views to render in-app notifications when `useSwiftUIForInApp` is set to `true`.

## Features

- ✅ Universal slide-in banner for all notification types
- ✅ Top or bottom positioning
- ✅ Auto-dismiss after 5 seconds
- ✅ Swipe to dismiss gesture
- ✅ Dark mode support
- ✅ Custom styling from payload
- ✅ Action button handling
- ✅ Deep link support
- ✅ Smooth animations
- ✅ Image loading with AsyncImage

## Current Implementation

**MVP Approach:** For simplicity, all in-app notification types (modal, slide banner, HTML) are displayed as slide-in banners. This provides:

- Consistent user experience
- Simpler codebase
- Faster implementation
- Easy to extend later

Future versions may add type-specific views (modals, full-screen HTML, etc.).

## Fallback Behavior

If SwiftUI is not available or `useSwiftUIForInApp` is `false`, the SDK automatically falls back to UIKit-based rendering.

## Architecture

```
SwiftUI/
├── BlueShiftSwiftUI.h                      # Umbrella header
├── Bridge/                                  # Objective-C ↔ SwiftUI bridge
│   ├── BlueShiftInAppRenderer.swift
│   ├── BlueShiftSwiftUIBridge.swift
│   └── BlueShiftInAppNotification+SwiftUI.swift
├── ViewModels/                              # View models
│   └── BlueShiftInAppViewModel.swift
└── Views/                                   # SwiftUI views
    ├── BlueShiftInAppSwiftUIView.swift     # Main router (uses banner)
    └── BlueShiftSlideBannerSwiftUIView.swift  # Universal banner view
```

## Customization

The banner view automatically adapts to:
- Notification payload styling (colors, images, text)
- Device color scheme (light/dark mode)
- Safe area insets
- Screen size
- Position (top/bottom)

## Banner Features

### Visual Elements
- **Icon/Image**: Displays notification icon or banner image
- **Title**: Bold headline text
- **Message**: Secondary description text
- **Close Button**: Tap to dismiss

### Interactions
- **Tap**: Opens deep link or dismisses
- **Swipe**: Drag up (top banner) or down (bottom banner) to dismiss
- **Auto-dismiss**: Automatically dismisses after 5 seconds

### Positioning
Controlled by `template_style.position` in payload:
- `"top"` - Slides in from top
- `"bottom"` - Slides in from bottom
- Default: top

## Migration from UIKit

No code changes required! Simply:
1. Add the SwiftUI subspec to your Podfile
2. Set `config.useSwiftUIForInApp = true`
3. Run `pod install`

To revert to UIKit rendering, set `config.useSwiftUIForInApp = false`.

## Example Payload

```json
{
  "data": {
    "inapp": {
      "type": "modal",
      "content": {
        "title": "Special Offer!",
        "message": "Get 20% off your next purchase",
        "icon": "https://example.com/icon.png",
        "actions": [
          {
            "text": "Shop Now",
            "ios_link": "myapp://shop"
          }
        ]
      },
      "template_style": {
        "position": "top",
        "background_color": "#FFFFFF"
      }
    }
  }
}
```

## Support

For issues or questions, please visit:
- Documentation: https://developer.blueshift.com
- Support: support@blueshift.com
