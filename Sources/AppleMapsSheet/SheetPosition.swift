//
//  SheetPosition.swift
//  AppleMapsSheet
//
//  An Apple Maps-style interactive bottom sheet for SwiftUI and UIKit.
//
//  Copyright (c) 2024. MIT License.
//

import SwiftUI

// MARK: - SheetPosition

/// Defines the possible positions for the bottom sheet.
///
/// Use these positions to control where the sheet snaps to. You can configure
/// which positions are available using ``AppleMapsSheetConfiguration/snapPositions``.
///
/// ## Topics
///
/// ### Standard Positions
/// - ``dismiss``
/// - ``bottom``
/// - ``middle``
/// - ``top``
///
/// ### Custom Positions
/// - ``custom(heightRatio:)``
///
/// ## Example
/// ```swift
/// // Configure available positions
/// let config = AppleMapsSheetConfiguration(
///     snapPositions: [.dismiss, .middle, .top]
/// )
/// ```
public enum SheetPosition: Equatable, Hashable {
    
    /// Sheet is completely dismissed/hidden (off-screen).
    ///
    /// When the sheet is in this position, it's not visible to the user.
    /// Use this to programmatically show/hide the sheet.
    case dismiss
    
    /// Sheet is collapsed at the bottom, showing minimal content.
    ///
    /// Default height ratio: 12.5% of screen height.
    case bottom
    
    /// Sheet is at a medium height, showing partial content.
    ///
    /// Default height ratio: 40% of screen height.
    case middle
    
    /// Sheet is fully expanded, showing maximum content with scrolling enabled.
    ///
    /// Default height ratio: 85% of screen height.
    /// Scrolling is automatically enabled when the sheet is at this position.
    case top
    
    /// Sheet is at a custom height ratio.
    ///
    /// - Parameter heightRatio: The height as a ratio of screen height (0.0 to 1.0).
    ///
    /// ## Example
    /// ```swift
    /// // Create a sheet at 60% height
    /// let customPosition = SheetPosition.custom(heightRatio: 0.6)
    /// ```
    case custom(heightRatio: CGFloat)
    
    // MARK: - Public Properties
    
    /// The height ratio relative to screen height (0.0 to 1.0).
    ///
    /// Returns the fraction of the screen height that this position occupies.
    public var heightRatio: CGFloat {
        switch self {
        case .dismiss:
            return 0.0
        case .bottom:
            return 0.125
        case .middle:
            return 0.4
        case .top:
            return 0.85
        case .custom(let ratio):
            return max(0, min(1, ratio))
        }
    }
    
    /// Whether scrolling should be enabled at this position.
    ///
    /// By default, scrolling is only enabled when the sheet is at the `.top` position
    /// or at a custom position with height ratio >= 0.7.
    public var isScrollEnabled: Bool {
        switch self {
        case .top:
            return true
        case .custom(let ratio):
            return ratio >= 0.7
        default:
            return false
        }
    }
    
    /// Whether the sheet is visible at this position.
    public var isVisible: Bool {
        return self != .dismiss
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(heightRatio)
    }
}

// MARK: - SheetPosition + Navigation

extension SheetPosition {
    
    /// Returns the next position when dragging up, based on available positions.
    ///
    /// - Parameter positions: The array of available snap positions.
    /// - Returns: The next higher position, or self if already at the highest.
    public func nextUp(in positions: [SheetPosition]) -> SheetPosition {
        let sorted = positions.sorted { $0.heightRatio < $1.heightRatio }
        guard let currentIndex = sorted.firstIndex(where: { $0.heightRatio == self.heightRatio }) else {
            return self
        }
        let nextIndex = currentIndex + 1
        return nextIndex < sorted.count ? sorted[nextIndex] : self
    }
    
    /// Returns the next position when dragging down, based on available positions.
    ///
    /// - Parameter positions: The array of available snap positions.
    /// - Returns: The next lower position, or self if already at the lowest.
    public func nextDown(in positions: [SheetPosition]) -> SheetPosition {
        let sorted = positions.sorted { $0.heightRatio < $1.heightRatio }
        guard let currentIndex = sorted.firstIndex(where: { $0.heightRatio == self.heightRatio }) else {
            return self
        }
        let previousIndex = currentIndex - 1
        return previousIndex >= 0 ? sorted[previousIndex] : self
    }
    
    /// Returns the highest position in the array.
    ///
    /// - Parameter positions: The array of available snap positions.
    /// - Returns: The position with the highest height ratio.
    public static func highest(in positions: [SheetPosition]) -> SheetPosition {
        return positions.max { $0.heightRatio < $1.heightRatio } ?? .top
    }
    
    /// Returns the lowest visible position in the array.
    ///
    /// - Parameter positions: The array of available snap positions.
    /// - Returns: The position with the lowest height ratio that is still visible.
    public static func lowest(in positions: [SheetPosition]) -> SheetPosition {
        let visible = positions.filter { $0.isVisible }
        return visible.min { $0.heightRatio < $1.heightRatio } ?? .bottom
    }
}
