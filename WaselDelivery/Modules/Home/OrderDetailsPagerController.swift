//
//  OrderDetailsPagerController.swift
//  WaselDelivery
//
//  Created by sunanda on 12/26/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class OrderDetailsPagerController: ButtonBarPagerTabStripViewController {

    var outletCategories: [OutletItemCategory]? {
        didSet {
           reloadPagerTabStripView()
        }
    }

    // MARK: - Variables used in upshot deeplinking
    /// The following properties are set from OutletDetailController

    /// Holds the OutletItem to increment the cart item count
    /// and to scroll the product list to bring the particular product to top.
    var outletItem: OutletItem?
    /// Holds the index of the OutletItemsController
    /// used to display the particular category
    var defaultControllerIndex = -1 {
        didSet {
            guard defaultControllerIndex >= 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if self.defaultControllerIndex < self.viewControllers.count {
                    if let vc = self.viewControllers[self.defaultControllerIndex] as? OutletItemsController {
                        if let outletItem = self.outletItem {
                            vc.incrementOutletItemCount(outletItem: outletItem)
                            vc.scrollTo(item: outletItem)
                        }
                        self.moveTo(viewController: vc, animated: false)
                    }
                }
                if self.canMoveTo(index: self.defaultControllerIndex) {
                    self.moveToViewController(at: self.defaultControllerIndex, animated: false)
                }
                self.defaultControllerIndex = -1
            }
        }
    }

    override func viewDidLoad() {

        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.selectedBarBackgroundColor = .white
        settings.style.buttonBarItemFont = .montserratLightWithSize(14.0)
        settings.style.selectedBarHeight = 0.0
        settings.style.buttonBarMinimumLineSpacing = 20
        settings.style.buttonBarItemTitleColor = .unSelectedTextColor()
//        settings.style.buttonBarSelectedItemTitleColor = .themeColor()
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
        settings.style.buttonBarLeftContentInset = 15
        settings.style.buttonBarRightContentInset = 15
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        pagerBehaviour = .progressive(skipIntermediateViewControllers: true, elasticIndicatorLimit: true)
        
        changeCurrentIndexProgressive = {(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .unSelectedTextColor()
            oldCell?.label.font = .montserratLightWithSize(14.0)
            newCell?.label.textColor = .themeColor()
            newCell?.label.font = .montserratSemiBoldWithSize(14.0)
        }
        super.viewDidLoad()
        self.containerView.bounces = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return categoryControllers()
    }
    
    func categoryControllers() -> [UIViewController] {
        if let outletCategories_ = outletCategories {
            return outletCategories_.map({ outletItemCategory -> OutletItemsController in
                return outItemsController(itemInfo: IndicatorInfo(title: outletItemCategory.name ?? ""), foodItemCategory: outletItemCategory)
            })
        } else {
            return [outItemsController(itemInfo: IndicatorInfo(title: ""), foodItemCategory: nil)]
        }
    }

    private func outItemsController(itemInfo: IndicatorInfo, foodItemCategory: OutletItemCategory?) -> OutletItemsController {
        let storyBoard = Utilities.getStoryBoard(forName: .main)
        guard let itemController = storyBoard.instantiateViewController(withIdentifier: "OutletItemsController") as? OutletItemsController else {
            return OutletItemsController(itemInfo: IndicatorInfo(title: ""), foodItemCategory_: nil)
        }
        itemController.itemInfo = itemInfo
        itemController.foodItemCategory = foodItemCategory
        return itemController
    }
}
