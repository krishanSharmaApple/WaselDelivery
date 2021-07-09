//
//  CustomizeController.swift
//  WaselDelivery
//
//  Created by sunanda on 11/25/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class CustomizeController: BaseViewController, PageControllerProtocol, HeaderProtocol {

    @IBOutlet weak var decButton: UIButton!
    @IBOutlet weak var incButton: UIButton!
    @IBOutlet weak var decrementButton: UIButton!
    @IBOutlet weak var incrementButton: UIButton!
    @IBOutlet weak var totalCostLabel: UILabel!
    @IBOutlet weak var totalItemsLabel: UILabel!
    @IBOutlet weak var titleViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var doneView: UIView!
    @IBOutlet weak var headerView: HeaderView!
    var outletItem: OutletItem?
    @IBOutlet weak var itemTitleLabel: UILabel!
    private var customizationItems: [CustomizeCategory]?
    
    private var cartQuantity = 0
    
//    weak var delegate: ReloadParentDelegate?
    weak var delegate: ReloadDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cartQuantity = 0
        
        if let outlet_ = outletItem, let items = outlet_.customisationItems {
            customizationItems = items.map { $0.copy() }
        }
        
        let anyOneCategoryCount = customizationItems?.filter { $0.categoryMode == .anyOne }.count ?? 0
        
        if anyOneCategoryCount > 0 {
            cartQuantity = 1
        }
        
        if let item_ = outletItem, let name_ = item_.name {
            itemTitleLabel.text = name_.trim()
        }

        if let customizationItems_ = customizationItems, customizationItems_.count > 0 {
            let titles = customizationItems_.map { $0.name }.compactMap { $0 }
            headerView.titles = titles
            headerView.delegate = self
        }
        
        if let child = children.last, child is CustomizePageController, let customizationItems_ = customizationItems, customizationItems_.count > 0 {
            if let childController = child as? CustomizePageController {
                childController.loadPageController(customizationItems_)
                childController.pageControlDelegate = self
            }
        }

        doneView.layer.shadowColor = UIColor.gray.cgColor
        doneView.layer.shadowOffset = CGSize(width: 0, height: -1.0)
        doneView.layer.shadowOpacity = 0.2
        doneView.layer.shadowRadius = 1.0
        NotificationCenter.default.addObserver(self, selector: #selector(reloadView(_:)), name: NSNotification.Name(rawValue: UpdateCustomizationNotification), object: nil)
        updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
 
    deinit {
        Utilities.log("customise deinit" as AnyObject, type: .trace)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateCustomizationNotification), object: nil)
    }
    
