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
}

public class SidePanelController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK: Usage
    
    // set the panels
    public var leftPanel:UIViewController?
    public var centerPanel:UIViewController
    public var rightPanel:UIViewController?
    
    // show the panels
    public func showLeftPanel(animated:Bool) {
    }
    
    public func showRightPanel(animated:Bool) {
    }
    
    public func showCenterPanel(animated:Bool) {
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
    
    // style
    public var style:SidePanelStyle = SidePanelStyle.SingleActive
    
    // push side panels instead of overlapping them
    public var pushesSidePanels:Bool = false
    
    // size the left panel based on % of total screen width
    public var leftGapPercentage:CGFloat = 0.5
    
    // size the left panel based on this fixed size. overrides leftGapPercentage
    public var leftFixedWidth:CGFloat = 0
    
    // the visible width of the left panel
    public var leftVisibleWidth:CGFloat = 0
    
    // size the right panel based on % of total screen width
    public var rightGapPercentage:CGFloat = 0.5
    
    // size the right panel based on this fixed size. overrides rightGapPercentage
    public var rightFixedWidth:CGFloat = 0
    
    // the visible width of the right panel
    public var rightVisibleWidth:CGFloat = 0
    
    // by default applies a black shadow to the container. override in sublcass to change
    public func styleContainer(container:UIView, animate:Bool, duration:NSTimeInterval) {
    }
    
    public func stylePanel(panel:UIView) {
    }
    
    //MARK: Animation
    
    // the minimum % of total screen width the centerPanel.view must move for panGesture to succeed
    public var minimumMovePercentage:CGFloat = 0.15
    
    // the maximum time panel opening/closing should take. Actual time may be less if panGesture has already moved the view.
    public var maximumAnimationDuration:CGFloat = 0.2
    
    // how long the bounce animation should take
    public var bounceDuration:CGFloat = 0.1
    
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
        return UIBarButtonItem()
    }
    
    //MARK: Nuts & Bolts
    
    // Current state of panels. Use KVO to monitor state changes
    public var state:SidePanelState = SidePanelState.CenterVisible
    
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
    
    private var _centerPanelRestingFrame:CGRect = CGRectZero
    private var _locationBeforePan:CGPoint = CGPointZero
    
    
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
        
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Privae Method
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
    
    private func loadCenterPanelWithPreviousState(previousState:SidePanelState) {
        
    }
    
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
}
