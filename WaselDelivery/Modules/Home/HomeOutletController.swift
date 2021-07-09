//
//  HomeOutletController.swift
//  WaselDelivery
//
//  Created by sunanda on 11/3/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift
import Upshot

class HomeOutletController: BaseViewController, MultiLocationPopUpProtocol {

    @IBOutlet weak var contentTableView: UITableView!
    var controllerIndex: NSInteger = 0
    weak var delegate: PageViewProtocol?
    weak var pushDelegate: PageViewDelegte?
    
    fileprivate var disposbleBag = DisposeBag()
    fileprivate var restaurants: [OutletsInfo]?
    fileprivate var disposeObj: Disposable?
    fileprivate var shouldFetchOutlets: Bool = true
    fileprivate let batchCount = 20
    fileprivate let OutletEmptyCellIdentifier = "OutletEmptyCellIdentifier"

    var amenity: Amenity!
    var refreshControl: UIRefreshControl!
    fileprivate var selectedOutletInformation: OutletsInfo?
    fileprivate var multiLocationPopUpViewController: MultiLocationPopUpViewController?
    var oldTimeZoneAbbreviation = TimeZone.current.identifier

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshDetails(_:)), name: UIApplication.significantTimeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppOpenCloseStateUI), name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)

        createInfoView(.emptyOutlets)
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refreshOutlets(_:)), for: .valueChanged)
        contentTableView.addSubview(refreshControl)
        
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: view)
            }
        }
        
        multiLocationPopUpViewController = MultiLocationPopUpViewController(nibName: "MultiLocationPopUpViewController", bundle: .main)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadOutletsContent), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(removeMultiLocationPopUpOnGpsLocation), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAmenityDetails(_:)), name: NSNotification.Name(rawValue: DeepLinkCategoryNotification), object: nil)
   }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utilities.showTransparentView()
        reloadOutletsContent()
        Utilities.shouldHideTabCenterView(tabBarController, false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.HOME_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.HOME_SCREEN_TAG)

        let params = ["CategoryName": amenity?.name ?? "", "CategoryID": amenity?.id ?? "0"]
        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CHOOSE_CATEGORY_EVENT, params: params)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.CATEGORY_SELECTION_TAG)
        self.sendUserDetailsToUpshot()
        
//        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, false == appDelegate.isForceUpdateAlertDisplayed {
            delegate?.updateCurrentIndex(controllerIndex)
            if restaurants == nil {
                getOutletsForPageWithIndex(0, isSilentCall: false)
            } else {
                contentTableView.reloadData()
            }
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let disposeObj_ = disposeObj {
            disposeObj_.dispose()
        }
        if let lastVisibleView = UIApplication.shared.windows.last {
            Utilities.hideHUD(from: lastVisibleView)
        }
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
    }
    
    deinit {
        Utilities.log("deinit home outlet" as AnyObject, type: .trace)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DeepLinkCategoryNotification), object: nil)
    }
    
// MARK: - Upshot methods
    
    func sendUserDetailsToUpshot() {
        let userInfo = BKUserInfo.init()
        var infoDict =  [String: Any]()
        if Utilities.isUserLoggedIn() {
            guard let user = Utilities.getUser() else {
                return
            }
            if let email = user.email {
                userInfo.email = email
            }
            
            if let userName = user.name {
                userInfo.userName = userName
            }
            if let mobileNumber = user.mobile {
                userInfo.phone = mobileNumber
            }
            if let userId = user.id {
                infoDict["UserId"] = userId
                let externalId = BKExternalId.init()
                externalId.appuID = userId
                userInfo.externalId = externalId
            }
            infoDict["IsGuestUser"] = "No"
        } else {
            infoDict["IsGuestUser"] = "Yes"
        }
        userInfo.others = infoDict
        userInfo.build(completionBlock: nil)
    }
    
