//
//  ViewController.swift
//  SidePanelController
//
//  Created by 周泽勇 on 15/7/29.
//  Copyright (c) 2015年 周泽勇. All rights reserved.
//

import UIKit

class ViewController: JASidePanelController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.centerPanel = self.storyboard?.instantiateViewControllerWithIdentifier("CenterView") as? UIViewController
        self.leftPanel = self.storyboard?.instantiateViewControllerWithIdentifier("LeftPanel") as? UIViewController
        self.rightPanel = self.storyboard?.instantiateViewControllerWithIdentifier("RightPanel") as? UIViewController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

