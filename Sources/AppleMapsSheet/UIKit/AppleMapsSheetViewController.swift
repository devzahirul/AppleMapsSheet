//
//  AppleMapsSheetViewController.swift
//  AppleMapsSheet
//
//  UIKit view controller for presenting Apple Maps-style bottom sheets.
//
//  Copyright (c) 2024. MIT License.
//

import UIKit
import SwiftUI

// MARK: - AppleMapsSheetViewControllerDelegate

/// Delegate protocol for receiving sheet position change notifications.
///
/// Implement this protocol to respond to sheet position changes in UIKit.
///
/// ## Example
/// ```swift
/// extension MapViewController: AppleMapsSheetViewControllerDelegate {
///     func sheetDidChangePosition(_ position: SheetPosition) {
///         print("Sheet moved to: \(position)")
///         if position == .dismiss {
///             // Handle sheet dismissal
///         }
///     }
/// }
/// ```
public protocol AppleMapsSheetViewControllerDelegate: AnyObject {
    
    /// Called when the sheet changes position.
    ///
    /// - Parameter position: The new position of the sheet.
    func sheetDidChangePosition(_ position: SheetPosition)
}

// MARK: - AppleMapsSheetViewController

/// A UIKit view controller that presents an Apple Maps-style interactive bottom sheet.
///
/// Use `AppleMapsSheetViewController` to add a draggable bottom sheet to your UIKit app.
/// It provides the same smooth scroll/drag coordination as ``AppleMapsSheetView`` but
/// designed for UIKit-first projects.
///
/// ## Features
/// - Apple Maps-style scroll/drag coordination
/// - Configurable snap positions including dismiss
/// - Full customization of appearance
/// - Delegate pattern for position change notifications
///
/// ## Example
/// ```swift
/// class MapViewController: UIViewController {
///     private lazy var sheetController: AppleMapsSheetViewController = {
///         let sheet = AppleMapsSheetViewController()
///         sheet.delegate = self
///         sheet.configuration = AppleMapsSheetConfiguration(
///             snapPositions: [.dismiss, .middle, .top],
///             cornerRadius: 20
///         )
///         return sheet
///     }()
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///
///         // Add the sheet as a child view controller
///         addChild(sheetController)
///         view.addSubview(sheetController.view)
///         sheetController.didMove(toParent: self)
///
///         // Layout the sheet
///         sheetController.view.translatesAutoresizingMaskIntoConstraints = false
///         NSLayoutConstraint.activate([
///             sheetController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
///             sheetController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
///             sheetController.view.topAnchor.constraint(equalTo: view.topAnchor),
///             sheetController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
///         ])
///
///         // Set the content
///         let contentVC = SearchResultsViewController()
///         sheetController.setContentViewController(contentVC)
///
///         // Show the sheet
///         sheetController.setPosition(.middle, animated: true)
///     }
/// }
/// ```
open class AppleMapsSheetViewController: UIViewController {
    
    // MARK: - Public Properties
    
    /// The delegate that receives sheet position change notifications.
    public weak var delegate: AppleMapsSheetViewControllerDelegate?
    
    /// The configuration for customizing the sheet's appearance and behavior.
    ///
    /// Set this before the view loads for best results. Changes after the view
    /// loads may require calling `reloadConfiguration()`.
    public var configuration: AppleMapsSheetConfiguration = .default {
        didSet {
            if isViewLoaded {
                reloadConfiguration()
            }
        }
    }
    
    /// The current position of the sheet.
    ///
    /// Use ``setPosition(_:animated:)`` to change the position with animation.
    public private(set) var position: SheetPosition = .middle
    
    // MARK: - Private Properties
    
    private var hostingController: UIHostingController<SheetWrapperView>?
    private var contentViewController: UIViewController?
    private var contentView: UIView?
    
    @Published private var internalPosition: SheetPosition = .middle
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupSheet()
    }
    
    // MARK: - Public Methods
    
    /// Sets the sheet position.
    ///
    /// - Parameters:
    ///   - position: The target position.
    ///   - animated: Whether to animate the transition.
    ///
    /// ## Example
    /// ```swift
    /// // Show the sheet
    /// sheetController.setPosition(.middle, animated: true)
    ///
    /// // Dismiss the sheet
    /// sheetController.setPosition(.dismiss, animated: true)
    /// ```
    public func setPosition(_ position: SheetPosition, animated: Bool = true) {
        let oldPosition = self.position
        self.position = position
        self.internalPosition = position
        
        if animated && isViewLoaded {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                self.view.layoutIfNeeded()
            }
        }
        
        if oldPosition != position {
            delegate?.sheetDidChangePosition(position)
        }
    }
    
    /// Sets the content view controller to display inside the sheet.
    ///
    /// The content view controller's view will be embedded inside the scrollable
    /// area of the sheet.
    ///
    /// - Parameter viewController: The view controller to embed.
    ///
    /// ## Example
    /// ```swift
    /// let searchResults = SearchResultsViewController()
    /// sheetController.setContentViewController(searchResults)
    /// ```
    public func setContentViewController(_ viewController: UIViewController) {
        // Remove existing content
        contentViewController?.willMove(toParent: nil)
        contentViewController?.view.removeFromSuperview()
        contentViewController?.removeFromParent()
        
        contentViewController = viewController
        
        // Re-setup the sheet with new content
        if isViewLoaded {
            setupSheet()
        }
    }
    
    /// Sets a UIView as the content to display inside the sheet.
    ///
    /// - Parameter view: The view to display.
    public func setContentView(_ view: UIView) {
        contentView = view
        
        if isViewLoaded {
            setupSheet()
        }
    }
    
    /// Reloads the configuration.
    ///
    /// Call this if you change configuration properties after the view has loaded.
    public func reloadConfiguration() {
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
        
        setupSheet()
    }
    
    // MARK: - Private Methods
    
    private func setupSheet() {
        // Create wrapper view that bridges to SwiftUI
        let wrapperView = SheetWrapperView(
            position: Binding(
                get: { self.internalPosition },
                set: { newPosition in
                    let oldPosition = self.position
                    self.position = newPosition
                    self.internalPosition = newPosition
                    if oldPosition != newPosition {
                        self.delegate?.sheetDidChangePosition(newPosition)
                    }
                }
            ),
            configuration: configuration,
            contentViewController: contentViewController,
            contentView: contentView
        )
        
        let hosting = UIHostingController(rootView: wrapperView)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController = hosting
    }
}

// MARK: - SheetWrapperView

/// Internal SwiftUI view that wraps the sheet for UIKit integration.
private struct SheetWrapperView: View {
    @Binding var position: SheetPosition
    let configuration: AppleMapsSheetConfiguration
    let contentViewController: UIViewController?
    let contentView: UIView?
    
    var body: some View {
        AppleMapsSheetView(position: $position, configuration: configuration) {
            if let contentViewController = contentViewController {
                UIViewControllerWrapper(viewController: contentViewController)
            } else if let contentView = contentView {
                UIViewWrapper(view: contentView)
            } else {
                Color.clear
            }
        }
    }
}

// MARK: - UIViewControllerWrapper

/// Internal wrapper to embed a UIViewController in SwiftUI.
private struct UIViewControllerWrapper: UIViewControllerRepresentable {
    let viewController: UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - UIViewWrapper

/// Internal wrapper to embed a UIView in SwiftUI.
private struct UIViewWrapper: UIViewRepresentable {
    let view: UIView
    
    func makeUIView(context: Context) -> UIView {
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}
