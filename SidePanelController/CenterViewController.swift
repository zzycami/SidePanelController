//
//  CenterViewController.swift
//  SidePanelController
//
//  Created by 周泽勇 on 15/8/6.
//  Copyright (c) 2015年 周泽勇. All rights reserved.
//

import UIKit

class CenterViewController: UIViewController {

    @IBAction func openLeft(sender: AnyObject) {
        //self.sidePanelController?.showLeftPanel(true)
        self.jaSidePanelController.showLeftPanelAnimated(true)
    }
    
    
    @IBAction func openRight(sender: AnyObject) {
        //self.sidePanelController?.showRightPanel(true)
        self.jaSidePanelController.showRightPanelAnimated(true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
