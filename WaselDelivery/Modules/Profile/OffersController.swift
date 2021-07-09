//
//  OffersController.swift
//  WaselDelivery
//
//  Created by sunanda on 12/21/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OffersController: BaseViewController, UITableViewDelegate, UITableViewDataSource, CouponCellDelegate {

    @IBOutlet weak var offersTableView: UITableView!
    @IBOutlet weak var offersWarningLabel: UILabel!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!
    private var offers: [Coupon]?
    private var currentIndex: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        offersWarningLabel.isHidden = true
        Utilities.shouldHideTabCenterView(tabBarController, true)
        self.addNavigationView()
        self.navigationView?.titleLabel.text = "Offers"
        offersTableView.register(CouponCell.nib(), forCellReuseIdentifier: CouponCell.cellIdentifier())
        getCoupons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.OFFERS_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.OFFERS_SCREEN_TAG)
    }

    override func navigateBack(_ sender: Any?) {
        Utilities.shouldHideTabCenterView(tabBarController, false)
        super.navigateBack(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        Utilities.log("Offers deinit" as AnyObject, type: .trace)
    }
    
// MARK: - API Methods
    
    func getCoupons() {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        Utilities.showHUD(to: view, "Loading...")
        _ = ApiManager.shared.apiService.getCoupons().subscribe(onNext: { [weak self](offers) in
            Utilities.hideHUD(from: self?.view)
            if offers.count > 0 {
                self?.offers = offers
                self?.offersWarningLabel.isHidden = true
                self?.offersTableView.reloadData()
            } else {
                self?.offersWarningLabel.isHidden = false
            }
        }, onError: { [weak self](error) in
            Utilities.hideHUD(from: self?.view)
            self?.offersWarningLabel.isHidden = false
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                    
                } else {
                    Utilities.showToastWithMessage(error_.description())
                }
            }
        })
    }

// MARK: - UITAbleViewDelegate&DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let offers_ = offers, offers_.count > 0 {
            self.offersWarningLabel.isHidden = true
            return offers_.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CouponCell.cellIdentifier(), for: indexPath) as? CouponCell else {
            return UITableViewCell()
        }
        if let coupon = offers?[indexPath.row] {
            cell.isOfferType = true
            cell.delegate = self
            cell.loadCellWithCoupon(coupon)
        }
        
        return cell
    }

    func selectedCoupon(cell: CouponCell) {
        
        if currentIndex == -1 {
            if let index_ = offersTableView.indexPath(for: cell) {
                currentIndex = index_.row
                offers?[currentIndex] = cell.coupon
            }
        } else {
            if var prevCoupon = offers?[currentIndex] {
                prevCoupon.isSelected = false
                offers?[currentIndex] = prevCoupon
            }
            if let couponCell = offersTableView.indexPath(for: cell) {
                currentIndex = couponCell.row
            }
            offers?[currentIndex] = cell.coupon
        }
        offersTableView.reloadData()
    }

}
