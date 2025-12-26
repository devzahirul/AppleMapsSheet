//
//  AppleMapsScrollViewController.swift
//  AppleMapsSheet
//
//  Internal scroll view controller handling gesture coordination.
//
//  Copyright (c) 2024. MIT License.
//

import SwiftUI
import UIKit

// MARK: - Protocol

/// Internal protocol for communicating scroll/drag events to the coordinator.
protocol AppleMapsScrollDelegate: AnyObject {
    var currentPosition: SheetPosition { get }
    func handleDrag(_ translation: CGFloat)
    func handleDragEnd(_ translation: CGFloat, velocity: CGFloat)
}

// MARK: - AppleMapsScrollViewController

/// Internal view controller that manages the scroll view and gesture coordination.
///
/// This controller implements the Apple Maps-style behavior where:
/// - When NOT at top position: all drags move the sheet (scroll locked)
/// - When at top position: scroll is enabled, but pulling down past top drags the sheet
class AppleMapsScrollViewController<Content: View>: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    weak var delegate: AppleMapsScrollDelegate?
    
    private let scrollView: UIScrollView
    private let hostingController: UIHostingController<Content>
    private var panGesture: UIPanGestureRecognizer!
    private let configuration: AppleMapsSheetConfiguration
    private let screenHeight: CGFloat
    
    // State tracking
    private var isDraggingSheet = false
    private var isScrollEnabled = false
    private var initialScrollOffset: CGFloat = 0
    private var accumulatedTranslation: CGFloat = 0
    
    // MARK: - Initialization
    
    init(rootView: Content, configuration: AppleMapsSheetConfiguration, screenHeight: CGFloat) {
        self.configuration = configuration
        self.screenHeight = screenHeight
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = configuration.showScrollIndicator
        scrollView.alwaysBounceVertical = false
        scrollView.bounces = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        view.addSubview(scrollView)
        
        // ScrollView constraints
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add hosting controller
        addChild(hostingController)
        scrollView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Content constraints
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        scrollView.delegate = self
        
        // Add custom pan gesture for sheet dragging
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }
    
    // MARK: - Public Methods
    
    func updateContent(_ content: Content) {
        hostingController.rootView = content
    }
    
    func updateScrollEnabled(_ enabled: Bool) {
        isScrollEnabled = enabled
        scrollView.isScrollEnabled = enabled
    }
    
    // MARK: - Pan Gesture Handler
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            initialScrollOffset = scrollView.contentOffset.y
            accumulatedTranslation = 0
            isDraggingSheet = false
            
        case .changed:
            handlePanChanged(translation: translation.y, velocity: velocity.y)
            
        case .ended, .cancelled:
            handlePanEnded(velocity: velocity.y)
            
        default:
            break
        }
    }
    
    private func handlePanChanged(translation: CGFloat, velocity: CGFloat) {
        guard let delegate = delegate else { return }
        let position = delegate.currentPosition
        
        if !position.isScrollEnabled || !configuration.enableScrollAtTop {
            // Sheet NOT at top or scroll disabled: all drags move the sheet
            isDraggingSheet = true
            accumulatedTranslation = translation
            delegate.handleDrag(translation)
        } else {
            // Sheet IS at top: need to coordinate with scroll
            let currentScrollOffset = scrollView.contentOffset.y
            
            if translation > 0 && currentScrollOffset <= 0 {
                // Dragging DOWN and scroll is at top -> drag sheet
                if !isDraggingSheet {
                    isDraggingSheet = true
                }
                accumulatedTranslation = translation
                delegate.handleDrag(accumulatedTranslation)
                
                // Prevent scroll from moving
                scrollView.contentOffset.y = 0
            } else if isDraggingSheet && translation > 0 {
                // Continue dragging sheet
                accumulatedTranslation = translation
                delegate.handleDrag(accumulatedTranslation)
                scrollView.contentOffset.y = 0
            } else {
                // Let scroll handle it
                isDraggingSheet = false
                accumulatedTranslation = 0
            }
        }
    }
    
    private func handlePanEnded(velocity: CGFloat) {
        guard let delegate = delegate else { return }
        
        if isDraggingSheet {
            delegate.handleDragEnd(accumulatedTranslation, velocity: velocity)
        }
        
        isDraggingSheet = false
        accumulatedTranslation = 0
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGesture else { return true }
        
        let velocity = panGesture.velocity(in: view)
        return abs(velocity.y) > abs(velocity.x)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 && !isDraggingSheet {
            scrollView.contentOffset.y = 0
        }
    }
}
