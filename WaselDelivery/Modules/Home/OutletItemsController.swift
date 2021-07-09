//
//  OutletItemsController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 16/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class OutletItemsController: UIViewController, IndicatorInfoProvider {

    @IBOutlet weak var itemTableView: UITableView!
    
    var itemInfo: IndicatorInfo = "View"
    var foodItemCategory: OutletItemCategory?
    var bubbleOffset: CGFloat = 130.0
    
// MARK: - View Life Cycle
    
    init(itemInfo: IndicatorInfo, foodItemCategory_: OutletItemCategory?) {
        self.itemInfo = itemInfo
        self.foodItemCategory = foodItemCategory_
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppOpenCloseStateUI), name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshProductDetails(_:)), name: NSNotification.Name(rawValue: DeepLinkProductNotification), object: nil)

        itemTableView.estimatedRowHeight = 97.0
        itemTableView.rowHeight = UITableView.automaticDimension
        itemTableView.register(UINib(nibName: "ItemSectionView", bundle: nil),
                                  forHeaderFooterViewReuseIdentifier: "ItemSectionView")
        itemTableView.register(OutletItemCell.nib(), forCellReuseIdentifier: OutletItemCell.cellIdentifier())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if foodItemCategory != nil {
            itemTableView.reloadData()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(enableScrolling(_:)), name: NSNotification.Name(rawValue: EnableItemTableViewScrollNotification), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        changeScollEnable(!Utilities.shared.isOpen)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: EnableItemTableViewScrollNotification), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        Utilities.log("outletitem deinit" as AnyObject, type: .trace)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
    }
    
