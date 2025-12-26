//
//  SwiftUIAppleMapBottomSheetView.swift
//  AppleMapsSheet
//
//  A simplified Apple Maps-style bottom sheet for SwiftUI.
//  Users only need to pass content - position and configuration are handled automatically.
//
//  Copyright (c) 2024. MIT License.
//

import SwiftUI

// MARK: - SwiftUIAppleMapBottomSheetView

/// A simplified Apple Maps-style interactive bottom sheet.
///
/// This is a convenience wrapper around `AppleMapsSheetView` that provides
/// sensible defaults and a simpler API. Users only need to pass their content.
///
/// ## Basic Usage
/// ```swift
/// ZStack {
///     MapView()
///     
///     SwiftUIAppleMapBottomSheetView {
///         VStack {
///             Text("My Content")
///             ForEach(items) { item in
///                 ItemRow(item: item)
///             }
///         }
///     }
/// }
/// ```
///
/// ## With Position Binding
/// ```swift
/// @State private var position: SheetPosition = .middle
///
/// SwiftUIAppleMapBottomSheetView(position: $position) {
///     ContentView()
/// }
/// ```
///
/// ## With Custom Positions
/// ```swift
/// SwiftUIAppleMapBottomSheetView(
///     positions: [.bottom, .middle, .top],
///     startPosition: .middle
/// ) {
///     ContentView()
/// }
/// ```
public struct SwiftUIAppleMapBottomSheetView<Content: View>: View {
    
    // MARK: - Properties
    
    /// The current position of the sheet (can be externally controlled).
    @Binding private var position: SheetPosition
    
    /// Available snap positions.
    private let snapPositions: [SheetPosition]
    
    /// The content to display inside the sheet.
    private let content: () -> Content
    
    // MARK: - Initialization
    
    /// Creates a simple bottom sheet with default settings.
    ///
    /// - Parameters:
    ///   - content: The content to display inside the sheet.
    public init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._position = .constant(.middle)
        self.snapPositions = [.bottom, .custom(heightRatio: 0.5), .top]
        self.content = content
    }
    
    /// Creates a simple bottom sheet with position binding.
    ///
    /// - Parameters:
    ///   - position: A binding to the sheet's position.
    ///   - content: The content to display inside the sheet.
    public init(
        position: Binding<SheetPosition>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._position = position
        self.snapPositions = [.bottom, .custom(heightRatio: 0.5), .top]
        self.content = content
    }
    
    /// Creates a simple bottom sheet with custom snap positions.
    ///
    /// - Parameters:
    ///   - position: A binding to the sheet's position.
    ///   - positions: The available snap positions.
    ///   - content: The content to display inside the sheet.
    public init(
        position: Binding<SheetPosition>,
        positions: [SheetPosition],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._position = position
        self.snapPositions = positions
        self.content = content
    }
    
    // MARK: - Body
    
    public var body: some View {
        AppleMapsSheetView(
            position: $position,
            configuration: AppleMapsSheetConfiguration(
                snapPositions: snapPositions,
                animation: .smooth
            )
        ) {
            content()
        }
    }
}

// MARK: - Convenience Modifiers

extension SwiftUIAppleMapBottomSheetView {
    
    /// Sets the corner radius of the sheet.
    public func cornerRadius(_ radius: CGFloat) -> some View {
        AppleMapsSheetView(
            position: $position,
            configuration: AppleMapsSheetConfiguration(
                snapPositions: snapPositions,
                cornerRadius: radius,
                animation: .smooth
            )
        ) {
            content()
        }
    }
    
    /// Sets the background color of the sheet.
    public func sheetBackground(_ color: Color) -> some View {
        AppleMapsSheetView(
            position: $position,
            configuration: AppleMapsSheetConfiguration(
                snapPositions: snapPositions,
                backgroundColor: color,
                animation: .smooth
            )
        ) {
            content()
        }
    }
}

// MARK: - Preview

#Preview("SwiftUI Apple Map Bottom Sheet") {
    ZStack {
        Color.green.opacity(0.2).ignoresSafeArea()
        
        SwiftUIAppleMapBottomSheetView {
            VStack(spacing: 16) {
                ForEach(0..<20) { index in
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            Text("Item \(index + 1)")
                                .font(.headline)
                            Text("Description text here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
            .padding(.top, 8)
        }
    }
}

#Preview("With Position Binding") {
    struct PreviewWrapper: View {
        @State private var position: SheetPosition = .middle
        
        var body: some View {
            ZStack {
                Color.blue.opacity(0.1).ignoresSafeArea()
                
                VStack {
                    Text("Position: \(position.heightRatio, specifier: "%.2f")")
                    
                    HStack {
                        Button("Bottom") { position = .bottom }
                        Button("Middle") { position = .middle }
                        Button("Top") { position = .top }
                    }
                    //.buttonStyle(.bordered)
                }
                
                SwiftUIAppleMapBottomSheetView(position: $position) {
                    VStack(spacing: 12) {
                        Text("Sheet Content")
                            .font(.headline)
                        Text("This sheet's position is controlled externally")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
        }
    }
    
    return PreviewWrapper()
}

