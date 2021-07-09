//
//  SearchViewController.swift
//  WaselDelivery
//
//  Created by Karthik on 25/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

class SearchViewController: BaseViewController, MultiLocationPopUpProtocol {

    @IBOutlet weak var deleteSearchButton: UIButton!
    @IBOutlet weak var searchResultsTableView: UITableView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchResultsBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchResultsTableTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topViewConstraint: NSLayoutConstraint!

    var searchHistoryArray = [String]()
    var searchResultsArray = [OutletsInfo]()
    var disposableBag = DisposeBag()
    let outletCellIdentifier = "OutletCellIdentifier"
    let EmptySearchCellIdentifier = "EmptySearchCellIdentifier"

    fileprivate var disposeObj: Disposable?
    fileprivate var shouldFetchOutlets: Bool = true
    fileprivate let batchCount = 20
    fileprivate var selectedOutletInformation: OutletsInfo?
    fileprivate var multiLocationPopUpViewController: MultiLocationPopUpViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchResultsTableView.tableFooterView = UIView(frame: CGRect.zero)
        searchResultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: outletCellIdentifier)
        searchResultsTableView.isHidden = true
        searchTableView.register(SearchCategoryCell.nib(), forCellReuseIdentifier: SearchCategoryCell.cellIdentifier())
        
        // keyboard notifications
        _ = registerForKeyboardDidShowNotification(tableBottomConstraint, shouldUseTabHeight: true)
        _ = registerForKeyboardWillHideNotification(tableBottomConstraint)
        _ = registerForKeyboardDidShowNotification(searchResultsBottomConstraint, shouldUseTabHeight: true)
        _ = registerForKeyboardWillHideNotification(searchResultsBottomConstraint)
        createInfoView(.emptySearch)
        multiLocationPopUpViewController = MultiLocationPopUpViewController(nibName: "MultiLocationPopUpViewController", bundle: .main)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utilities.shouldHideTabCenterView(tabBarController, false)
        let userDefaults = UserDefaults.standard
        if let history = userDefaults.object(forKey: ItemsSearchHistory) as? [String] {
            searchHistoryArray.removeAll()
            searchHistoryArray.append(contentsOf: history)
        }
        searchTableView.reloadData()
        if let text = searchField.text, text.count > 0 {
            searchResultsTableView.isHidden = true
            searchField.text = ""
            deleteSearchButton.isHidden = (text.count > 0 ) ? false : true
        }
        Utilities.removeTransparentView()
        
        if true == Utilities.shared.isIphoneX() {
//            navigationHeightConstraint.constant = 88.0
            searchResultsTableTopConstraint.constant = 88.0
            topViewConstraint.constant = 20.0
        } else {
//            navigationHeightConstraint.constant = 64.0
            searchResultsTableTopConstraint.constant = 64.0
            topViewConstraint.constant = 0.0
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Utilities.removeTransparentView()
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.SEARCH_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.SEARCH_SCREEN_TAG)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func textFieldValueChanged(_ sender: UITextField) {
        let textCount = sender.text?.count ?? 0
        deleteSearchButton.isHidden = (textCount > 0) ? false : true
        searchResultsArray.removeAll()
        shouldFetchOutlets = true
        if let text_ = sender.text, text_.count > 0 {
            getSearchResultsForPageWithIndex(0)
        } else {
            searchResultsTableView.isHidden = true
            view.endEditing(true)
        }
    }
    
    func getSearchResultsForPageWithIndex(_ pageStartIndex: Int) {
        
        if let userLocation = Utilities.getUserLocation() {
            
            guard Utilities.shared.isNetworkReachable() else {
                showNoInternetMessage()
                return
            }
            
            let secondsFromGMT = NSTimeZone.local.secondsFromGMT()
            let requestObj: [String: AnyObject] = [LatitudeKey: userLocation.latitude as AnyObject,
                                                   LongitudeKey: userLocation.longitude as AnyObject,
                                                   SearchItemsKey: searchField.text as AnyObject,
                                                   PageStartKey: pageStartIndex as AnyObject,
                                                   MaxResultKey: batchCount as AnyObject,
                                                   TimeZoneKey: secondsFromGMT as AnyObject]

            if let disposeObj_ = disposeObj {
                disposeObj_.dispose()
            }
            
            disposeObj = ApiManager.shared.apiService.searchItem(requestObj).subscribe(
                onNext: { [weak self](outlets) in
                    if outlets.count <= 0 {
                        self?.shouldFetchOutlets = false
                    }
                    if let text_ = self?.searchField.text, text_.count > 0 {
                        self?.searchResultsArray.append(contentsOf: outlets)
                        self?.searchResultsTableView.isHidden = false
                        self?.searchResultsTableView.reloadData()
                    }
                    
                    let params = ["SearchText": self?.searchField.text ?? "", "ItemFound": (outlets.count <= 0) ? "No" : "Yes"]
                    UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SEARCH_EVENT, params: params)
            }, onError: { [weak self](error) in
                // handle error
                let params = ["SearchText": self?.searchField.text ?? "", "ItemFound": "No"]
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.SEARCH_EVENT, params: params)
                Utilities.hideHUD(from: self?.view)
                if let error_ = error as? ResponseError {
                    if error_.getStatusCodeFromError() == .accessTokenExpire {
                        
                    } else {
                        Utilities.showToastWithMessage(error_.description())
                    }
                }
            })
            disposeObj?.disposed(by: disposableBag)
        } else {
            Utilities.showToastWithMessage(ResponseError.parseError.description())
        }
    }
    
