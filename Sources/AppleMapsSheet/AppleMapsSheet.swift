//
//  AppleMapsSheet.swift
//  AppleMapsSheet
//
//  An Apple Maps-style interactive bottom sheet for SwiftUI and UIKit.
//
//  Copyright (c) 2024. MIT License.
//

/// AppleMapsSheet provides an Apple Maps-style interactive bottom sheet component
/// for both SwiftUI and UIKit applications.
///
/// ## Overview
///
/// This package provides a draggable bottom sheet that behaves like the sheet in Apple Maps,
/// with smooth gesture coordination between sheet dragging and content scrolling.
///
/// ## Key Features
///
/// - **Apple Maps-style behavior**: Seamless scroll/drag coordination
/// - **Configurable snap positions**: Dismiss, bottom, middle, top, or custom heights
/// - **Full customization**: Colors, corner radius, handle, shadow, animation
/// - **Programmatic control**: Set position via binding to show/hide/move sheet
/// - **SwiftUI native**: First-class SwiftUI support with ``AppleMapsSheetView``
/// - **UIKit support**: Easy UIKit integration with ``AppleMapsSheetViewController``
///
/// ## SwiftUI Usage
///
/// ```swift
/// import AppleMapsSheet
///
/// struct ContentView: View {
///     @State private var sheetPosition: SheetPosition = .middle
///
///     var body: some View {
///         ZStack {
///             MapView()
///
///             AppleMapsSheetView(position: $sheetPosition) {
///                 SearchResultsList()
///             }
///         }
///     }
/// }
/// ```
///
/// ## UIKit Usage
///
/// ```swift
/// import AppleMapsSheet
///
/// class MapViewController: UIViewController {
///     private let sheetController = AppleMapsSheetViewController()
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///
///         sheetController.delegate = self
///         addChild(sheetController)
///         view.addSubview(sheetController.view)
///         sheetController.didMove(toParent: self)
///
///         sheetController.setContentViewController(SearchResultsViewController())
///         sheetController.setPosition(.middle, animated: true)
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### SwiftUI Components
/// - ``AppleMapsSheetView``
///
/// ### UIKit Components
/// - ``AppleMapsSheetViewController``
/// - ``AppleMapsSheetViewControllerDelegate``
///
/// ### Configuration
/// - ``AppleMapsSheetConfiguration``
/// - ``SheetPosition``
/// - ``ShadowConfiguration``
/// - ``AnimationConfiguration``

// Re-export all public types
@_exported import struct SwiftUI.Color
@_exported import struct CoreGraphics.CGFloat
@_exported import struct CoreGraphics.CGSize
