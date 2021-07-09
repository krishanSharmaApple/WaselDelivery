//
//  SplashViewController.swift
//  WaselDelivery
//
//  Created by Purpletalk on 9/12/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

class SplashViewController: UIViewController {

    fileprivate var disposableBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let appdelegate = UIApplication.shared.delegate as? AppDelegate {
            appdelegate.fetchAppVersion()
        }
    }
    
}