// MARK: - IBActions
    
    @IBAction func deleteSearch(_ sender: Any) {
        self.searchResultsArray.removeAll()
        self.searchResultsTableView.reloadData()
        searchResultsTableView.isHidden = true
        searchField.text = ""
        searchField.resignFirstResponder()
        deleteSearchButton.isHidden = true
    }
    
// MARK: - MultiLocationPopUp delegate Methods

    func pushToDetailsScreen(selectedOutlet: Outlet, outletsInfo_: OutletsInfo) {
        let outlet = selectedOutlet
        searchHistoryArray.removeObject(object: searchField.text ?? "")
        searchHistoryArray.insert((searchField.text?.trim()) ?? "", at: 0)
        UserDefaults.standard.set(searchHistoryArray, forKey: ItemsSearchHistory)
        UserDefaults.standard.synchronize()
        
        let outletStatus = Utilities.isOutletOpen(outlet)
//        if let aOutletId = selectedOutlet.id {
//            self.loadOutletDetails(outletId: aOutletId, completionHandler: { (isOutletDetailsFetched, outlet_) in
//                if true == isOutletDetailsFetched {
                    if 3 == selectedOutlet.openStatus {//Open
                        if false == selectedOutlet.showVendorMenu { //isPartnerOutLet
                            let controller = OrderAnythingController.instantiateFromStoryBoard(.main)
                            controller.outlet = outlet
                            controller.hidesBottomBarWhenPushed = true
                            
                            if controller.specialOrder.didEditedOrder() {
                                let popupVC = PopupViewController()
                                let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "When you leave this place cart will be cleared. Do you want to clear?", buttonText: "Cancel", cancelButtonText: "Clear")
                                responder.addCancelAction({
                                    DispatchQueue.main.async(execute: {
                                        controller.clearOrder()
                                        controller.isVendorOutLet = true
                                        controller.isFromSearchScreen = true
                                        controller.selectedOutletInformation = outletsInfo_
                                        self.removeMultiLocationPopUp()
                                        self.navigationController?.pushViewController(controller, animated: true)
                                    })
                                })
                            } else {
                                controller.isVendorOutLet = true
                                controller.isFromSearchScreen = true
                                controller.selectedOutletInformation = outletsInfo_
                                self.removeMultiLocationPopUp()
                                self.navigationController?.pushViewController(controller, animated: true)
                            }
                            Utilities.shouldHideTabCenterView(self.tabBarController, true)
                        } else {
                            self.searchTableView.reloadData()
                            self.searchField.resignFirstResponder()
                            let controller = OutletDetailsViewController.instantiateFromStoryBoard(.main)
                            controller.outlet = outlet
                            controller.selectedOutletInformation = outletsInfo_
                            Utilities.shared.currentOutlet = outlet
                            self.removeMultiLocationPopUp()
                            controller.loadRestaurantDetails { (isRestaurantDetailsFetched, _) in
                                if true == isRestaurantDetailsFetched {
                                    controller.isFromSearchScreen = true
                                    self.navigationController?.pushViewController(controller, animated: true)
                                }
                            }
                        }
                    } else {
                        var messageString = outletStatus.message
                        if 2 == selectedOutlet.openStatus { //Busy
                            messageString = OutletBusyMessage
                        }
                        Utilities.showToastWithMessage(messageString, position: .middle)
                    }
//                }
//            })
//        }
        