// MARK: - IBActions
    
    @IBAction func decrement(_ sender: Any) {
        var count = cartQuantity
        count -= 1
        if count >= 0 {
            cartQuantity = count
            updateView()
        }
    }
    
    @IBAction func increment(_ sender: Any) {
        guard Utilities.shared.getTotalItems() + cartQuantity < 99 else {
            Utilities.showToastWithMessage("Items limited to 99.")
            return
        }
        cartQuantity += 1
        updateView()
    }
    
    @IBAction func cancel(_ sender: Any) {
        
        if let delegate_ = delegate {
            delegate_.reloadData()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        
        guard let outletItem_ = outletItem else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        if 0 < cartQuantity {
            copyCustomization(outletItem_: outletItem_)
        } else {
            if outletItem_.customisationItems?.first?.categoryMode != .anyOne {
                addNewItem(outletItem_: outletItem_)
                Utilities.shared.reloadCartView()
            }
        }
        
        if outletItem_.cartQuantity == 0, 0 < cartQuantity {
            outletItem_.cartQuantity = 1
            Utilities.shared.updateCart(outletItem_)
        }

        if let cartView_ = Utilities.shared.cartView {
            cartView_.reloadData()
            Utilities.shared.animateCartCountLabel()
        }
        if let delegate_ = delegate {
            delegate_.reloadData()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
// MARK: - Support Methods
    
// outletItem property is the parent and it's cartItems are the actual endUser items.
// We will check if there exists any children with same customization and decide to append or update the new child.
    
    private func copyCustomization(outletItem_: OutletItem) {
        
        outletItem_.customisationItems = customizationItems
        if let cartItems_ = outletItem_.cartItems {
            let existingCustomizedItems = cartItems_.map { $0.customizedItems() }.compactMap { $0 }
            
            if let customizedItem_ = outletItem_.customizedItems(),
                let customisedItems_ = customizedItem_.customisedItems {
                
                let commonCustomizedTuples = getCommonCustomizations(existingCustomizedItems: existingCustomizedItems, newCustomizedItems: customisedItems_)//common customization existing
                
                if let commonCustomizedTuples_ = commonCustomizedTuples {
                    let existingItem = cartItems_.filter { ($0.cartIndex == commonCustomizedTuples_.index) }.compactMap { $0 }[0]
                    outletItem_.cartQuantity += cartQuantity
                    existingItem.cartQuantity += cartQuantity
                    if let index = outletItem_.cartItems?.index(where: { $0 === existingItem }) {
                        outletItem_.cartItems?.remove(at: index)
                    }
                    outletItem_.cartItems?.insert(existingItem, at: 0)
                    Utilities.shared.clearCustomizationForItem(outletItem_)
                } else {
                    addNewItem(outletItem_: outletItem_)
                }
            }
        } else {
            addNewItem(outletItem_: outletItem_)
        }
    }
    
    private func addNewItem(outletItem_: OutletItem) {
        outletItem_.cartQuantity += cartQuantity
        let item_ = outletItem_.copy()
        item_.cartQuantity = cartQuantity
        if nil != outletItem_.cartItems {
            outletItem_.cartItems?.insert(item_, at: 0)
        } else {
            outletItem_.cartItems = [item_]
        }
        item_.parent = outletItem_
        Utilities.shared.updateCart(item_)//In Utilities we will save parent, so we will check if parent exists in Utilities cart using instance.
        
        if 0 == cartQuantity {
            var cart = Utilities.shared.cart
            if !cart.cartItems.contains(where: { $0 === item_ }) {
                item_.cartIndex = Utilities.shared.cart.cartItems.count + 1
                item_.cartQuantity += 1

                // set cartId while adding first item to cart (if not exist)
                if cart.cartItems.isEmpty && Utilities.shared.cartId == nil {
                    // set UUID string as cart ID
                    Utilities.shared.cartId = UUID().uuidString
                }

                cart.cartItems.append(item_)
                Utilities.shared.cart = cart
            } else {
                if let index = cart.cartItems.index(where: { $0 === item_ }) {
                    cart.cartItems[index] = item_
                    Utilities.shared.cart = cart
                }
            }
        }
        
        Utilities.shared.clearCustomizationForItem(outletItem_)
    }
    
    private func getCommonCustomizations(existingCustomizedItems: [CustomisedItem], newCustomizedItems: [CustomisedTuple] ) -> CustomisedItem? {
        
        let filtered = existingCustomizedItems.filter({ (customisedItem) -> Bool in
            
            if customisedItem.customisedItems?.count == newCustomizedItems.count {
                
                let commonOnes = newCustomizedItems.filter({ (customisedTuple) -> Bool in
                    
                    if let customisedItems_ = customisedItem.customisedItems, customisedItems_.contains(customisedTuple) {
                        return true
                    } else {
                        return false
                    }
                })
                if commonOnes.count == newCustomizedItems.count {
                    return true
                }
                return false
            }
            return false
        })
        if filtered.count > 0 {
            return filtered.first
        }
        return nil
    }
    
    func updateView() {
        
        let dummyItem = outletItem?.copy()
        dummyItem?.customisationItems = customizationItems
        dummyItem?.cartQuantity = cartQuantity
        
        let customizationCost = dummyItem?.getCustomizationCost() ?? 0.0
        let itemCost = dummyItem?.getItemCost() ?? 0.0
        let text = String(format: "%.3f", customizationCost * Double(cartQuantity))
        priceLabel.text = text
        let totalCostText = String(format: "%.3f", itemCost)
        totalCostLabel.text = totalCostText
        totalItemsLabel.text = "\(cartQuantity)"
        
        var itemDefaultSelectionIndex = 0
        if 0 == cartQuantity {
            if outletItem?.customisationItems?.first?.categoryMode != .anyOne {
                itemDefaultSelectionIndex = -1
                let totalCostText = String(format: "%.3f", dummyItem?.price ?? 0.0)
                totalCostLabel.text = totalCostText
                totalItemsLabel.text = "1"
            }
        }
        
        incButton.layer.borderColor = UIColor.black.cgColor
        decButton.layer.borderColor = (cartQuantity > itemDefaultSelectionIndex) ? UIColor.black.cgColor : UIColor.lightGray.cgColor

        incrementButton.isEnabled = true
        decrementButton.isEnabled = (cartQuantity > itemDefaultSelectionIndex) ? true : false
    }
    
// MARK: - NotificationMethods
    
    @objc func reloadView(_ notification: Notification) {
        
        let array_ = customizationItems?.map { $0.items }.compactMap { $0 }.flatMap { $0 }.filter { $0.quantity > 0 }
        if cartQuantity == 0 {
            if let a = array_, a.count > 0 {
                cartQuantity = 1
            }
        } else {
            if let a = array_ {
                if a.count == 0 {
                    cartQuantity = 0
                }
            } else {
                cartQuantity = 0
            }
        }
        updateView()
    }
    
// MARK: - PageControllerProtocol
    
    func scrollToHeaderIndex(_ atIndex: Int) {
        headerView.updateMenuItem(atIndex) 
    }
    
// MARK: - HeaderProtocol
    
    func scrollToViewController(_ atIndex: Int) {
        if let child = children.last, child is CustomizePageController {
            if let childController = child as? CustomizePageController {
                childController.updateCurrentPage(atIndex)
            }
        }
    }
    
}