// MARK: - Deep link methods
    
    @objc private func refreshProductDetails(_ notification: Notification) {
        if let foodItemCategory_ = foodItemCategory, let categories_ =  foodItemCategory_.categories {
            for category in categories_ {
                if let items = category.foodItems {
                    if let productIdString = notification.object as? String, false == productIdString.isEmpty {
                        if let productId_ = Int(productIdString) {
                            NSLog("productId_:%ld", productId_)
                            for outletItem in items {
                                if let outletItemId = outletItem.id {
                                    if productId_ == outletItemId {
                                        self.incrementOutletItemCount(outletItem: outletItem)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// this method is also used in OrderDetailsPagerController
    /// for Upshot Deeplinking functionality
    /// This method used to increase cart quantity and to update the cart UI
    ///
    /// - Parameter outletItem: Product object
    func incrementOutletItemCount(outletItem: OutletItem) {
        
        guard Utilities.isWaselDeliveryOpen() else {
            return
        }
        
        guard Utilities.shared.getTotalItems() < 99 else {
            Utilities.showToastWithMessage("Items limited to 99.")
            return
        }
        
        if let customisationItems_ = outletItem.customisationItems, customisationItems_.count > 0 {
            self.showCustomiseView(forItem: outletItem)
            return
        }
        
        outletItem.cartQuantity += 1
        Utilities.shared.updateCart(outletItem)
        self.reloadData()
    }

    /// Search for indexPath of the given outlet item and
    /// scroll tableview to bring the item in top of the list.
    /// This method was used for upshot deeplinking and calling from OrderDetailsPagerController
    ///
    /// - Parameter item: OutletItem
    func scrollTo(item: OutletItem) {
        var section: Int = -1
        var row: Int = -1
        catLoop: for (index, subCat) in (foodItemCategory?.categories ?? []).enumerated() {
            for (itemIndex, foodItem) in (subCat.foodItems ?? []).enumerated() where (foodItem.id ?? -1) == (item.id ?? -1) {
                subCat.isExpanded = true
                section = index
                row = itemIndex
                break catLoop
            }
        }
        reloadData()
        if section >= 0 && row >= 0 {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.itemTableView.scrollToRow(at: IndexPath(row: row, section: section), at: .top, animated: true)
            }
        }
    }

// MARK: - SupportMethods
    
    func changeScollEnable(_ enable: Bool) {
        itemTableView.isScrollEnabled = enable
        itemTableView.showsVerticalScrollIndicator = enable
    }
    
    func startBubbleAnimation(indexPath: IndexPath) {
        guard let cell = itemTableView.cellForRow(at: indexPath) as? OutletItemCell,
            cell.outletItem.customisationItems?.isEmpty ?? true,
            let countLabel = cell.countLabel else { return }
        
        guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let appdelegateWindow_ = appdelegate.window else {
            return
        }
        let countRect = appdelegateWindow_.convert(countLabel.frame, from: countLabel.superview)
        
        let duplicateLabel = UILabel(frame: countRect)
        duplicateLabel.text = countLabel.text
        duplicateLabel.textColor = countLabel.textColor
        duplicateLabel.backgroundColor = .themeColor()
        duplicateLabel.clipsToBounds = true
        duplicateLabel.textAlignment = .center
        duplicateLabel.layer.cornerRadius = countRect.size.width / 2.0
        appdelegateWindow_.addSubview(duplicateLabel)
        UIView.animate(withDuration: 0.5, animations: {
            duplicateLabel.center = CGPoint(x: appdelegateWindow_.bounds.size.width / 2.0, y: appdelegateWindow_.bounds.size.height - 44.0) //self.bubbleOffset
        }, completion: { (completed) in
            guard completed else { return }
            duplicateLabel.removeFromSuperview()
            Utilities.shared.animateCartCountLabel()
        })
    }
    
// MARK: - Notification Methods
    
    @objc func enableScrolling(_ notification: Notification) {
        changeScollEnable(!Utilities.shared.isOpen)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
    
    @objc private func updateAppOpenCloseStateUI() {
        Utilities.showTransparentView()
        UIView.performWithoutAnimation {
            self.itemTableView.reloadData()
        }
    }

}

extension OutletItemsController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, CustomizeDelegate, ReloadSectionProtocol, ReloadDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var secCount = 0
        if let foodItemCategory_ = foodItemCategory, let categories_ = foodItemCategory_.categories {
            secCount = categories_.count
        }
        return secCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        if let foodItemCategory_ = foodItemCategory, let categories_ =  foodItemCategory_.categories {
            let category = categories_[section]
            // set expanted to true if only one section presents
            rowCount = ((category.isExpanded ?? false) == true) ? (category.foodItems?.count ?? 0) : 0
        }
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if let foodItemCategory_ = foodItemCategory, let categories_ =  foodItemCategory_.categories {
            
            var titleHeight = Utilities.getSizeForText(text: foodItemCategory_.name ?? "", font: .montserratSemiBoldWithSize(14.0), fixedWidth: ScreenWidth - 40.0).height
            titleHeight = (titleHeight > 45.0 ) ? titleHeight : 50.0
            let height: CGFloat = (foodItemCategory_.name == "Recommended" || categories_.count <= 1) ? 0.0 : titleHeight
            return height
        }
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0.0
        if let foodItem =  getItemFrom(subCategoryIndex: indexPath.section, itemIndex: indexPath.row) {
            if let name_ = foodItem.name, name_.length > 0 {
                let height_ = Utilities.getSizeForText(text: name_.trim(), font: .montserratLightWithSize(14.0), fixedWidth: ScreenWidth - 252.0).height
                height = (height_ >= 23.0) ? height_ - 23.0 : 0.0
            }
            if let des_ = foodItem.itemDescription, des_.length > 0 {
                let h = Utilities.getSizeForText(text: des_.trim(), font: .montserratLightWithSize(10.0), fixedWidth: ScreenWidth - 131.0).height
                height += h
            }
            height = 52 + height - 80//52 is current view height containing labels without text and 80 is the minimum height for view with labels
            if height > 0 {
                height += 97.0
            } else {
                height = 97.0
            }
            // cell height except labels
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if foodItemCategory?.name ?? "" == "Recommended" {
            return nil
        }
        guard let aView = itemTableView.dequeueReusableHeaderFooterView(withIdentifier: "ItemSectionView") as? ItemSectionView else {
            return nil
        }
        guard let item  = foodItemCategory?.categories?[section] else {
            return nil
        }
        aView.delegate = self
        aView.tintColor = UIColor.clear
        aView.loadView(item, index: section)
        return aView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard Utilities.isWaselDeliveryOpen() else { return }
        if let cell = tableView.cellForRow(at: indexPath) as? OutletItemCell {
            cell.incrementOutletItemCount()
            
            startBubbleAnimation(indexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OutletItemCell.cellIdentifier(), for: indexPath) as? OutletItemCell else {
            return UITableViewCell()
        }
        guard let category  = foodItemCategory?.categories?[(indexPath as NSIndexPath).section] else {
            return UITableViewCell()
        }
        guard let foodItem =  category.foodItems?[(indexPath as NSIndexPath).row] else {
            return UITableViewCell()
        }
        cell.customiseDelegate = self
        cell.isCustomized = false
        cell.reloadDelegate = self
        cell.loadCellWithData(foodItem)
        cell.isUserInteractionEnabled = Utilities.isWaselDeliveryOpen()
        cell.selectedBackgroundView = UIView(frame: CGRect.zero)
        cell.selectedBackgroundView?.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        return cell
    }
    
    func getCellSize(_ title: String, forIndexPath indexpath: IndexPath) -> CGSize {
        
        let font = UIFont.montserratLightWithSize(10.0)
        
        let cellRect = (title as NSString).boundingRect(with: CGSize(width: ScreenWidth - 115.0, height: CGFloat(Float.greatestFiniteMagnitude)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return cellRect.size
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offsetY = scrollView.contentOffset.y
        let isMovingUp = (scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0) ? true : false
        if offsetY < 0.0 && isMovingUp {
            bubbleOffset = 175.0
            Utilities.shared.isOpen = true
            changeScollEnable(!Utilities.shared.isOpen)
            NotificationCenter.default.post(name: Notification.Name(rawValue: EnableRestaurantTableViewScrollNotification), object: nil, userInfo: nil)
        } else {
            bubbleOffset = 130.0
        }
    }
    
    fileprivate func getItemFrom(subCategoryIndex: Int, itemIndex: Int) -> OutletItem? {
        if let categories_ = foodItemCategory?.categories, subCategoryIndex < categories_.count {
            let category  = categories_[subCategoryIndex]
            if let foodItems_ = category.foodItems, itemIndex < foodItems_.count {
                let foodItem_ =  foodItems_[itemIndex]
                return foodItem_
            }
        }
        return nil
    }

    // MARK: - CustomizeDelegate
    
    func showCustomiseView(forItem item: OutletItem) {
        
        let storyBoard = Utilities.getStoryBoard(forName: .home)
        guard let customiseController = storyBoard.instantiateViewController(withIdentifier: "CustomizeController") as? CustomizeController else {
            return
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        guard let rootNavController = appDelegate.window?.rootViewController as? UINavigationController else {
            return
        }

        customiseController.delegate = self
        customiseController.outletItem = item
        
        let navC = UINavigationController(rootViewController: customiseController)
        navC.providesPresentationContextTransitionStyle = true
        navC.modalPresentationStyle = .overCurrentContext
        navC.definesPresentationContext = true
        navC.isNavigationBarHidden = true
        
        if let tabC = rootNavController.viewControllers.first as? TabBarController {
            tabC.present(navC, animated: true, completion: nil)
        }
    }
    
    func showImagePopUpView(forItem item: OutletItem) {
        if let imageUrlString = item.imageUrl, false == imageUrlString.isEmpty {
            let photoDetailViewController = PhotoDetailViewController.init(nibName: "PhotoDetailViewController", bundle: nil)
            photoDetailViewController.outletItem = item
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let navController = appDelegate?.window?.rootViewController as? UINavigationController
            photoDetailViewController.modalTransitionStyle = .crossDissolve
            navController?.present(photoDetailViewController, animated: true, completion: nil)
        }
    }
    
// MARK: - ReloadParentDelegate
    
    func reloadData() {
        DispatchQueue.main.async {
            self.itemTableView.reloadData()
        }
    }
    
// MARK: - ReloadSectionProtocol
    
    func reloadSectionAt(index: Int) {
        
        let aIndex = index - 1
        let indexSet = NSMutableIndexSet()
        indexSet.add(aIndex)
        if let categories_ = foodItemCategory?.categories {
            if let isExpanded_ = categories_[aIndex].isExpanded {
                categories_[aIndex].isExpanded = !isExpanded_
            }
        }
        itemTableView.reloadSections(indexSet as IndexSet, with: .automatic)
    }
    
}

extension OutletItemsController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let tag_ = collectionView.tag
        let outletItem_ = getItemFrom(subCategoryIndex: tag_/10, itemIndex: tag_%10)
        if let customizations_ = outletItem_?.cartItems {
            return customizations_.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.cellIdentifier(), for: indexPath) as? ItemCell else {
            return UICollectionViewCell()
        }
        let tag_ = collectionView.tag
        if let outletItem_ = getItemFrom(subCategoryIndex: tag_/10, itemIndex: tag_%10) {
            if let cartItems_ = outletItem_.cartItems {
                cell.loadItemAtIndex(item: cartItems_[indexPath.item])
                cell.reloadDelegate = self
                return cell
            } else {
                return UICollectionViewCell()
            }
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tag_ = collectionView.tag
        if let outletItem_ = getItemFrom(subCategoryIndex: tag_/10, itemIndex: tag_%10) {
            if let cartItems_ = outletItem_.cartItems {
                let size_ = CGSize(width: ScreenWidth - 34.0, height: Utilities.getCustomizationStringHeightFor(item: cartItems_[indexPath.item]))
                return size_
            } else {
                return CGSize.zero
            }
        } else {
            return CGSize.zero
        }
    }
    
}
