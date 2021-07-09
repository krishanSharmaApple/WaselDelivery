//
//  HandlingFeeInfoViewController.swift
//  WaselDelivery
//
//  Created by ramchandra on 26/04/19.
//  Copyright © 2019 [x]cube Labs. All rights reserved.
//

import UIKit

///
class HandlingFeeInfoViewController: UIViewController {

    // MARK: - Variables / Properties
    ///

    // MARK: - Outlets
    ///

    // MARK: - View Lifecycle Methods
    ///
    override func viewDidLoad() {
        super.viewDidLoad()

        // configure view
        configureUI()
    }

    // MARK: - UI Configuration Methods
    ///
    private func configureUI() {}

    // MARK: - Action Methods
    ///
    @IBAction func dismiss(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Helper Methods
    ///
}
