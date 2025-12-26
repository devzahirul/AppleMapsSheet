//
//  SheetConfiguration.swift
//  AppleMapsSheet
//
//  An Apple Maps-style interactive bottom sheet for SwiftUI and UIKit.
//
//  Copyright (c) 2024. MIT License.
//

import SwiftUI

// MARK: - AppleMapsSheetConfiguration

/// Configuration options for customizing the appearance and behavior of ``AppleMapsSheetView``.
///
/// Use this struct to customize every aspect of the bottom sheet including colors,
/// dimensions, animations, and available snap positions.
///
/// ## Example
/// ```swift
/// let config = AppleMapsSheetConfiguration(
///     snapPositions: [.dismiss, .middle, .top],
///     cornerRadius: 20,
///     backgroundColor: .white,
///     handleColor: .gray,
///     shadowConfiguration: .default
/// )
///
/// AppleMapsSheetView(position: $position, configuration: config) {
///     ContentView()
/// }
/// ```
public struct AppleMapsSheetConfiguration {
    
    // MARK: - Position Configuration
    
    /// The positions the sheet can snap to.
    ///
    /// Configure which positions are available for the sheet. The sheet will only
    /// snap to these positions when dragged. Order doesn't matter - positions are
    /// automatically sorted by height.
    ///
    /// ## Example
    /// ```swift
    /// // Allow dismiss, middle, and top only (no bottom)
    /// config.snapPositions = [.dismiss, .middle, .top]
    ///
    /// // Include custom position
    /// config.snapPositions = [.dismiss, .custom(heightRatio: 0.3), .top]
    /// ```
    public var snapPositions: [SheetPosition]
    
    /// The initial position when the sheet appears.
    ///
    /// This should be one of the positions in ``snapPositions``.
    public var initialPosition: SheetPosition
    
    // MARK: - Appearance
    
    /// The corner radius of the sheet.
    ///
    /// Default: 16 points
    public var cornerRadius: CGFloat
    
    /// The background color of the sheet.
    ///
    /// Default: System background color
    public var backgroundColor: Color
    
    /// Whether to show the drag handle indicator.
    ///
    /// Default: true
    public var showHandle: Bool
    
    /// The color of the drag handle.
    ///
    /// Default: Gray (#D9D9D9)
    public var handleColor: Color
    
    /// The size of the drag handle.
    ///
    /// Default: 36 x 5 points
    public var handleSize: CGSize
    
    /// The vertical padding around the handle.
    ///
    /// Default: 7.5 points top and bottom
    public var handlePadding: CGFloat
    
    // MARK: - Shadow Configuration
    
    /// The shadow configuration for the sheet.
    ///
    /// Set to `nil` to disable the shadow.
    public var shadow: ShadowConfiguration?
    
    // MARK: - Animation Configuration
    
    /// The animation configuration for position transitions.
    public var animation: AnimationConfiguration
    
    // MARK: - Gesture Configuration
    
    /// The drag threshold (as a ratio of screen height) to trigger position change.
    ///
    /// Default: 0.12 (12% of screen height)
    public var dragThreshold: CGFloat
    
    /// The velocity threshold (points per second) for flick gestures.
    ///
    /// Default: 600 pts/sec
    public var velocityThreshold: CGFloat
    
    // MARK: - Scroll Configuration
    
    /// Whether to enable scrolling when at the top position.
    ///
    /// Default: true
    public var enableScrollAtTop: Bool
    
    /// Whether to show the scroll indicator.
    ///
    /// Default: true
    public var showScrollIndicator: Bool
    
    // MARK: - Initializer
    
