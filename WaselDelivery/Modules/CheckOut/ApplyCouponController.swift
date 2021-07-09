//
//  ApplyCouponController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 24/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

class ApplyCouponController: BaseViewController {

    @IBOutlet weak var tableHeaderView: UIView!
    @IBOutlet weak var couponField: BottomBorderField!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var couponsTableView: UITableView!
    weak var delegate: ApplyCouponDelegate?
    
    fileprivate var coupons: [Coupon]?
    fileprivate var currentIndex: Int = -1
    private var disposableBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationView()
        self.navigationView?.titleLabel.text = "Apply Coupon Code"
        couponsTableView.register(CouponCell.nib(), forCellReuseIdentifier: CouponCell.cellIdentifier())
        self.tableHeaderView.isHidden = true
        getCoupons()

        // keyboard notifications
        _ = registerForKeyboardDidShowNotification(tableBottomConstraint, shouldUseTabHeight: false)
        _ = registerForKeyboardWillHideNotification(tableBottomConstraint)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.APPLYCOUPONCODE_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.APPLY_COUPONCODE_TAG)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func applyCoupon(_ sender: Any) {
        
        view.endEditing(true)
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }

        if let coupons_ = coupons, coupons_.count > 0 {
            if currentIndex != -1 {
                let coupon = coupons_[currentIndex]
                couponField.text = coupon.code ?? ""
                let user = Utilities.getUser()
                let requestParams: [String: Any] = ["userId": user?.id ?? 0,
                                                    "couponId": coupon.id ?? 0] as [String: Any]
                
                Utilities.showHUD(to: self.view, "")
                ApiManager.shared.apiService.verifyCoupon(requestParams as [String: AnyObject]).subscribe(onNext: { [weak self](_) in
                    Utilities.hideHUD(from: self?.view)
                    if let delegate_ = self?.delegate {
                        delegate_.couponAppliedWithCoupon(coupon: coupon)
                    }
                    _ = self?.navigationController?.popViewController(animated: true)
                    
                }, onError: { [weak self](error) in
                    
                    Utilities.hideHUD(from: self?.view)
                    if let error_ = error as? ResponseError {
                        if error_.getStatusCodeFromError() == .accessTokenExpire {
                            
                        } else {
                            self?.showAlertWith(message: error_.description(), shouldRespond: false)
                        }
                    } else {
                        Utilities.showToastWithMessage(error.localizedDescription)
                    }
                }).disposed(by: disposableBag)
                
            } else {
                if let couponFieldText = couponField.text {
                    if couponFieldText.count > 0 {
                        showAlertWith(message: "Coupon does not exist.", shouldRespond: false)
                    } else {
                        showAlertWith(message: "Please add coupon.", shouldRespond: false)
                    }
                } else {
                    showAlertWith(message: "Please add coupon.", shouldRespond: false)
                }
            }
        }
    }
    
    @IBAction func couponEditing(_ sender: UITextField) {
        if let coupons_ = coupons {
            if let index_ = coupons_.index(where: { $0.code?.localizedCaseInsensitiveCompare(sender.text ?? "") == .orderedSame }) {
                currentIndex = index_
            } else {
                currentIndex = -1
            }
            
            for index in coupons_.indices {
                if var prevCoupon = coupons?[index] {
                    prevCoupon.isSelected = (currentIndex == index)
                    coupons?[index] = prevCoupon
                }
                couponsTableView.reloadData()
            }
        }
    }
    
// MARK: :- Support Methods
    
    func getCoupons() {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        Utilities.showHUD(to: view, "Loading...")
        _ = ApiManager.shared.apiService.getCoupons().subscribe(onNext: { [weak self](coupons) in
            Utilities.hideHUD(from: self?.view)
            if coupons.count > 0 {
                self?.tableHeaderView.isHidden = false
                self?.coupons = coupons
                self?.couponsTableView.reloadData()
            } else {
                self?.tableHeaderView.isHidden = true
                self?.showAlertWith(message: "No coupons availabale right now.", shouldRespond: true)
            }
        }, onError: { [weak self](error) in
            Utilities.hideHUD(from: self?.view)
            self?.tableHeaderView.isHidden = true
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                    
                } else {
                    Utilities.showToastWithMessage(error_.description())
                }
            }
        })
    }
    
    fileprivate func showAlertWith(message: String, shouldRespond: Bool) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "\(message)", buttonText: nil, cancelButtonText: "Ok")
        responder.setCancelButtonColor(.white)
        responder.setCancelTitleColor(.unSelectedTextColor())
        responder.setCancelButtonBorderColor(.unSelectedTextColor())
        
        if shouldRespond == true {
            responder.addCancelAction({
                DispatchQueue.main.async(execute: { 
                    _ = self.navigationController?.popViewController(animated: true)
                })
            })
        }
        
    }

}

extension ApplyCouponController: UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, CouponCellDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let coupons_ = coupons, coupons_.count > 0 {
            return coupons_.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CouponCell.cellIdentifier()) as? CouponCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        if let coupons = coupons?[indexPath.row] {
            cell.loadCellWithCoupon(coupons)
        }
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        if currentIndex != -1 {
            if var prevCoupon = coupons?[currentIndex] {
                prevCoupon.isSelected = false
                coupons?[currentIndex] = prevCoupon
            }
            couponsTableView.reloadData()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.count == 0 {
            currentIndex = -1
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 10
    }
    
    func selectedCoupon(cell: CouponCell) {
        if currentIndex == -1 {
            guard let couponCell = couponsTableView.indexPath(for: cell) else {
                return
            }
            currentIndex = couponCell.row
            if let coupon = cell.coupon {
                coupons?[currentIndex] = coupon
            }
            couponField.text = coupons?[currentIndex].code ?? ""
        } else {
            guard let couponCell = couponsTableView.indexPath(for: cell) else {
                return
            }
            let nextIndex = couponCell.row
            if var prevCoupon = coupons?[currentIndex] {
                prevCoupon.isSelected = false
                coupons?[currentIndex] = prevCoupon
            }
            if currentIndex == nextIndex {
                currentIndex = -1
                couponField.text = ""
            } else {
                if let coupon = cell.coupon {
                    coupons?[nextIndex] = coupon
                }
                couponField.text = coupons?[nextIndex].code ?? ""
                currentIndex = nextIndex
            }
        }
        couponsTableView.reloadData()
    }
    
}

protocol ApplyCouponDelegate: class {
    func couponAppliedWithCoupon(coupon: Coupon?)
}