// MARK: - Notification Refresh methods

    @objc private func refreshDetails(_ notification: Notification) {
        if let outLetsCount = restaurants?.count, 0 > outLetsCount {
            getOutletsForPageWithIndex(outLetsCount, isSilentCall: true)
        } else {
            getOutletsForPageWithIndex(0, isSilentCall: true)
        }
    }
    
    @objc private func updateAppOpenCloseStateUI() {
        Utilities.showTransparentView()
    }
    
    @objc private func refreshAmenityDetails(_ notification: Notification) {
        // Navigating to specific category(Food, Electronics,etc)
        if let amenityId = notification.object as? String, false == amenityId.isEmpty {
            if let amenityId_ = Int(amenityId) {
                getAmenitiesList() { [weak self] _ in
                    var amenityIndex: Int?
                    for (index, amenity) in (Utilities.shared.amenities ?? []).enumerated() where amenity.id == "\(amenityId_)" {
                        amenityIndex = index
                        break
                    }
                    guard let index = amenityIndex else { return }
                    self?.delegate?.updateCurrentIndex(index) // Electronics
                    self?.delegate?.updateCurrentPage(index)
                    self?.getOutletsForPageWithIndex(0, isSilentCall: false)
                    if let restaurants_ = self?.restaurants, 0 < restaurants_.count {
                        self?.contentTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .none, animated: true)
                    }
                }
            }
        }
    }

// MARK: - API Methods
    
    func getOutletsForPageWithIndex(_ pageStartIndex: Int, isSilentCall: Bool) {
        
        guard Utilities.shared.isNetworkReachable() else {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            showNoInternetMessage()
            return
        }

        if let userLocation = Utilities.getUserLocation() {
            let secondsFromGMT = NSTimeZone.local.secondsFromGMT()
            let requestObj: [String: AnyObject] = [LatitudeKey: userLocation.latitude as AnyObject,
                                                   LongitudeKey: userLocation.longitude as AnyObject,
                                                   AmenityIdKey: amenity.id as AnyObject ,
                                                   PageStartKey: pageStartIndex as AnyObject,
                                                   MaxResultKey: batchCount as AnyObject,
                                                   TimeZoneKey: secondsFromGMT as AnyObject]
            if Utilities.shared.isNetworkReachable() {
                if isSilentCall == false {
                    Utilities.showHUD(to: self.view, "Loading...")
                }
                disposeObj = ApiManager.shared.apiService.getOutlets(requestObj).subscribe(
                    onNext: { [weak self](outlets) in
                        if self?.refreshControl.isRefreshing == true {
                            self?.refreshControl.endRefreshing()
                        }
                        if let lastVisibleView = UIApplication.shared.windows.last {
                            Utilities.hideHUD(from: lastVisibleView)
                        }
                        self?.updateOutletInfo(outlets, pageStartIndex)
                }, onError: { [weak self](error) in
                    if self?.refreshControl.isRefreshing == true {
                        self?.refreshControl.endRefreshing()
                    }
                    if let lastVisibleView = UIApplication.shared.windows.last {
                        Utilities.hideHUD(from: lastVisibleView)
                    }
                    if let error_ = error as? ResponseError {
                        if error_.getStatusCodeFromError() == .accessTokenExpire {
                            
                        } else {
                            Utilities.showToastWithMessage(error_.description())
                        }
                    }
                })
            } else {
                showNoInternetMessage()
            }
        } else {
            Utilities.showToastWithMessage(ResponseError.parseError.description())
        }
    }
    
// MARK: - Support Methods
    
    func updateOutletInfo(_ restaurants_: [OutletsInfo], _ pageStartIndex: Int) {

        if pageStartIndex == 0 {
            self.restaurants = restaurants_
        } else {
            if restaurants_.count == 0 {
                self.shouldFetchOutlets = false
            }
            
            // Adding outletsinfo if outlet not exists in previous set
            var outletsArray = [OutletsInfo]()
            for outletsInfo_ in restaurants_ {
                if let aOutlet_ = outletsInfo_.outlet?.first {
                    var isOutletExist = false
                    if let restaurants_ = self.restaurants {
                        for outlets_ in restaurants_ {
                            if let outlet_ = outlets_.outlet?.first {
                                if aOutlet_.id == outlet_.id {
                                    isOutletExist = true
                                    break
                                }
                            }
                        }
                    }
                    if false == isOutletExist {
                        outletsArray.append(outletsInfo_)
                    }
                }
            }
            self.restaurants?.append(contentsOf: outletsArray)
        }
        self.contentTableView.reloadData()
    }
    
    @objc func refreshOutlets(_ sender: Any?) {
        getAmenitiesList()
    }
    
    fileprivate func getAmenitiesList(completion: ((_ success: Bool) -> Void)? = nil) {
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            completion?(false)
            return
        }
        
        if Utilities.shared.isNetworkReachable() {
            _ = ApiManager.shared.apiService.getAmenities()
                .subscribe(
                    onNext: { [weak self](amenities) in
                        if amenities.count > 0 {
                            if let existingAmenities = Utilities.shared.amenities {
                                if existingAmenities != amenities {
                                    self?.updateAmenities(amenities)
                                }
                            }
                            Utilities.shared.amenities = amenities
                            self?.getOutlets()
                        }
                        completion?(true)
                    }, onError: { error in
                    if let error_ = error as? ResponseError {
                        if error_.getStatusCodeFromError() == .accessTokenExpire {
                            
                        } else {
                            Utilities.showToastWithMessage(error_.description())
                        }
                        completion?(false)
                    }
                })
        } else {
            showNoInternetMessage()
        }
    }
    
    func getOutlets() {
        shouldFetchOutlets = true
        getOutletsForPageWithIndex(0, isSilentCall: true)
    }
    
    fileprivate func updateAmenities(_ amenities: [Amenity]) {
        // Once amenities are updated, silently refresh outlets
        guard let safeDelegate = self.delegate else { return }
        safeDelegate.reloadAmenities(list: amenities)
        getOutlets()
    }
    
}

