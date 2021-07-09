//
//  MobileNumberController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 07/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class MobileNumberController: BaseViewController {

    @IBOutlet weak var mobileNumberField: UITextField!
    
    var isFromForgotPassword: Bool? = false
    var registration: Registration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationView()
        mobileNumberField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func proceed(_ sender: Any) {
        let storyBoard = Utilities.getStoryBoard(forName: .main)
        if let mobileVC = storyBoard.instantiateViewController(withIdentifier: "MobileVeificationController") as? MobileVeificationController {
            mobileVC.isFromForgotPassword = true
            self.navigationController?.pushViewController(mobileVC, animated: true)
        }
    }
}
