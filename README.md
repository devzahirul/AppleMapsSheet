# AppleMapsSheet

An Apple Maps-style interactive bottom sheet for SwiftUI and UIKit.

[![Swift 5.7+](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![iOS 14+](https://img.shields.io/badge/iOS-14+-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

<p align="center">
  <img src="https://via.placeholder.com/300x600?text=Demo+GIF" alt="Demo" width="300">
</p>

## Features

- 🎯 **Apple Maps-style behavior** - Seamless scroll/drag coordination
- 📍 **Configurable snap positions** - Dismiss, bottom, middle, top, or custom heights
- 🔄 **SwiftUI native** - First-class SwiftUI support
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
   https://github.com/yourusername/AppleMapsSheet.git
   ```
3. Select the version and click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/AppleMapsSheet.git", from: "1.0.0")
]
```

## Quick Start

### SwiftUI

```swift
import AppleMapsSheet

struct ContentView: View {
    @State private var sheetPosition: SheetPosition = .middle
    
    var body: some View {
        ZStack {
            // Your background content (e.g., Map)
            MapView()
            
            // The bottom sheet
            AppleMapsSheetView(position: $sheetPosition) {
                // Your sheet content
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

## Configuration

### Custom Snap Positions

Configure which positions the sheet can snap to:

```swift
let config = AppleMapsSheetConfiguration(
    snapPositions: [.dismiss, .middle, .top]  // No bottom position
)

AppleMapsSheetView(position: $position, configuration: config) {
    Content()
}
```

### Custom Heights

```swift
let config = AppleMapsSheetConfiguration(
    snapPositions: [
        .dismiss,
        .custom(heightRatio: 0.3),  // 30% height
        .custom(heightRatio: 0.6),  // 60% height
        .top
    ]
)
```

### Full Customization

```swift
let config = AppleMapsSheetConfiguration(
    // Positions
    snapPositions: [.dismiss, .middle, .top],
    initialPosition: .middle,
    
    // Appearance
    cornerRadius: 20,
    backgroundColor: .white,
    showHandle: true,
    handleColor: Color(UIColor.systemGray3),
    handleSize: CGSize(width: 40, height: 6),
    handlePadding: 10,
    
    // Shadow
    shadow: ShadowConfiguration(
        color: .black.opacity(0.1),
        radius: 20,
        x: 0,
        y: -5
    ),
    
    // Animation
    animation: .bouncy,  // or .smooth, .default, or custom
    
    // Gesture thresholds
    dragThreshold: 0.15,
    velocityThreshold: 500,
    
    // Scroll
    enableScrollAtTop: true,
    showScrollIndicator: true
)
```

## Programmatic Control

### SwiftUI

```swift
@State private var position: SheetPosition = .dismiss

// Show sheet
Button("Show Sheet") {
    position = .middle
}

// Dismiss sheet
Button("Dismiss") {
    position = .dismiss
}

// Expand to top
Button("Expand") {
    position = .top
}
```

### UIKit

```swift
// Show sheet
sheetController.setPosition(.middle, animated: true)

// Dismiss sheet
sheetController.setPosition(.dismiss, animated: true)

// Expand to top
sheetController.setPosition(.top, animated: true)
```

## API Reference

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
| `initialPosition` | `SheetPosition` | `.middle` | Initial position |
| `cornerRadius` | `CGFloat` | `16` | Corner radius |
| `backgroundColor` | `Color` | System background | Background color |
| `showHandle` | `Bool` | `true` | Show drag handle |
| `handleColor` | `Color` | Gray | Handle color |
| `handleSize` | `CGSize` | `36x5` | Handle dimensions |
| `shadow` | `ShadowConfiguration?` | Default shadow | Shadow settings |
| `animation` | `AnimationConfiguration` | Spring (300, 30) | Animation config |
| `dragThreshold` | `CGFloat` | `0.12` | Drag threshold |
| `velocityThreshold` | `CGFloat` | `600` | Flick threshold |

### AnimationConfiguration Presets

| Preset | Type | Description |
|--------|------|-------------|
| `.default` | Spring | Apple Maps style (stiffness: 300, damping: 30) |
| `.smooth` | Spring | Fluid with minimal overshoot (stiffness: 200, damping: 35) |
| `.smoothSlow` | Spring | Extra smooth, elegant (stiffness: 150, damping: 25) |
| `.snappy` | Spring | Quick, responsive (stiffness: 400, damping: 35) |
| `.bouncy` | Spring | Playful with overshoot (stiffness: 300, damping: 20) |
| `.eased` | EaseInOut | Classic easing (0.35s) |
| `.easedSlow` | EaseInOut | Slow easing (0.5s) |

Custom animations:
```swift
// Custom spring
.spring(stiffness: 250, damping: 28)

// Custom easeInOut
.easeInOut(duration: 0.4)
```

## Examples

The package includes complete example projects demonstrating real-world usage:

### 📱 SwiftUI Example: Map Explorer

Location: `Examples/SwiftUIExample/MapExplorerView.swift`

A complete map exploration app demonstrating:
- Apple Maps integration with `Map` view
- Tap/long-press on map to search nearby places
- Category filters (Restaurants, Gas Stations, Cafes, etc.)
- Search results displayed in `AppleMapsSheetView`
- Navigation to place details
- Smooth `.smooth` animation preset

**Key Features:**
- `@State` position binding for programmatic control
- Category pills with horizontal scroll
- Place annotations on map
- Detail view with actions (Directions, Call, Share)

### 📱 UIKit Example: Map Explorer

Location: `Examples/UIKitExample/MapExplorerViewController.swift`

The same map exploration app built with UIKit:
- `MKMapView` integration
- `AppleMapsSheetViewController` with delegate pattern
- Category collection view with custom cells
- Places table view with custom cells
- Navigation controller for place details

**Key Features:**
- `AppleMapsSheetViewControllerDelegate` for position changes
- `setContentViewController(_:)` for dynamic content
- `setPosition(_:animated:)` for programmatic control
- Custom `MKAnnotationView` for place markers

### Running the Examples

1. Clone the repository
2. Open the package in Xcode
3. Copy the example file to a new iOS project
4. Add the AppleMapsSheet package dependency
5. Run on simulator or device

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