//        if 3 == outlet.openStatus {//Open
//            if false == outlet.showVendorMenu { //isPartnerOutLet
//                let controller = OrderAnythingController.instantiateFromStoryBoard(.main)
//                controller.outlet = outlet
//                controller.hidesBottomBarWhenPushed = true
//
//                if (controller.specialOrder.didEditedOrder()) {
//                    let popupVC = PopupViewController()
//                    let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "When you leave this place cart will be cleared. Do you want to clear?", buttonText: "Cancel", cancelButtonText: "Clear")
//                    responder.addCancelAction({
//                        DispatchQueue.main.async(execute: {
//                            controller.clearOrder()
//                            controller.isVendorOutLet = true
//                            controller.isFromSearchScreen = true
//                            controller.selectedOutletInformation = outletsInfo_
//                            self.removeMultiLocationPopUp()
//                            self.navigationController?.pushViewController(controller, animated: true)
//                        })
//                    })
//                }
//                else {
//                    controller.isVendorOutLet = true
//                    controller.isFromSearchScreen = true
//                    controller.selectedOutletInformation = outletsInfo_
//                    self.removeMultiLocationPopUp()
//                    self.navigationController?.pushViewController(controller, animated: true)
//                }
//                Utilities.shouldHideTabCenterView(tabBarController, true)
//            }
//            else {
//                searchTableView.reloadData()
//                searchField.resignFirstResponder()
//                if let storeName = selectedOutlet.name, let storeType = selectedOutlet.id {
//                    let aDict:[String: Any] = ["Category" : selectedOutlet.amenity?.name ?? "", "Store Name": storeName, "Store ID": storeType]//Store type has to update
//                    Utilities.shared.sendWebEngagementEvent(eventName: "Store Selected", valueDict: aDict)
//                }
//                let controller = OutletDetailsViewController.instantiateFromStoryBoard(.main)
//                controller.outlet = outlet
//                controller.selectedOutletInformation = outletsInfo_
//                Utilities.shared.currentOutlet = outlet
//                self.removeMultiLocationPopUp()
//                controller.loadRestaurantDetails { (isRestaurantDetailsFetched) in
//                    if (true == isRestaurantDetailsFetched) {
//                        controller.isFromSearchScreen = true
//                        self.navigationController?.pushViewController(controller, animated: true)
//                    }
//                }
//            }
//        }
//        else {
//            var messageString = outletStatus.message
//            if (2 == selectedOutlet.openStatus) { //Busy
//                messageString = OutletBusyMessage
//            }
//            Utilities.showToastWithMessage(messageString, position: .middle)
//        }
    }
    
    func showMultilocationPopUp(selectedOutletInfo: OutletsInfo, shouldShowMultiLocationPopUp: Bool) {
        selectedOutletInformation?.selectedOutletIndex = -1
        multiLocationPopUpViewController?.delegate = self
        multiLocationPopUpViewController?.selectedOutletInformation = self.selectedOutletInformation
        multiLocationPopUpViewController?.modalPresentationStyle = .overCurrentContext
        if let multiLocationPopUpViewController_ = multiLocationPopUpViewController {
            self.tabBarController?.present(multiLocationPopUpViewController_, animated: true, completion: {
                self.multiLocationPopUpViewController?.loadData()
            })
        }
    }
    
    func removeMultiLocationPopUp() {
        // Remove MultiLocation Popup
        multiLocationPopUpViewController?.dismiss(animated: true, completion: nil)
        multiLocationPopUpViewController?.delegate = nil
    }

}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == searchResultsTableView {
            return 1
        }
        return searchHistoryArray.count > 0 ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == searchResultsTableView {
            return self.searchResultsArray.count == 0 ? 1 : self.searchResultsArray.count
        }
        
        if searchHistoryArray.count > 0 && section == 0 {
            return searchHistoryArray.count > 3 ? 4 : searchHistoryArray.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == searchTableView {
            if searchHistoryArray.count > 0 && section == 0 {
                return "RECENT SEARCHES"
            }
            return "SHOP BY CATEGORY"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView == searchTableView {
            guard let headerView = SearchTableSectionHeaderView.loadFromNib() as? SearchTableSectionHeaderView else {
                return UIView(frame: CGRect.zero)
            }
            headerView.delegate = self
            
            if searchHistoryArray.count > 0 && section == 0 {
                headerView.titleLabel.text = "RECENT SEARCHES"
                headerView.aButton.setTitle("Clear History", for: .normal)
                headerView.aButton.isHidden = false
            } else {
                headerView.titleLabel.text = "SHOP BY CATEGORY"
                headerView.aButton.isHidden = true
            }
            
            return headerView
        }
        
        return UIView(frame: CGRect.zero)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == searchTableView {
            if searchHistoryArray.count > 0 && indexPath.section == 0 {
                return 44.0
            }
            
            let cellHeight: CGFloat = (UIScreen.main.bounds.width - 40) / 3
            let amenitiesCount = CGFloat(Utilities.shared.amenities?.count ?? 0)
            return cellHeight * ceil(amenitiesCount / 3.0)
        }
        
        if searchResultsArray.count == 0 {
            return ScreenHeight - NavigationBarHeight - TabBarHeight
        }
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableView == searchTableView ? 40.0 : 0.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == searchTableView {
            if searchHistoryArray.count > 0 && indexPath.section == 0 {
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchHistoryCell.cellIdentifier()) as? SearchHistoryCell else {
                    return UITableViewCell()
                }
                cell.delegate = self
                cell.tag = indexPath.row
                
                if indexPath.row == 3 {
                    cell.ellipsisImage.isHidden = false

                    cell.showMore()
                } else {
                    cell.ellipsisImage.isHidden = true

                    cell.configureCell(with: searchHistoryArray[indexPath.row])
                }
                return cell
                
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchCategoryCell.cellIdentifier()) as? SearchCategoryCell else {
                    return UITableViewCell()
                }
                cell.categoryCollectionView.reloadData()
                cell.delegate = self
                cell.backgroundColor = UIColor.white
                return cell
            }

        } else {
            if searchResultsArray.count == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: EmptySearchCellIdentifier, for: indexPath)
                if let infoView_ = infoView {
                    cell.addSubview(infoView_)
                    infoView_.infoDescriptionLabel.text = "We couldn't find anything for \"\(searchField.text ?? "")\". Please search with different keyword."
                    infoView_.center = cell.contentView.center
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: outletCellIdentifier, for: indexPath)
                let outlet = self.searchResultsArray[(indexPath as NSIndexPath).row]
                cell.textLabel?.font = UIFont.montserratLightWithSize(16.0)
                if let aOutlet = outlet.outlet?.first {
                    cell.textLabel?.text = Utilities.fetchOutletName(aOutlet).trim()
                } else {
                    cell.textLabel?.text = outlet.location
                }
                if indexPath.row == searchResultsArray.count - 1 && shouldFetchOutlets == true {
                    getSearchResultsForPageWithIndex(searchResultsArray.count)
                }
                return cell
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchTableView {
            if searchHistoryArray.count > 0 && indexPath.row == 3 {
                let storyBoard = Utilities.getStoryBoard(forName: .main)
                if let searchHistoryVC = storyBoard.instantiateViewController(withIdentifier: "SearchHistoryViewController") as? SearchHistoryViewController {
                    searchHistoryVC.searchHistoryArray = searchHistoryArray
                    self.navigationController?.pushViewController(searchHistoryVC, animated: true)
                }
            }
        } else {
            if self.searchResultsArray.count > 0 {
                if let selectedOutlet = self.searchResultsArray[indexPath.row].outlet?.first {
                    self.pushToDetailsScreen(selectedOutlet: selectedOutlet, outletsInfo_: self.searchResultsArray[indexPath.row])
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 35
    }
    
}

extension SearchViewController: SearchHistoryCellDelegate {
    
    func searchHistoryCell(cell: SearchHistoryCell, didSelectClearHistory historyItem: String) {
        let userDefaults = UserDefaults.standard
        searchHistoryArray.remove(at: cell.tag)
        userDefaults.set(searchHistoryArray, forKey: ItemsSearchHistory)
        userDefaults.synchronize()
        searchTableView.reloadData()
    }
    
    func reloadSearch(cell: SearchHistoryCell, didSelectClearHistory historyItem: String) {
        self.searchField.becomeFirstResponder()
        self.searchField.text = historyItem
        self.textFieldValueChanged(self.searchField)
    }

}

extension SearchViewController: SearchCategoryCellDelegate {
    func searchCategoryCell(cell: SearchCategoryCell, didSelect index: Int) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let navController = appDelegate.window?.rootViewController as? UINavigationController {
                if let tabController = navController.viewControllers.last as? TabBarController {
                    if let homeNavController = tabController.viewControllers?.first as? UINavigationController {
                        homeNavController.popToRootViewController(animated: false)
                        if let homeVC = homeNavController.viewControllers.first as? HomeViewController {
                            tabController.selectedIndex = 0
                            homeVC.scrollToViewController(index)
                        }
                    }
                }
            }
        }
    }
}

extension SearchViewController: SearchTableSectionHeaderViewDelegate {
    func didSelectClearButton(cell: SearchTableSectionHeaderView) {
        
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Are you sure you want to clear search history?", buttonText: "Cancel", cancelButtonText: "Clear")
        responder.addCancelAction({
            DispatchQueue.main.async(execute: {
                // remove history
                UserDefaults.standard.removeObject(forKey: ItemsSearchHistory)
                UserDefaults.standard.synchronize()
                self.searchHistoryArray.removeAll()
                
                self.searchTableView.beginUpdates()
                self.searchTableView.deleteSections(NSIndexSet(index: 0) as IndexSet, with: .top)
                self.searchTableView.endUpdates()

            })
        })
    }
}
