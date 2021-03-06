//
//  SidePanelController.swift
//  SidePanelController
//
//  Created by 周泽勇 on 15/7/29.
//  Copyright (c) 2015年 周泽勇. All rights reserved.
//

import UIKit

public enum SidePanelStyle:Int {
    case SingleActive
    case MultipleActive
}

public enum SidePanelState:Int {
    case CenterVisible
    case LeftVisible
    case RightVisible
    case NonVisible
}

private var ja_kvoContext:Void

public extension UIViewController {
    public var sidePanelController:SidePanelController? {
        get {
            var iter = self.parentViewController
            while iter != nil {
                if iter!.isKindOfClass(SidePanelController) {
                    return iter! as? SidePanelController
                }else if iter!.parentViewController != nil && iter!.parentViewController != iter! {
                    iter = iter!.parentViewController
                }else {
                    iter = nil
                }
            }
            return nil
        }
    }
}

public class SidePanelController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK: Usage
    
    // set the panels
    public var leftPanel:UIView? {
        didSet {
            if let _oldValue = oldValue, _leftPanel = self.leftPanel {
                if _oldValue != _leftPanel {
                    _oldValue.removeFromSuperview()
                    if self.state == SidePanelState.RightVisible {
                        self.visiblePanel = _leftPanel
                    }
                }
            }
        }
    }
    
    public var centerPanel:UIView? {
        didSet {
            if self.centerPanel != oldValue {
                oldValue?.removeObserver(self, forKeyPath: "view")
                oldValue?.removeObserver(self, forKeyPath: "viewControllers")
                self.centerPanel?.addObserver(self, forKeyPath: "viewControllers", options: NSKeyValueObservingOptions.allZeros, context: &ja_kvoContext)
                self.centerPanel?.addObserver(self, forKeyPath: "view", options: NSKeyValueObservingOptions.Initial, context: &ja_kvoContext)
                if self.state == SidePanelState.CenterVisible {
                    visiblePanel = self.centerPanel
                }
            }
            if self.isViewLoaded() && self.state == SidePanelState.CenterVisible {
                self.swapCenter(oldValue, previousState: SidePanelState.NonVisible, next: self.centerPanel)
            }else if self.isViewLoaded() {
                // update the state immediately to prevent user interaction on the side panels while animating
                var previousState = self.state
                self.state = SidePanelState.CenterVisible
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    if self.bounceOnCenterPanelChange {
                        // first move the centerPanel offscreen
                        var x = (previousState == SidePanelState.LeftVisible) ? self.view.bounds.size.width : -self.view.bounds.size.width
                        self._centerPanelRestingFrame.origin.x = x
                    }
                    }, completion: { (finished:Bool) -> Void in
                        self.swapCenter(oldValue, previousState: previousState, next: self.centerPanel)
                        self.showCenterPanel(true, shouldBounce: false)
                })
            }
        }
    }
    
    public var rightPanel:UIView? {
        didSet {
            if let _oldValue = oldValue, _rightPanel = self.rightPanel {
                if _oldValue != _rightPanel {
                    _oldValue.removeFromSuperview()
                    if self.state == SidePanelState.RightVisible {
                        self.visiblePanel = _rightPanel
                    }
                }
            }
        }
    }
    
    // show the panels
    public func showLeftPanel(animated:Bool) {
        showLeftPanel(animated, shouldBounce: false)
    }
    
    private func showLeftPanel(animated:Bool, shouldBounce:Bool) {
        state = SidePanelState.LeftVisible
        loadLeftPanel()
        
        adjustCenterFrame()
        
        if animated {
            animateCenterPanel(shouldBounce, completion: nil)
        } else {
            self.centerPanelContainer.frame = _centerPanelRestingFrame
            styleContainer(centerPanelContainer, animate: false, duration: 0)
            if style == SidePanelStyle.MultipleActive || pushesSidePanels {
                layoutSideContainers(false, duration: 0)
            }
        }
        
        if style == SidePanelStyle.SingleActive {
            tapView = UIView()
        }
        
        toggleScrollsToTopForCenter(false, left: true, right: false)
    }
    
    public func showRightPanel(animated:Bool) {
        showRightPanel(animated, shouldBounce: false)
    }
    
    private func showRightPanel(animated:Bool, shouldBounce:Bool) {
        state = SidePanelState.RightVisible
        loadRightPanel()
        
        adjustCenterFrame()
        if animated {
            animateCenterPanel(shouldBounce, completion: nil)
        }else {
            centerPanelContainer.frame = _centerPanelRestingFrame
            styleContainer(centerPanelContainer, animate: false, duration: 0)
            if style == SidePanelStyle.MultipleActive || pushesSidePanels {
                layoutSideContainers(false, duration: 0)
            }
        }
        
        if style == SidePanelStyle.SingleActive {
            tapView = UIView()
        }
        toggleScrollsToTopForCenter(false, left: false, right: true)
    }
    
    public func showCenterPanel(animated:Bool) {
        // make sure center panel isn't hidden
        if centerPanelHidden {
            centerPanelHidden = false
            unhideCenterPanel()
        }
        showCenterPanel(animated, shouldBounce: false)
    }
    
    private func showCenterPanel(animated:Bool, shouldBounce:Bool) {
        state = SidePanelState.CenterVisible
        adjustCenterFrame()
        if animated {
            animateCenterPanel(shouldBounce, completion: { (finished:Bool) -> Void in
                self.leftPanelContainer.hidden = true
                self.rightPanelContainer.hidden = true
                self.unloadPanels()
            })
        }else {
            centerPanelContainer.frame = _centerPanelRestingFrame
            styleContainer(centerPanelContainer, animate: false, duration: 0)
            if style == SidePanelStyle.MultipleActive || pushesSidePanels {
                layoutSideContainers(false, duration: 0)
            }
            leftPanelContainer.hidden = true
            rightPanelContainer.hidden = true
            unloadPanels()
        }
        tapView = nil
        toggleScrollsToTopForCenter(true, left: false, right: false)
    }
    
    private func unhideCenterPanel() {
        centerPanelContainer.hidden = false
        if centerPanel?.superview != nil {
            centerPanel!.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
            centerPanel!.frame = centerPanelContainer.bounds
            stylePanel(centerPanel!)
            centerPanelContainer.addSubview(centerPanel!)
        }
    }
    
    private func hideCenterPanel() {
        centerPanelContainer.hidden = true
        if isViewLoaded() {
            centerPanel!.removeFromSuperview()
        }
    }
    
    private func toggleScrollsToTopForCenter(center:Bool, left:Bool, right:Bool) {
        // iPhone only supports 1 active UIScrollViewController at a time
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Phone {
            toggleScrollsToTop(center, view: centerPanelContainer)
            toggleScrollsToTop(left, view: leftPanelContainer)
            toggleScrollsToTop(right, view: rightPanelContainer)
        }
    }
    
    private func toggleScrollsToTop(enabled:Bool, view:UIView)->Bool {
        if view.isKindOfClass(UIScrollView) {
            var scrollView = view as! UIScrollView
            scrollView.scrollsToTop = enabled
            return true
        }else {
            for subview in view.subviews {
                if toggleScrollsToTop(enabled, view: subview as! UIView) {
                    return true
                }
            }
        }
        return false
    }
    
    // toggle them opened/closed
    public func toggleLeftPanel(sender:AnyObject) {
        if state == SidePanelState.LeftVisible {
            showCenterPanel(true, shouldBounce: false)
        }else if state == SidePanelState.CenterVisible {
            showLeftPanel(true, shouldBounce: false)
        }
    }
    
    public func toggleRightPanel(sender:AnyObject) {
        if state == SidePanelState.RightVisible {
            showCenterPanel(true, shouldBounce: false)
        }else {
            showRightPanel(true, shouldBounce: false)
        }
    }
    
    
    // Calling this while the left or right panel is visible causes the center panel to be completely hidden
    public func setCenterPanelHidden(centerPanelHidden:Bool, animated:Bool, duration:NSTimeInterval) {
    }
    
    //MARK: style
    
    //MARK: Look & Feel
    // style
    public var style:SidePanelStyle = SidePanelStyle.SingleActive {
        didSet {
            if isViewLoaded() {
                configureContainers()
                layoutSideContainers(false, duration: 0)
            }
        }
    }
    
    // push side panels instead of overlapping them
    public var pushesSidePanels:Bool = false
    
    // size the left panel based on % of total screen width
    public var leftGapPercentage:CGFloat = 0.5
    
    // size the left panel based on this fixed size. overrides leftGapPercentage
    public var leftFixedWidth:CGFloat = 0
    
    // the visible width of the left panel
    public var leftVisibleWidth:CGFloat {
        if self.centerPanelHidden && self.shouldResizeLeftPanel {
            return self.view.bounds.size.width
        }else {
            var width = CGFloat(floorf(Float(self.view.bounds.size.width) * Float(self.leftGapPercentage)))
            return (self.leftFixedWidth != 0) ? self.leftFixedWidth : width
        }
    }
    
    // size the right panel based on % of total screen width
    public var rightGapPercentage:CGFloat = 0.5
    
    // size the right panel based on this fixed size. overrides rightGapPercentage
    public var rightFixedWidth:CGFloat = 0
    
    // the visible width of the right panel
    public var rightVisibleWidth:CGFloat {
        if self.centerPanelHidden && self.shouldResizeRightPanel {
            return self.view.bounds.size.width
        }else {
            var width = CGFloat(floorf(Float(self.view.bounds.size.width) * Float(self.rightGapPercentage)))
            return (self.rightFixedWidth != 0) ? self.rightFixedWidth : width
        }
    }
    
    private var _centerPanelRestingFrame:CGRect = CGRectZero
    private var _locationBeforePan:CGPoint = CGPointZero
    
    // by default applies a black shadow to the container. override in sublcass to change
    public func styleContainer(container:UIView, animate:Bool, duration:NSTimeInterval) {
        var shadowPath = UIBezierPath(roundedRect: container.bounds, cornerRadius: 0)
        if animate {
            var animation = CABasicAnimation(keyPath: "shadowPath")
            animation.fromValue = container.layer.shadowPath
            animation.toValue = shadowPath.CGPath
            animation.duration = duration
            container.layer.addAnimation(animation, forKey: "shadowPath")
        }
        container.layer.shadowPath = shadowPath.CGPath
        container.layer.shadowColor = UIColor.blackColor().CGColor
        container.layer.shadowRadius = 4.0
        container.layer.shadowOpacity = 0.25
        container.clipsToBounds = false
    }
    
    public func stylePanel(panel:UIView) {
        panel.layer.cornerRadius = 0
        panel.clipsToBounds = true
    }
    
    //MARK: Animation
    
    // the minimum % of total screen width the centerPanel.view must move for panGesture to succeed
    public var minimumMovePercentage:CGFloat = 0.15
    
    // the maximum time panel opening/closing should take. Actual time may be less if panGesture has already moved the view.
    public var maximumAnimationDuration:CGFloat = 0.2
    
    // how long the bounce animation should take
    public var bounceDuration:NSTimeInterval = 0.1
    
    // how far the view should bounce
    public var bouncePercentage:CGFloat = 0.075
    
    // should the center panel bounce when you are panning open a left/right panel.
    public var bounceOnSidePanelOpen:Bool = true
    
    // should the center panel bounce when you are panning closed a left/right panel.
    public var bounceOnSidePanelClose:Bool = false
    
    // while changing the center panel, should we bounce it offscreen?
    public var bounceOnCenterPanelChange:Bool = true
    
    //MARK: Gesture Behavior
    
    // Determines whether the pan gesture is limited to the top ViewController in a UINavigationController/UITabBarController
    public var panningLimitedToTopViewController:Bool = true
    
    // Determines whether showing panels can be controlled through pan gestures, or only through buttons
    public var recognizesPanGesture:Bool = true
    
    //MARK: Menu Buttons
    public static var defaultImage:UIImage {
        var defaultImage:UIImage
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 13), false, 0)
        
        UIColor.blackColor().setFill()
        UIBezierPath(rect: CGRectMake(0, 0, 20, 1)).fill()
        UIBezierPath(rect: CGRectMake(0, 5, 20, 1)).fill()
        UIBezierPath(rect: CGRectMake(0, 10, 20, 1)).fill()
        
        UIColor.whiteColor().setFill()
        UIBezierPath(rect: CGRectMake(0, 0, 20, 2)).fill()
        UIBezierPath(rect: CGRectMake(0, 6, 20, 2)).fill()
        UIBezierPath(rect: CGRectMake(0, 11, 20, 2)).fill()
        
        defaultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return defaultImage
    }
    
    public func leftButtonForCenterPanel()->UIBarButtonItem {
        return UIBarButtonItem(image: SidePanelController.defaultImage, style: UIBarButtonItemStyle.Plain, target: self, action: "toggleLeftPanel:")
    }
    
    //MARK: Nuts & Bolts
    
    // Current state of panels. Use KVO to monitor state changes
    public var state:SidePanelState = SidePanelState.CenterVisible {
        didSet {
            if oldValue != self.state {
                switch self.state {
                case .CenterVisible:
                    visiblePanel = centerPanel
                    leftPanelContainer.userInteractionEnabled = false
                    rightPanelContainer.userInteractionEnabled = false
                    break
                case .LeftVisible:
                    visiblePanel = leftPanel
                    leftPanelContainer.userInteractionEnabled = true
                    break
                case .RightVisible:
                    visiblePanel = rightPanel
                    rightPanelContainer.userInteractionEnabled = true
                    break
                default:
                    break
                }
            }
        }
    }
    
    // Whether or not the center panel is completely hidden
    public var centerPanelHidden:Bool = false
    
    // The currently visible panel
    public var visiblePanel:UIView!
    
    // If set to yes, "shouldAutorotateToInterfaceOrientation:" will be passed to self.visiblePanel instead of handled directly
    public var shouldDelegateAutorotateToVisiblePanel:Bool = true
    
    // Determines whether or not the panel's views are removed when not visble. If YES, rightPanel & leftPanel's views are eligible for viewDidUnload
    public var canUnloadRightPanel:Bool = false
    public var canUnloadLeftPanel:Bool = false
    
    // Determines whether or not the panel's views should be resized when they are displayed. If yes, the views will be resized to their visible width
    public var shouldResizeRightPanel:Bool = false
    public var shouldResizeLeftPanel:Bool = false
    
    // Determines whether or not the center panel can be panned beyound the the visible area of the side panels
    public var allowRightOverpan:Bool = true
    public var allowLeftOverpan:Bool = true
    
    // Determines whether or not the left or right panel can be swiped into view. Use if only way to view a panel is with a button
    public var allowLeftSwipe:Bool = true
    public var allowRightSwipe:Bool = true
    
    // Containers for the panels.
    internal(set) var leftPanelContainer:UIView = UIView(frame: CGRectZero)
    internal(set) var rightPanelContainer:UIView = UIView(frame: CGRectZero)
    internal(set) var centerPanelContainer:UIView = UIView(frame: CGRectZero)
    private var tapView:UIView? {
        didSet {
            if oldValue != self.tapView {
                oldValue?.removeFromSuperview()
                if self.tapView != nil {
                    self.tapView!.frame = self.centerPanelContainer.bounds
                    self.tapView!.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
                    addTapGuestureToView(self.tapView!)
                    
                    if self.recognizesPanGesture {
                        addPanGestureToView(self.tapView!)
                    }
                    
                    centerPanelContainer.addSubview(self.tapView!)
                }
            }
        }
    }
    
    private func addTapGuestureToView(view:UIView) {
        var tapGesture = UITapGestureRecognizer(target: self, action: "centerPanelTapped:")
        view.addGestureRecognizer(tapGesture)
    }
    
    func centerPanelTapped(gesture:UIGestureRecognizer) {
        showCenterPanel(true, shouldBounce: false)
    }
    
    
    //MARK: Life Cycle
    
    deinit {
        centerPanel?.removeObserver(self, forKeyPath: "view")
        centerPanel?.removeObserver(self, forKeyPath: "viewControllers")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        centerPanelContainer = UIView(frame: self.view.bounds)
        _centerPanelRestingFrame = centerPanelContainer.frame
        centerPanelHidden = false
        
        leftPanelContainer = UIView(frame: view.bounds)
        leftPanelContainer.hidden = true
        
        rightPanelContainer = UIView(frame: view.bounds)
        rightPanelContainer.hidden = true
        
        configureContainers()
        
        view.addSubview(centerPanelContainer)
        view.addSubview(leftPanelContainer)
        view.addSubview(rightPanelContainer)
        
        state = SidePanelState.CenterVisible
        
        swapCenter(nil, previousState: SidePanelState.CenterVisible, next: centerPanel)
        view.bringSubviewToFront(centerPanelContainer)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // ensure correct view dimensions
        layoutSideContainers(false, duration: 0)
        layoutSidePanels()
        centerPanelContainer.frame = adjustCenterFrame()
        styleContainer(centerPanelContainer, animate: false, duration: 0)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        adjustCenterFrame()//Account for possible rotation while view appearing
    }
    
    
    public override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        layoutSideContainers(true, duration: duration)
        layoutSidePanels()
        styleContainer(centerPanelContainer, animate: true, duration: duration)
        if centerPanelHidden {
            var frame = centerPanelContainer.frame
            frame.origin.x = (self.state == SidePanelState.LeftVisible) ? centerPanelContainer.frame.size.width : -self.centerPanelContainer.frame.size.width
            centerPanelContainer.frame = frame
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Delegate
    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &ja_kvoContext {
            if keyPath == "view" {
                if let centerPanel = self.centerPanel {
                    if isViewLoaded() && recognizesPanGesture {
                        addPanGestureToView(centerPanel)
                    }
                }
            }else if keyPath == "viewControllers" && object as! NSObject == self.centerPanel! {
                // view controllers have changed, need to replace the button
                placeButtonForLeftPanel()
            }
        }else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let tapView = self.tapView, view = gestureRecognizer.view{
            if view == tapView {
                return true
            }
        }else if gestureRecognizer.isKindOfClass(UIPanGestureRecognizer) {
            var pan = gestureRecognizer as! UIPanGestureRecognizer
            var translate = pan.translationInView(centerPanelContainer)
            // determine if right swipe is allowed
            if translate.x < 0 && !allowRightSwipe {
                return false
            }
            // determine if left swipe is allowed
            if translate.x > 0 && !allowLeftSwipe {
                return false
            }
            var possible = (translate.x != 0) && ((fabs(translate.y) / fabs(translate.x)) < 1)
            if possible && ((translate.x > 0 && self.leftPanel != nil) || (translate.x < 0 && self.rightPanel != nil)) {
                return true
            }
        }
        return false
    }
    
    private func addPanGestureToView(view:UIView) {
        var panGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
    }
    
    func handlePan(sender:UIGestureRecognizer) {
        if !recognizesPanGesture {
            return
        }
        if sender.isKindOfClass(UIPanGestureRecognizer) {
            var pan = sender as! UIPanGestureRecognizer
            
            if pan.state == UIGestureRecognizerState.Began {
                _locationBeforePan = centerPanelContainer.frame.origin
            }
            
            var translate = pan.translationInView(centerPanelContainer)
            var frame = _centerPanelRestingFrame
            frame.origin.x += CGFloat(roundf(Float(correctMovement(translate.x))))
            
            if style == SidePanelStyle.MultipleActive {
                frame.size.width = view.bounds.size.width - frame.origin.x
            }
            
            println("frame(\(frame.origin.x), \(frame.origin.y), \(frame.size.width), \(frame.size.height))")
            centerPanelContainer.frame = frame
            
            // if center panel has focus, make sure correct side panel is revealed
            if state == SidePanelState.CenterVisible {
                if frame.origin.x > 0 {
                    loadLeftPanel()
                }else if frame.origin.x < 0 {
                    loadRightPanel()
                }
            }
            
            // adjust side panel locations, if needed
            if style == SidePanelStyle.MultipleActive || pushesSidePanels {
                layoutSideContainers(false, duration: 0)
            }
            
            if sender.state == UIGestureRecognizerState.Ended {
                var deltaX = frame.origin.x - _locationBeforePan.x
                if validateThreshold(deltaX) {
                    completePan(deltaX)
                }else {
                    undoPan()
                }
            }else if sender.state == UIGestureRecognizerState.Cancelled {
                undoPan()
            }
        }
    }
    
    func completePan(deltaX:CGFloat) {
        switch state {
        case .CenterVisible:
            if deltaX > 0 {
                showLeftPanel(true, shouldBounce: bounceOnSidePanelOpen)
            }else {
                showRightPanel(true, shouldBounce: bounceOnSidePanelOpen)
            }
            break
        case .LeftVisible:
            showCenterPanel(true, shouldBounce: bounceOnSidePanelClose)
            break
        case .RightVisible:
            showCenterPanel(true, shouldBounce: bounceOnSidePanelClose)
            break
        default:
            break
        }
    }
    
    func undoPan() {
        switch state {
        case .CenterVisible:
            showCenterPanel(true, shouldBounce: false)
            break
        case .LeftVisible:
            showLeftPanel(true, shouldBounce: false)
            break
        case .RightVisible:
            showRightPanel(true, shouldBounce: false)
        default:
            break
        }
    }
    
    //MARK: Privae Method
    private func isOnTopLevelViewController(root:UIViewController?)->Bool {
        if let _root = root {
            if _root.isKindOfClass(UINavigationController) {
                var nav = _root as! UINavigationController
                return nav.viewControllers.count == 1
            }else if _root.isKindOfClass(UITabBarController) {
                var tab = _root as! UITabBarController
                return isOnTopLevelViewController(tab.selectedViewController)
            }
        }
        return root != nil
    }
    
    private func correctMovement(movement:CGFloat)->CGFloat {
        var position = _centerPanelRestingFrame.origin.x + movement
        if state == SidePanelState.CenterVisible {
            if (position > 0 && leftPanel == nil) || (position < 0 && rightPanel == nil) {
                return 0
            }else if !allowLeftOverpan && position > leftVisibleWidth {
                return leftVisibleWidth
            }else if !allowRightOverpan && position < -rightVisibleWidth {
                return -rightVisibleWidth
            }
        }else if state == SidePanelState.RightVisible && !allowRightOverpan {
            if position < -self.rightVisibleWidth {
                return 0
            }else if (style == SidePanelStyle.MultipleActive || pushesSidePanels) && position > 0 {
                return -_centerPanelRestingFrame.origin.x
            }else if position > rightPanelContainer.frame.origin.x {
                return rightPanelContainer.frame.origin.x - _centerPanelRestingFrame.origin.x
            }
        }else if state == SidePanelState.LeftVisible && !allowLeftOverpan {
            if position > leftVisibleWidth {
                return 0
            }else if state == SidePanelState.LeftVisible && !allowLeftOverpan {
                return -_centerPanelRestingFrame.origin.x
            }else if position < leftPanelContainer.frame.origin.x {
                return leftPanelContainer.frame.origin.x - _centerPanelRestingFrame.origin.x
            }
        }
        
        return movement
    }
    
    private func validateThreshold(movement:CGFloat)->Bool {
        var minimum = CGFloat(floorf(Float(view.bounds.size.width)*Float(minimumMovePercentage)))
        switch state {
        case .LeftVisible:
            return movement <= -minimum
        case .CenterVisible:
            return fabs(movement) >= minimum
        case .RightVisible:
            return movement >= minimum
        default:
            return false
        }
    }
    
    
    private func configureContainers() {
        self.leftPanelContainer.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleRightMargin
        self.rightPanelContainer.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleHeight
        self.centerPanelContainer.frame = view.bounds
        self.centerPanelContainer.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    }
    
    private func swapCenter(previous:UIView?, previousState:SidePanelState, next:UIView?) {
        if previous != next {
            previous?.removeFromSuperview()
            
            if let nextView = next {
                loadCenterPanelWithPreviousState(previousState)
                centerPanelContainer.addSubview(nextView)
            }
        }
    }
    
    //MARK: Loading Panels
    private func loadCenterPanelWithPreviousState(previousState:SidePanelState) {
        placeButtonForLeftPanel()
        
        // for the multi-active style, it looks better if the new center starts out in it's fullsize and slides in
        if style == SidePanelStyle.MultipleActive {
            switch previousState {
            case .LeftVisible:
                var frame = centerPanelContainer.frame
                frame.size.width = view.bounds.size.width
                centerPanelContainer.frame = frame
                break
            case .RightVisible:
                var frame = centerPanelContainer.frame
                frame.size.width = view.bounds.size.width
                frame.origin.x = -rightVisibleWidth
                centerPanelContainer.frame = frame
                break
            default:
                break
            }
        }
        
        if let centerPanel = self.centerPanel {
            centerPanel.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
            centerPanel.frame = centerPanelContainer.bounds
            stylePanel(centerPanel)
        }
    }
    
    private func loadLeftPanel() {
        rightPanelContainer.hidden = true
        if leftPanelContainer.hidden && self.leftPanel != nil {
            if let leftPanelView = leftPanel {
                if leftPanelView.superview == nil {
                    layoutSidePanels()
                    leftPanelView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
                    stylePanel(leftPanelView)
                    leftPanelContainer.addSubview(leftPanelView)
                }
            }
            leftPanelContainer.hidden = false
        }
    }
    
    private func loadRightPanel() {
        leftPanelContainer.hidden = true
        if rightPanelContainer.hidden && rightPanel != nil {
            if let rightPanelView = rightPanel {
                if rightPanelView.superview == nil {
                    layoutSidePanels()
                    rightPanelView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
                    stylePanel(rightPanelView)
                    rightPanelContainer.addSubview(rightPanelView)
                }
            }
            rightPanelContainer.hidden = false
        }
    }
    
    private func unloadPanels() {
        if canUnloadLeftPanel && leftPanel != nil {
            self.leftPanel!.removeFromSuperview()
        }
        if canUnloadRightPanel && rightPanel != nil {
            rightPanel!.removeFromSuperview()
        }
    }
    
    //MARK: Animation
    private func calculatedDuration()->NSTimeInterval {
        var remaining = fabs(centerPanelContainer.frame.origin.x - _centerPanelRestingFrame.origin.x)
        var max = _locationBeforePan.x == _centerPanelRestingFrame.origin.x ? remaining : _locationBeforePan.x - _centerPanelRestingFrame.origin.x
        return (max > 0) ? NSTimeInterval(self.maximumAnimationDuration * (remaining / max)) : NSTimeInterval(self.maximumAnimationDuration)
    }
    
    private func animateCenterPanel(shouldBounce:Bool, completion:((Bool)->Void)?) {
        var _shouldBounce = shouldBounce
        var bounceDistance = NSTimeInterval((_centerPanelRestingFrame.origin.x - self.centerPanelContainer.frame.origin.x) * self.bouncePercentage)
        // looks bad if we bounce when the center panel grows
        if _centerPanelRestingFrame.size.width > self.centerPanelContainer.frame.size.width {
            _shouldBounce = false
        }
        
        var duration = calculatedDuration()
        var delay:NSTimeInterval = 0
        UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveLinear | UIViewAnimationOptions.LayoutSubviews, animations: { () -> Void in
            
            self.centerPanelContainer.frame = self._centerPanelRestingFrame
            self.styleContainer(self.centerPanelContainer, animate: true, duration: duration)
            if self.style == SidePanelStyle.MultipleActive || self.pushesSidePanels {
                self.layoutSideContainers(false, duration: 0)
            }
            }) { (finished:Bool) -> Void in
                if _shouldBounce {
                    // make sure correct panel is displayed under the bounce
                    if self.state == SidePanelState.CenterVisible {
                        if bounceDistance > 0 {
                            self.loadLeftPanel()
                        }else {
                            self.loadRightPanel()
                        }
                    }
                    
                    // animate the bounce
                    UIView.animateWithDuration(self.bounceDuration, delay: delay, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                        var bounceFrame = self._centerPanelRestingFrame
                        bounceFrame.origin.x += CGFloat(bounceDistance)
                        self.centerPanelContainer.frame = bounceFrame
                        }, completion: { (finished:Bool) -> Void in
                            
                            UIView.animateWithDuration(self.bounceDuration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                                self.centerPanelContainer.frame = self._centerPanelRestingFrame
                                
                                }, completion: { (finished:Bool) -> Void in
                                    if let _completion = completion {
                                        _completion(finished)
                                    }
                            })
                            
                    })
                }
        }
    }
    
    //MARK: Style
    private func layoutSideContainers(animate:Bool, duration:NSTimeInterval) {
        var leftFrame = view.bounds
        var rightFrame = view.bounds
        if style == SidePanelStyle.MultipleActive {
            // left panel container
            leftFrame.size.width = leftVisibleWidth
            leftFrame.origin.x = centerPanelContainer.frame.origin.x - leftFrame.width
            
            // right panel container
            rightFrame.size.width = rightVisibleWidth
            rightFrame.origin.x = centerPanelContainer.frame.origin.x + centerPanelContainer.frame.size.width
        }else if pushesSidePanels && !centerPanelHidden {
            leftFrame.origin.x = centerPanelContainer.frame.origin.x - leftVisibleWidth
            rightFrame.origin.x = centerPanelContainer.frame.origin.x + centerPanelContainer.frame.size.width
        }
        
        leftPanelContainer.frame = leftFrame
        rightPanelContainer.frame = rightFrame
        styleContainer(leftPanelContainer, animate: animate, duration: duration)
        styleContainer(rightPanelContainer, animate: animate, duration: duration)
    }
    
    
    private func layoutSidePanels() {
        if rightPanel != nil {
            var frame = rightPanelContainer.bounds
            if shouldResizeRightPanel {
                if !pushesSidePanels {
                    frame.origin.x = rightPanelContainer.bounds.size.width - self.rightVisibleWidth
                }
                frame.size.width = rightVisibleWidth
            }
            rightPanelContainer.frame = frame
        }
        
        if leftPanel != nil {
            var frame = leftPanelContainer.bounds
            if shouldResizeLeftPanel {
                frame.size.width = leftVisibleWidth
            }
            leftPanelContainer.frame = frame
        }
    }
    
    private func adjustCenterFrame()->CGRect {
        var frame = view.bounds
        switch state {
        case .CenterVisible:
            frame.origin.x = 0
            if style == SidePanelStyle.MultipleActive {
                frame.size.width = view.bounds.size.width
            }
            break
        case .LeftVisible:
            frame.origin.x = leftVisibleWidth
            if style == SidePanelStyle.MultipleActive {
                frame.size.width = view.bounds.size.width - leftVisibleWidth
            }
            break
        case .RightVisible:
            frame.origin.x = -rightVisibleWidth
            if style == SidePanelStyle.MultipleActive {
                frame.origin.x = 0
                frame.size.width = view.bounds.size.width - rightVisibleWidth
            }
            break
        default:
            break
        }
        _centerPanelRestingFrame = frame
        return _centerPanelRestingFrame
    }
    
    private func placeButtonForLeftPanel () {
//        if leftPanel != nil {
//            var buttonController = self.superclass
//            if buttonController.isKindOfClass(UINavigationController) {
//                var nav = buttonController as! UINavigationController
//                if nav.viewControllers.count > 0 {
//                    buttonController = nav.viewControllers[0] as UIViewController
//                }
//            }
//            if buttonController.navigationItem.leftBarButtonItem != nil {
//                buttonController!.navigationItem.leftBarButtonItem = leftButtonForCenterPanel()
//            }
//        }
    }
}
 