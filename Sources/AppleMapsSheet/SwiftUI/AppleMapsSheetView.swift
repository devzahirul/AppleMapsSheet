//
//  AppleMapsSheetView.swift
//  AppleMapsSheet
//
//  An Apple Maps-style interactive bottom sheet for SwiftUI and UIKit.
//
//  Copyright (c) 2024. MIT License.
//

import SwiftUI

// MARK: - AppleMapsSheetView

/// An Apple Maps-style interactive bottom sheet with smooth scroll/drag coordination.
///
/// `AppleMapsSheetView` provides a draggable bottom sheet that behaves like the sheet
/// in Apple Maps. It supports multiple snap positions, smooth gesture coordination
/// between sheet dragging and content scrolling, and full customization.
///
/// ## Key Features
/// - **Apple Maps-style behavior**: Seamless scroll/drag coordination
/// - **Configurable snap positions**: Dismiss, bottom, middle, top, or custom
/// - **Full customization**: Colors, corner radius, handle, shadow, animation
/// - **Programmatic control**: Set position via binding to show/hide/move sheet
///
/// ## Behavior
/// - **When sheet is NOT at top**: Dragging anywhere moves the sheet (scroll locked)
/// - **When sheet IS at top**: Scroll is enabled. Pulling down past content top drags sheet down.
///
/// ## Example
/// ```swift
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
/// ## Custom Configuration
/// ```swift
/// AppleMapsSheetView(
///     position: $sheetPosition,
///     configuration: AppleMapsSheetConfiguration(
///         snapPositions: [.dismiss, .middle, .top],
///         cornerRadius: 20,
///         backgroundColor: .white
///     )
/// ) {
///     ContentView()
/// }
/// ```
///
/// ## Topics
///
/// ### Creating a Sheet
/// - ``init(position:configuration:content:)``
///
/// ### Configuration
/// - ``AppleMapsSheetConfiguration``
/// - ``SheetPosition``
public struct AppleMapsSheetView<Content: View>: View {
    
    // MARK: - Properties
    
    /// The current position of the sheet.
    @Binding public var position: SheetPosition
    
    /// The configuration for customizing the sheet's appearance and behavior.
    public let configuration: AppleMapsSheetConfiguration
    
    /// The content to display inside the sheet.
    @ViewBuilder public let content: () -> Content
    
    // MARK: - Private State
    
    @State private var dragOffset: CGFloat = 0
    
    // MARK: - Initializer
    