    /// Creates a new configuration with customizable options.
    ///
    /// - Parameters:
    ///   - snapPositions: The positions the sheet can snap to.
    ///   - initialPosition: The initial position when the sheet appears.
    ///   - cornerRadius: The corner radius of the sheet.
    ///   - backgroundColor: The background color of the sheet.
    ///   - showHandle: Whether to show the drag handle.
    ///   - handleColor: The color of the drag handle.
    ///   - handleSize: The size of the drag handle.
    ///   - handlePadding: The vertical padding around the handle.
    ///   - shadow: The shadow configuration.
    ///   - animation: The animation configuration.
    ///   - dragThreshold: The drag threshold to trigger position change.
    ///   - velocityThreshold: The velocity threshold for flick gestures.
    ///   - enableScrollAtTop: Whether to enable scrolling at top position.
    ///   - showScrollIndicator: Whether to show the scroll indicator.
    public init(
        snapPositions: [SheetPosition] = [.bottom, .middle, .top],
        initialPosition: SheetPosition = .middle,
        cornerRadius: CGFloat = 16,
        backgroundColor: Color = Color(UIColor.systemBackground),
        showHandle: Bool = true,
        handleColor: Color = Color(red: 217/255, green: 217/255, blue: 217/255),
        handleSize: CGSize = CGSize(width: 36, height: 5),
        handlePadding: CGFloat = 7.5,
        shadow: ShadowConfiguration? = .default,
        animation: AnimationConfiguration = .default,
        dragThreshold: CGFloat = 0.12,
        velocityThreshold: CGFloat = 600,
        enableScrollAtTop: Bool = true,
        showScrollIndicator: Bool = true
    ) {
        self.snapPositions = snapPositions
        self.initialPosition = initialPosition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.showHandle = showHandle
        self.handleColor = handleColor
        self.handleSize = handleSize
        self.handlePadding = handlePadding
        self.shadow = shadow
        self.animation = animation
        self.dragThreshold = dragThreshold
        self.velocityThreshold = velocityThreshold
        self.enableScrollAtTop = enableScrollAtTop
        self.showScrollIndicator = showScrollIndicator
    }
    
    /// The default configuration.
    public static var `default`: AppleMapsSheetConfiguration {
        AppleMapsSheetConfiguration()
    }
}

// MARK: - ShadowConfiguration

/// Configuration for the sheet's shadow appearance.
public struct ShadowConfiguration {
    
    /// The shadow color.
    public var color: Color
    
    /// The shadow blur radius.
    public var radius: CGFloat
    
    /// The shadow x offset.
    public var x: CGFloat
    
    /// The shadow y offset.
    public var y: CGFloat
    
    /// Creates a new shadow configuration.
    ///
    /// - Parameters:
    ///   - color: The shadow color.
    ///   - radius: The blur radius.
    ///   - x: The horizontal offset.
    ///   - y: The vertical offset.
    public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
    
    /// The default shadow configuration.
    ///
    /// A subtle shadow with 0.08 opacity black, 24pt blur, offset -4pt upward.
    public static var `default`: ShadowConfiguration {
        ShadowConfiguration(
            color: Color.black.opacity(0.08),
            radius: 24,
            x: 0,
            y: -4
        )
    }
    
    /// No shadow.
    public static var none: ShadowConfiguration? {
        nil
    }
}

// MARK: - AnimationConfiguration

/// Configuration for the sheet's animation behavior.
///
/// Choose from preset animations or create custom spring/easeInOut animations.
///
/// ## Presets
/// - ``default``: Snappy spring animation (Apple Maps style)
/// - ``smooth``: Smooth, fluid animation with higher damping
/// - ``smoothSlow``: Extra smooth with longer duration
/// - ``bouncy``: Playful bouncy animation
/// - ``snappy``: Quick, responsive animation
/// - ``easeInOut``: Classic easing curve (non-spring)
///
/// ## Example
/// ```swift
/// // Use smooth animation
/// let config = AppleMapsSheetConfiguration(animation: .smooth)
///
/// // Custom spring
/// let custom = AnimationConfiguration.spring(stiffness: 250, damping: 28)
///
/// // Custom easeInOut
/// let eased = AnimationConfiguration.easeInOut(duration: 0.4)
/// ```
public struct AnimationConfiguration {
    
    /// The animation type.
    public enum AnimationType {
        /// Spring-based animation with stiffness and damping.
        case spring(stiffness: Double, damping: Double)
        
        /// Ease in-out animation with duration.
        case easeInOut(duration: Double)
        
        /// Linear animation with duration.
        case linear(duration: Double)
        
        /// Ease in animation with duration.
        case easeIn(duration: Double)
        
        /// Ease out animation with duration.
        case easeOut(duration: Double)
    }
    
    /// The animation type.
    public var type: AnimationType
    
    /// Creates a new animation configuration with a specific type.
    ///
    /// - Parameter type: The animation type to use.
    public init(type: AnimationType) {
        self.type = type
    }
    
    /// Creates a spring animation configuration.
    ///
    /// - Parameters:
    ///   - stiffness: The spring stiffness (higher = snappier).
    ///   - damping: The spring damping (higher = less bouncy).
    public init(stiffness: Double, damping: Double) {
        self.type = .spring(stiffness: stiffness, damping: damping)
    }
    
    // MARK: - Factory Methods
    
