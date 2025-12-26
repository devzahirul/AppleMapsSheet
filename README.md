# AppleMapsSheet

An Apple Maps-style interactive bottom sheet for SwiftUI and UIKit.

[![Swift 5.7+](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![iOS 14+](https://img.shields.io/badge/iOS-14+-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📹 Demo

[![Watch Demo](https://img.shields.io/badge/YouTube-Demo-red?logo=youtube)](https://www.youtube.com/shorts/uQqQKW-RBKI)

[▶️ Watch the demo video on YouTube](https://www.youtube.com/shorts/uQqQKW-RBKI)

## Features

- 🎯 **Apple Maps-style behavior** - Seamless scroll/drag coordination
- 📍 **Configurable snap positions** - Dismiss, bottom, middle, top, or custom heights
- 🔄 **SwiftUI native** - First-class SwiftUI support with `SwiftUIAppleMapBottomSheetView`
- 🛠 **UIKit bridge** - Easy UIKit integration
- ⚡ **Smooth animations** - Spring animations with velocity preservation
- 🎨 **Fully customizable** - Colors, corner radius, handle appearance, shadows
- 📖 **Well documented** - DocC-compatible documentation

## Behavior

| Position | Scroll | Drag Behavior |
|----------|--------|---------------|
| Bottom/Middle | Disabled | Dragging anywhere moves the sheet |
| Top | Enabled | Pull down past content top → sheet moves |

## Installation

### Swift Package Manager

Add this package to your Xcode project:

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/devzahirul/AppleMapsSheet.git
   ```
3. Select the version and click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/devzahirul/AppleMapsSheet.git", from: "1.0.0")
]
```

## Quick Start

### SwiftUI - Simple (Just Pass Content)

```swift
import AppleMapsSheet

struct ContentView: View {
    var body: some View {
        ZStack {
            MapView()
            
            // Simplest usage - just pass content
            SwiftUIAppleMapBottomSheetView {
                VStack {
                    Text("My Content")
                    ForEach(items) { item in
                        ItemRow(item: item)
                    }
                }
            }
        }
    }
}
```

### SwiftUI - With Position Binding

```swift
import AppleMapsSheet

struct ContentView: View {
    @State private var sheetPosition: SheetPosition = .middle
    
    var body: some View {
        ZStack {
            MapView()
            
            // Control position externally
            SwiftUIAppleMapBottomSheetView(position: $sheetPosition) {
                SearchResultsList()
            }
            
            // Buttons to control position
            VStack {
                Button("Expand") { sheetPosition = .top }
                Button("Middle") { sheetPosition = .middle }
                Button("Collapse") { sheetPosition = .bottom }
            }
        }
    }
}
```

### SwiftUI - With Custom Positions

```swift
import AppleMapsSheet

struct ContentView: View {
    @State private var sheetPosition: SheetPosition = .custom(heightRatio: 0.3)
    
    // Custom snap positions: 20%, 50%, 80%
    let customPositions: [SheetPosition] = [
        .custom(heightRatio: 0.2),
        .custom(heightRatio: 0.5),
        .custom(heightRatio: 0.8)
    ]
    
    var body: some View {
        ZStack {
            MapView()
            
            SwiftUIAppleMapBottomSheetView(
                position: $sheetPosition,
                positions: customPositions
            ) {
                ContentView()
            }
        }
    }
}
```

### SwiftUI - Full Configuration

```swift
import AppleMapsSheet

struct ContentView: View {
    @State private var position: SheetPosition = .middle
    
    var body: some View {
        ZStack {
            MapView()
            
            AppleMapsSheetView(
                position: $position,
                configuration: AppleMapsSheetConfiguration(
                    snapPositions: [.dismiss, .middle, .top],
                    cornerRadius: 20,
                    backgroundColor: .white,
                    animation: .smooth
                )
            ) {
                SearchResultsList()
            }
        }
    }
}
```

### UIKit

```swift
import AppleMapsSheet

class MapViewController: UIViewController {
    private let sheetController = AppleMapsSheetViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sheetController.delegate = self
        
        addChild(sheetController)
        view.addSubview(sheetController.view)
        sheetController.didMove(toParent: self)
        
        // Layout
        sheetController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetController.view.topAnchor.constraint(equalTo: view.topAnchor),
            sheetController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set content
        sheetController.setContentViewController(SearchResultsViewController())
        sheetController.setPosition(.middle, animated: true)
    }
}

extension MapViewController: AppleMapsSheetViewControllerDelegate {
    func sheetDidChangePosition(_ position: SheetPosition) {
        print("Sheet moved to: \(position)")
    }
}
```

## API Reference

### SwiftUIAppleMapBottomSheetView

The simplified SwiftUI wrapper with sensible defaults.

| Init | Description |
|------|-------------|
| `init(content:)` | Just pass content, uses default positions |
| `init(position:content:)` | With position binding |
| `init(position:positions:content:)` | With custom snap positions |

### SheetPosition

| Position | Height Ratio | Scroll Enabled |
|----------|-------------|----------------|
| `.dismiss` | 0% (hidden) | No |
| `.bottom` | 12.5% | No |
| `.middle` | 40% | No |
| `.top` | 85% | Yes |
| `.custom(heightRatio:)` | Custom | ≥70%: Yes |

### AppleMapsSheetConfiguration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `snapPositions` | `[SheetPosition]` | `[.bottom, .middle, .top]` | Available snap positions |
| `cornerRadius` | `CGFloat` | `16` | Corner radius |
| `backgroundColor` | `Color` | System background | Background color |
| `showHandle` | `Bool` | `true` | Show drag handle |
| `animation` | `AnimationConfiguration` | Spring (300, 30) | Animation config |

### AnimationConfiguration Presets

| Preset | Description |
|--------|-------------|
| `.default` | Apple Maps style |
| `.smooth` | Fluid with minimal overshoot |
| `.snappy` | Quick, responsive |
| `.bouncy` | Playful with overshoot |

## Examples

The package includes complete example projects:

### 📱 SwiftUI Example

Location: `Examples/SwiftUIExample/`

**Demo List View** with 4 examples:
1. **Simple Sheet** - Just pass content, no configuration
2. **Position Binding** - Control position externally with buttons
3. **Custom Positions** - Define 20%, 50%, 80% snap points
4. **Full Map Explorer** - Complete MapKit search app

Features:
- MapKit MKLocalSearch integration for real places
- Category filters (Restaurants, Cafes, Gas Stations, etc.)
- Tap map to search at location
- Place annotations and detail navigation

### 📱 UIKit Example

Location: `Examples/UIKitExample/`

Same functionality built with UIKit and delegate pattern.

### Running Examples

```bash
# Clone the repository
git clone https://github.com/devzahirul/AppleMapsSheet.git

# Open in Xcode
cd AppleMapsSheet
open Package.swift

# Generate Xcode project for examples (requires XcodeGen)
cd Examples/SwiftUIExample
xcodegen generate
open SwiftUIExample.xcodeproj
```

## Requirements

- iOS 14.0+
- Swift 5.7+
- Xcode 14.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

Inspired by the bottom sheet behavior in Apple Maps.