    /// Creates a new interactive bottom sheet.
    ///
    /// - Parameters:
    ///   - position: A binding to the current sheet position.
    ///   - configuration: The configuration for customizing the sheet. Defaults to ``AppleMapsSheetConfiguration/default``.
    ///   - content: A view builder that creates the content to display inside the sheet.
    ///
    /// ## Example
    /// ```swift
    /// @State private var position: SheetPosition = .middle
    ///
    /// AppleMapsSheetView(position: $position) {
    ///     VStack {
    ///         Text("Sheet Content")
    ///         List(items) { item in
    ///             ItemRow(item: item)
    ///         }
    ///     }
    /// }
    /// ```
    public init(
        position: Binding<SheetPosition>,
        configuration: AppleMapsSheetConfiguration = .default,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._position = position
        self.configuration = configuration
        self.content = content
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let sheetHeight = screenHeight * position.heightRatio
            let baseOffset = screenHeight - sheetHeight
            let currentOffset = baseOffset + dragOffset
            
            // Only render if visible
            if position.isVisible || dragOffset != 0 {
                ZStack(alignment: .top) {
                    // Sheet background
                    sheetBackground
                    
                    VStack(spacing: 0) {
                        // Drag handle
                        if configuration.showHandle {
                            dragHandle
                        }
                        
                        // Content with Apple Maps scroll behavior
                        AppleMapsScrollViewRepresentable(
                            position: $position,
                            dragOffset: $dragOffset,
                            configuration: configuration,
                            screenHeight: screenHeight,
                            content: content()
                        )
                    }
                }
                .frame(width: geometry.size.width, height: screenHeight * 0.95)
                .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
                .offset(y: max(0, currentOffset))
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Subviews
    
    private var sheetBackground: some View {
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
            .fill(configuration.backgroundColor)
            .shadow(
                color: configuration.shadow?.color ?? .clear,
                radius: configuration.shadow?.radius ?? 0,
                x: configuration.shadow?.x ?? 0,
                y: configuration.shadow?.y ?? 0
            )
    }
    
    private var dragHandle: some View {
        Capsule()
            .fill(configuration.handleColor)
            .frame(
                width: configuration.handleSize.width,
                height: configuration.handleSize.height
            )
            .padding(.vertical, configuration.handlePadding)
    }
}

// MARK: - AppleMapsScrollViewRepresentable

struct AppleMapsScrollViewRepresentable<Content: View>: UIViewControllerRepresentable {
    
    @Binding var position: SheetPosition
    @Binding var dragOffset: CGFloat
    let configuration: AppleMapsSheetConfiguration
    let screenHeight: CGFloat
    let content: Content
    
    func makeUIViewController(context: Context) -> AppleMapsScrollViewController<Content> {
        let controller = AppleMapsScrollViewController(
            rootView: content,
            configuration: configuration,
            screenHeight: screenHeight
        )
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ controller: AppleMapsScrollViewController<Content>, context: Context) {
        controller.updateContent(content)
        
        let shouldEnableScroll = position.isScrollEnabled && configuration.enableScrollAtTop
        controller.updateScrollEnabled(shouldEnableScroll)
        
        // Update coordinator state without triggering SwiftUI updates
        context.coordinator.currentPosition = position
        context.coordinator.currentScreenHeight = screenHeight
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            position: $position,
            dragOffset: $dragOffset,
            configuration: configuration,
            screenHeight: screenHeight
        )
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, AppleMapsScrollDelegate {
        @Binding var position: SheetPosition
        @Binding var dragOffset: CGFloat
        let configuration: AppleMapsSheetConfiguration
        
        var currentPosition: SheetPosition
        var currentScreenHeight: CGFloat
        
        init(
            position: Binding<SheetPosition>,
            dragOffset: Binding<CGFloat>,
            configuration: AppleMapsSheetConfiguration,
            screenHeight: CGFloat
        ) {
            self._position = position
            self._dragOffset = dragOffset
            self.configuration = configuration
            self.currentPosition = position.wrappedValue
            self.currentScreenHeight = screenHeight
            super.init()
        }
        
        func handleDrag(_ translation: CGFloat) {
            DispatchQueue.main.async { [weak self] in
                self?.dragOffset = translation
            }
        }
        
        func handleDragEnd(_ translation: CGFloat, velocity: CGFloat) {
            let dragRatio = translation / currentScreenHeight
            var newPosition = currentPosition
            let snapPositions = configuration.snapPositions
            
            if translation < 0 {
                // Dragging up
                if -dragRatio >= configuration.dragThreshold || velocity < -configuration.velocityThreshold {
                    if -dragRatio >= configuration.dragThreshold * 2.5 || velocity < -configuration.velocityThreshold * 1.5 {
                        newPosition = SheetPosition.highest(in: snapPositions)
                    } else {
                        newPosition = currentPosition.nextUp(in: snapPositions)
                    }
                }
            } else {
                // Dragging down
                if dragRatio >= configuration.dragThreshold || velocity > configuration.velocityThreshold {
                    if dragRatio >= configuration.dragThreshold * 2.5 || velocity > configuration.velocityThreshold * 1.5 {
                        // Flick to lowest (could be dismiss)
                        let sorted = snapPositions.sorted { $0.heightRatio < $1.heightRatio }
                        newPosition = sorted.first ?? .dismiss
                    } else {
                        newPosition = currentPosition.nextDown(in: snapPositions)
                    }
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                withAnimation(self.configuration.animation.swiftUIAnimation) {
                    self.position = newPosition
                    self.dragOffset = 0
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.green.opacity(0.2).ignoresSafeArea()
        
        AppleMapsSheetView(
            position: .constant(.middle),
            configuration: AppleMapsSheetConfiguration(
                snapPositions: [.dismiss, .middle, .top]
            )
        ) {
            VStack(spacing: 16) {
                ForEach(0..<30, id: \.self) { index in
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