    /// Creates a spring animation configuration.
    ///
    /// - Parameters:
    ///   - stiffness: The spring stiffness (higher = snappier). Default: 300
    ///   - damping: The spring damping (higher = less bouncy). Default: 30
    /// - Returns: A spring animation configuration.
    public static func spring(stiffness: Double = 300, damping: Double = 30) -> AnimationConfiguration {
        AnimationConfiguration(type: .spring(stiffness: stiffness, damping: damping))
    }
    
    /// Creates an ease in-out animation configuration.
    ///
    /// - Parameter duration: The animation duration in seconds. Default: 0.35
    /// - Returns: An ease in-out animation configuration.
    public static func easeInOut(duration: Double = 0.35) -> AnimationConfiguration {
        AnimationConfiguration(type: .easeInOut(duration: duration))
    }
    
    /// Creates a linear animation configuration.
    ///
    /// - Parameter duration: The animation duration in seconds.
    /// - Returns: A linear animation configuration.
    public static func linear(duration: Double) -> AnimationConfiguration {
        AnimationConfiguration(type: .linear(duration: duration))
    }
    
    /// Creates an ease in animation configuration.
    ///
    /// - Parameter duration: The animation duration in seconds.
    /// - Returns: An ease in animation configuration.
    public static func easeIn(duration: Double) -> AnimationConfiguration {
        AnimationConfiguration(type: .easeIn(duration: duration))
    }
    
    /// Creates an ease out animation configuration.
    ///
    /// - Parameter duration: The animation duration in seconds.
    /// - Returns: An ease out animation configuration.
    public static func easeOut(duration: Double) -> AnimationConfiguration {
        AnimationConfiguration(type: .easeOut(duration: duration))
    }
    
    // MARK: - Presets
    
    /// The default animation: snappy spring (Apple Maps style).
    ///
    /// Stiffness: 300, Damping: 30
    public static var `default`: AnimationConfiguration {
        .spring(stiffness: 300, damping: 30)
    }
    
    /// A bouncy animation with visible overshoot.
    ///
    /// Stiffness: 300, Damping: 20
    public static var bouncy: AnimationConfiguration {
        .spring(stiffness: 300, damping: 20)
    }
    
    /// A smooth, fluid animation with minimal overshoot.
    ///
    /// Stiffness: 200, Damping: 35
    /// Best for a polished, premium feel.
    public static var smooth: AnimationConfiguration {
        .spring(stiffness: 200, damping: 35)
    }
    
    /// Extra smooth animation with longer settling time.
    ///
    /// Stiffness: 150, Damping: 25
    /// Best for slow, elegant transitions.
    public static var smoothSlow: AnimationConfiguration {
        .spring(stiffness: 150, damping: 25)
    }
    
    /// A snappy, quick-responding animation.
    ///
    /// Stiffness: 400, Damping: 35
    /// Best for responsive, immediate feel.
    public static var snappy: AnimationConfiguration {
        .spring(stiffness: 400, damping: 35)
    }
    
    /// Classic ease in-out animation (non-spring).
    ///
    /// Duration: 0.35 seconds
    public static var eased: AnimationConfiguration {
        .easeInOut(duration: 0.35)
    }
    
    /// Slow ease in-out animation.
    ///
    /// Duration: 0.5 seconds
    public static var easedSlow: AnimationConfiguration {
        .easeInOut(duration: 0.5)
    }
    
    // MARK: - SwiftUI Animation
    
    /// The SwiftUI animation representation.
    public var swiftUIAnimation: Animation {
        switch type {
        case .spring(let stiffness, let damping):
            return .interpolatingSpring(stiffness: stiffness, damping: damping)
        case .easeInOut(let duration):
            return .easeInOut(duration: duration)
        case .linear(let duration):
            return .linear(duration: duration)
        case .easeIn(let duration):
            return .easeIn(duration: duration)
        case .easeOut(let duration):
            return .easeOut(duration: duration)
        }
    }
    
    /// UIKit animation duration (for spring animations, this is approximate).
    public var uiKitDuration: TimeInterval {
        switch type {
        case .spring:
            return 0.35  // Approximate
        case .easeInOut(let duration), .linear(let duration), .easeIn(let duration), .easeOut(let duration):
            return duration
        }
    }
    
    /// UIKit damping ratio (for spring animations).
    public var uiKitDampingRatio: CGFloat {
        switch type {
        case .spring(_, let damping):
            return CGFloat(min(1.0, damping / 30.0))
        default:
            return 1.0
        }
    }
}

