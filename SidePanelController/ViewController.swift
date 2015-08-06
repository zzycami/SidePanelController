//
//  ViewController.swift
//  SidePanelController
//
//  Created by 周泽勇 on 15/7/29.
//  Copyright (c) 2015年 周泽勇. All rights reserved.
//

import UIKit

class ViewController: SidePanelController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var leftView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
        leftView.backgroundColor = UIColor.greenColor()
        var rightView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
        rightView.backgroundColor = UIColor.redColor()
        
        var centerView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
        centerView.backgroundColor = UIColor.purpleColor()
        
        self.centerPanel = centerView//self//self.storyboard?.instantiateViewControllerWithIdentifier("CenterView") as? UIViewController
        self.leftPanel = leftView//self.storyboard?.instantiateViewControllerWithIdentifier("LeftPanel") as? UIViewController
        self.rightPanel = rightView//self.storyboard?.instantiateViewControllerWithIdentifier("RightPanel") as? UIViewController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