extension HomeOutletController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, ClosingInMinUpdateProtocol {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let restaurants_ = restaurants {
            return (restaurants_.count == 0 ) ? 1 : restaurants_.count
        } else {
            return 0
        }
//        return (restaurants != nil) ? (restaurants!.count == 0) ? 1 : restaurants!.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let restaurants_ = restaurants, restaurants_.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: OutletEmptyCellIdentifier, for: indexPath)
            if let infoView_ = infoView {
                cell.addSubview(infoView_)
                infoView?.center = cell.contentView.center
            }
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OutletCell.cellIdentifier(), for: indexPath) as? OutletCell else {
            return UITableViewCell()
        }
        guard let restaurants_ = restaurants else {
            return UITableViewCell()
        }
        cell.loadOutletDetails(restaurants_[indexPath.row], amenity)
        if indexPath.row == restaurants_.count - 1 && shouldFetchOutlets == true {
            getOutletsForPageWithIndex(restaurants_.count, isSilentCall: true)
        }
        cell.closingInMinUpdateDelegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let restaurants_ = restaurants, restaurants_.count == 0 {
            return ScreenHeight - NavigationBarHeight - TabBarHeight - 70.0
        }
        // 12:5 ratio is maintained for outlet image on backend
        // can be done using dynamic cell height and aspect ratio for image, but not done for empty outlet height cell.
