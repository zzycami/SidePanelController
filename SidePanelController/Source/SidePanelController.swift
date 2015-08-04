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

public class SidePanelController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK: Usage
    
    // set the panels
    public var leftPanel:UIViewController? {
        didSet {
            if let _oldValue = oldValue, _leftPanel = self.leftPanel {
                if _oldValue != _leftPanel {
                    _oldValue.willMoveToParentViewController(nil)
                    _oldValue.view.removeFromSuperview()
                    _oldValue.removeFromParentViewController()
                    self.addChildViewController(_leftPanel)
                    _leftPanel.didMoveToParentViewController(self)
                    if self.state == SidePanelState.RightVisible {
                        self.visiblePanel = _leftPanel
                    }
                }
            }
        }
    }
    
    public var centerPanel:UIViewController {
        didSet {
            if self.centerPanel != oldValue {
                oldValue.removeObserver(self, forKeyPath: "view")
                oldValue.removeObserver(self, forKeyPath: "viewControllers")
                self.centerPanel.addObserver(self, forKeyPath: "viewControllers", options: NSKeyValueObservingOptions.allZeros, context: &ja_kvoContext)
                self.centerPanel.addObserver(self, forKeyPath: "view", options: NSKeyValueObservingOptions.Initial, context: &ja_kvoContext)
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
    
    public var rightPanel:UIViewController? {
        didSet {
            if let _oldValue = oldValue, _rightPanel = self.rightPanel {
                if _oldValue != _rightPanel {
                    _oldValue.willMoveToParentViewController(nil)
                    _oldValue.view.removeFromSuperview()
                    _oldValue.removeFromParentViewController()
                    self.addChildViewController(_rightPanel)
                    _rightPanel.didMoveToParentViewController(self)
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
        if centerPanel.view.superview != nil {
            centerPanel.view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
            centerPanel.view.frame = centerPanelContainer.bounds
            stylePanel(centerPanel.view)
            centerPanelContainer.addSubview(centerPanel.view)
        }
    }
    
    private func hideCenterPanel() {
        centerPanelContainer.hidden = true
        if centerPanel.isViewLoaded() {
            centerPanel.view.removeFromSuperview()
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
    }
    
    public func toggleRightPanel(sender:AnyObject) {
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
    public var visiblePanel:UIViewController!
    
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
    private var tapView:UIView?
    
    
    //MARK: Life Cycle
    public init(centerPanel:UIViewController) {
        self.centerPanel = centerPanel
        super.init(nibName: nil, bundle: nil)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        centerPanel.removeObserver(self, forKeyPath: "view")
        centerPanel.removeObserver(self, forKeyPath: "viewControllers")
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
    
    public override func shouldAutorotate() -> Bool {
        var visiblePanel = self.visiblePanel
        if shouldDelegateAutorotateToVisiblePanel && visiblePanel.respondsToSelector("shouldAutorotate") {
            return visiblePanel.shouldAutorotate()
        }else {
            return true
        }
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
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let tapView = self.tapView, view = gestureRecognizer.view{
            if view == tapView {
                return true
            }else if panningLimitedToTopViewController && !isOnTopLevelViewController(centerPanel) {
                return false
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
        }
        return false
    }
    
    private func addPanGestureToView(view:UIView) {
        
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
    
    
    private func configureContainers() {
        self.leftPanelContainer.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleRightMargin
        self.rightPanelContainer.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleHeight
        self.centerPanelContainer.frame = view.bounds
        self.centerPanelContainer.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    }
    
    private func swapCenter(previous:UIViewController?, previousState:SidePanelState, next:UIViewController?) {
        if previous != next {
            previous?.willMoveToParentViewController(nil)
            previous?.view.removeFromSuperview()
            previous?.removeFromParentViewController()
            
            if let viewController = next {
                loadCenterPanelWithPreviousState(previousState)
                addChildViewController(viewController)
                centerPanelContainer.addSubview(viewController.view)
                viewController.didMoveToParentViewController(self)
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
    }
    
    private func loadLeftPanel() {
        rightPanelContainer.hidden = true
        if leftPanelContainer.hidden && self.leftPanel != nil {
            if let leftPanelView = leftPanel?.view {
                if leftPanelView.superview != nil {
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
            if let rightPanelView = rightPanel?.view {
                if rightPanelView.superview != nil {
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
        if let leftPanel = self.leftPanel {
            if canUnloadLeftPanel && leftPanel.isViewLoaded() {
                self.leftPanel?.view.removeFromSuperview()
            }
        }
        if let rightPanel = self.rightPanel {
            if canUnloadRightPanel && rightPanel.isViewLoaded() {
                rightPanel.view.removeFromSuperview()
            }
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
        if let rightPanel = self.rightPanel {
            if rightPanel.isViewLoaded() {
                var frame = rightPanelContainer.bounds
                if shouldResizeRightPanel {
                    if !pushesSidePanels {
                        frame.origin.x = rightPanelContainer.bounds.size.width - self.rightVisibleWidth
                    }
                    frame.size.width = rightVisibleWidth
                }
                rightPanelContainer.frame = frame
            }
        }
        
        if let leftPanel = self.leftPanel {
            if leftPanel.isViewLoaded() {
                var frame = leftPanelContainer.bounds
                if shouldResizeLeftPanel {
                    frame.size.width = leftVisibleWidth
                }
                leftPanelContainer.frame = frame
            }
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
            frame.origin.x = rightVisibleWidth
            if style == SidePanelStyle.MultipleActive {
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
        if leftPanel != nil {
            var buttonController = centerPanel
            if buttonController.isKindOfClass(UINavigationController) {
                var nav = buttonController as! UINavigationController
                if nav.viewControllers.count > 0 {
                    buttonController = nav.viewControllers[0] as! UIViewController
                }
            }
            if buttonController.navigationItem.leftBarButtonItem != nil {
                buttonController.navigationItem.leftBarButtonItem = leftButtonForCenterPanel()
            }
        }
    }
}
