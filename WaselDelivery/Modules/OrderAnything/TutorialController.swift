//
//  TutorialController.swift
//  WaselDelivery
//
//  Created by Purpletalk on 03/27/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class TutorialController: BaseViewController {

    @IBOutlet private weak var topLabel: UILabel!
    @IBOutlet private weak var middleLabel: UILabel!
    @IBOutlet private weak var bottomLabel: UILabel!
    @IBOutlet private weak var gotItButton: UIButton!
    @IBOutlet private weak var tutorialImageView: UIImageView!

    var pageIndex: Int = 0
    weak var delegate: PageViewProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utilities.removeTransparentView()

        gotItButton.isHidden = (self.pageIndex != TutorialInfo.count - 1) //Last page
        gotItButton.clipsToBounds = true
        gotItButton.layer.cornerRadius = 4.0
        gotItButton.layer.borderWidth = 1.0
        gotItButton.layer.borderColor = UIColor.themeColor().cgColor
        
        switch pageIndex {
        case 0:
            middleLabel.text = TutorialInfo.Page0.middleLabelText
            bottomLabel.text = TutorialInfo.Page0.bottomLabelText
            tutorialImageView.image = UIImage(named: "tutorial1")
        case 1:
            middleLabel.text = TutorialInfo.Page1.middleLabelText
            bottomLabel.text = TutorialInfo.Page1.bottomLabelText
            tutorialImageView.image = UIImage(named: "tutorial2")
        default:
            middleLabel.text = TutorialInfo.Page2.middleLabelText
            bottomLabel.text = TutorialInfo.Page2.bottomLabelText
            tutorialImageView.image = UIImage(named: "tutorial3")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Utilities.showTransparentView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let delegate_ = delegate {
            delegate_.updateCurrentIndex(pageIndex)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - IBActions
    
    @IBAction func gotItButtonAction(_ sender: Any) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: isTutorialCompleted)
        userDefaults.synchronize()

        self.dismiss(animated: true, completion: nil)
    }
    
}