//        var partnerLabelHeight = 0.0
//        if let selectedOutlet = restaurants?[indexPath.row], true == selectedOutlet.isPartnerOutLet {
//            partnerLabelHeight = 28.0
//        }
        let height = ((ScreenWidth * 5.0) / 12.0) + 28.0 //28.0 for PartnerLabel
        debugPrint(height)
        return height + 2.0 //4.0 for seperator
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? OutletCell
        if nil == cell {
            return
        }
        if cell?.shoulAllowSelection == false {
            return
        }

        if let selectedOutlet = restaurants?[indexPath.row].outlet?.first {
            if 3 == selectedOutlet.openStatus {//Open
                if let outletsArray = restaurants?[indexPath.row].outlet, 1 < outletsArray.count {
                    // Show Multi location popup
                    if let selectedOutletInformation_ = restaurants?[indexPath.row] {
                        self.selectedOutletInformation = selectedOutletInformation_
                        self.showMultilocationPopUp(selectedOutletInfo: selectedOutletInformation_, shouldShowMultiLocationPopUp: true)
                    }
                } else {
                     if let selectedOutletInformation_ = restaurants?[indexPath.row] {
                        self.pushToDetailsScreen(selectedOutlet: selectedOutlet, outletsInfo_: selectedOutletInformation_)
                    }
                }
            } else {
                let outletStatus = Utilities.isOutletOpen(selectedOutlet)
                var messageString
                    = outletStatus.message
                if 2 == selectedOutlet.openStatus { // Busy
                    messageString = OutletBusyMessage
                }
                Utilities.showToastWithMessage(messageString)
            }
        }
    }
    
    func pushToDetailsScreen(selectedOutlet: Outlet, outletsInfo_: OutletsInfo) {
//        if let aOutletId = selectedOutlet.id {
//            self.loadOutletDetails(outletId: aOutletId, completionHandler: { (isOutletDetailsFetched, outlet_) in
//                if true == isOutletDetailsFetched {
                    if false == selectedOutlet.showVendorMenu { //isPartnerOutLet
                        let controller = OrderAnythingController.instantiateFromStoryBoard(.main)
                        controller.outlet = selectedOutlet
                        controller.hidesBottomBarWhenPushed = true
                        
                        if controller.specialOrder.didEditedOrder() {
                            let popupVC = PopupViewController()
                            let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "When you leave this place cart will be cleared. Do you want to clear?", buttonText: "Cancel", cancelButtonText: "Clear")
                            responder.addCancelAction({
                                DispatchQueue.main.async(execute: {
                                    controller.clearOrder()
                                    controller.isVendorOutLet = true
                                    controller.selectedOutletInformation = outletsInfo_
                                    self.removeMultiLocationPopUp()
                                    self.navigationController?.pushViewController(controller, animated: true)
                                })
                            })
                        } else {
                            controller.isVendorOutLet = true
                            controller.selectedOutletInformation = outletsInfo_
                            self.removeMultiLocationPopUp()
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                        Utilities.shouldHideTabCenterView(self.tabBarController, true)
                    } else {
                        if let restaurants_ = self.restaurants, restaurants_.count > 0 {
                            self.pushDelegate?.pushToDetailsController(selectedOutlet, outletsInfo_: outletsInfo_)
                            self.removeMultiLocationPopUp()
                        }
                    }
//                }
//            })
//        }
    }
    
    func showMultilocationPopUp(selectedOutletInfo: OutletsInfo, shouldShowMultiLocationPopUp: Bool) {
        guard let multiLocationPopUpViewController_ = self.multiLocationPopUpViewController else {
            return
        }
        selectedOutletInformation?.selectedOutletIndex = -1
        multiLocationPopUpViewController_.delegate = self
        multiLocationPopUpViewController_.selectedOutletInformation = self.selectedOutletInformation
        multiLocationPopUpViewController_.modalPresentationStyle = .overCurrentContext
        multiLocationPopUpViewController_.loadData()
        self.tabBarController?.present(multiLocationPopUpViewController_, animated: true, completion: nil)
    }
    
    func removeMultiLocationPopUp() {
        // Remove MultiLocation Popup
        multiLocationPopUpViewController?.dismiss(animated: true, completion: nil)
        multiLocationPopUpViewController?.delegate = nil
    }
    
    // MARK: - ClosingInMinUpdateProtocol

    func updateCloseInMin() {
        let newTimeZoneAbbreviation = TimeZone.current.identifier
        if oldTimeZoneAbbreviation != "" && newTimeZoneAbbreviation != "" && newTimeZoneAbbreviation != oldTimeZoneAbbreviation {
            oldTimeZoneAbbreviation = newTimeZoneAbbreviation
            self.refreshOutlets(nil)
        }
    }
    
    @objc func reloadOutletsContent() {
        contentTableView.reloadData()
    }
    
    @objc func removeMultiLocationPopUpOnGpsLocation() {
        if Utilities.shouldUseCurrentLocation() == true {
            self.removeMultiLocationPopUp()
        }
    }
}

@available(iOS 9.0, *)
extension HomeOutletController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.contentTableView.indexPathForRow(at: CGPoint(x: location.x, y: location.y + self.contentTableView.contentOffset.y)),
            let cell = contentTableView.cellForRow(at: indexPath) else { return nil }
        
        let storyBoard = Utilities.getStoryBoard(forName: .main)
        guard let detailViewController = storyBoard.instantiateViewController(withIdentifier: "OutletDetailsViewController") as? OutletDetailsViewController else { return nil }
        
        if let outlet = self.restaurants?[(indexPath as NSIndexPath).row].outlet?.first {
            detailViewController.outlet = outlet
        }
        detailViewController.loadRestaurantDetails()
        detailViewController.preferredContentSize = CGSize(width: 0.0, height: 0.0)
        detailViewController.isFromSearchScreen = false
        previewingContext.sourceRect = cell.frame
        
        return detailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}

protocol PageViewDelegte: class {
    func pushToDetailsController(_ outlet_: Outlet, outletsInfo_: OutletsInfo)
}

protocol ClosingInMinUpdateProtocol: class {
    func updateCloseInMin()
}
