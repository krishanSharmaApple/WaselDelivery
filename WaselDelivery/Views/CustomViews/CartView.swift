//
//  CartView.swift
//  WaselDelivery
//
//  Created by sunanda on 11/14/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class CartView: UIView {

    @IBOutlet weak var totalCartItemsLabel: UILabel!
    @IBOutlet weak var totalCostLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view: UIView = loadViewFromNib()
        view.frame = bounds
        addSubview(view)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)
        
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        self.backgroundColor = UIColor(red: (85.0/255.0), green: (190.0/255.0), blue: (109.0/255.0), alpha: isAppOpen ? 1.0
            : 0.5)
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let nib = UINib(nibName: "CartView", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView ?? UIView()
        return view
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if false == Utilities.isWaselDeliveryOpen() {
            return
        }
        let checkOutSB = Utilities.getStoryBoard(forName: .checkOut)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        guard let rootNavController = appDelegate.window?.rootViewController as? UINavigationController else {
            return
        }

        let totalCost = Utilities.shared.getTotalCost()
        if let currentOutlet = Utilities.shared.currentOutlet, currentOutlet.showVendorMenu ?? false, totalCost < (currentOutlet.minimumOrderValue ?? 0) {
            Utilities.showToastWithMessage("Minimum order value should be \(currentOutlet.minimumOrderValue ?? 0) BD")
            return
        }

        if let tabC = rootNavController.viewControllers.first as? TabBarController {
            guard let cartController = checkOutSB.instantiateViewController(withIdentifier: "CartViewController") as? CartViewController else {
                return
            }
            let cartNavController = UINavigationController(rootViewController: cartController)
            cartNavController.isNavigationBarHidden = true
            tabC.present(cartNavController, animated: true, completion: nil)
        }
    }

    func reloadData() {
        totalCartItemsLabel.text = "\(Utilities.shared.getTotalItems())"
        let totalCost = Utilities.shared.getTotalCost()
        let text = String(format: "%.3f", totalCost)
        totalCostLabel.text = text

        DispatchQueue.main.async {
            if let currentOutlet = Utilities.shared.currentOutlet, currentOutlet.showVendorMenu ?? false, totalCost < (currentOutlet.minimumOrderValue ?? 0) {
                self.containerView.backgroundColor = UIColor.lightGray
            } else {
                let isAppOpen = Utilities.isWaselDeliveryOpen()
                self.containerView.backgroundColor = UIColor(red: 85 / 255, green: 190 / 255, blue: 109 / 255, alpha: isAppOpen ? 1 : 0.5)
            }
        }
    }
}
