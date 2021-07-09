//
//  HomeViewController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 13/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift
import CoreLocation

class HomeViewController: BaseViewController, LocationSearchProtocol, PageControllerProtocol, HeaderProtocol {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var navView: NavigationView!
    @IBOutlet weak var homeHeader: HomeHeader!
    @IBOutlet weak var locatonButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!
    
    fileprivate var restaurants: [Outlet]?
    fileprivate var currentPage = 1
    fileprivate var isAllRestaurantsFetched: Bool = false
    var disposbleBag = DisposeBag()
    
// MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if Utilities.shouldUseCurrentLocation() == true {
            updateToCurrentLocation()
        } else {
            loadLocation()
        }
        setDelegates()
        locatonButton.isMultipleTouchEnabled = false
        navView.bringSubviewToFront(locatonButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
        if Utilities.shared.enteredForeground == true {
            updateToCurrentLocation()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: NetworkStatusChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentLocation(_:)), name: NSNotification.Name(rawValue: UpdateCurrentLocationNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateBusyStatusUI), name: NSNotification.Name(UpdateOutletBusyBlinkNotification), object: nil)
        
        if let appdelegate = UIApplication.shared.delegate as? AppDelegate {
            appdelegate.getPendingFeedbackOrders()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Utilities.shared.startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NetworkStatusChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateCurrentLocationNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(UpdateOutletBusyBlinkNotification), object: nil)
        Utilities.shared.cancelTimer()
    }
    
    deinit {
        Utilities.log("Home deinit" as AnyObject, type: .trace)
    }
    
// MARK: - Notification Methods
    
    @objc func reachabilityChanged(_ notification: Notification) {
        
        if Utilities.shared.isNetworkReachable() {
            
            if homeHeader.titles == nil {
                
            } else {
                
            }
        }
    }

    @objc func updateCurrentLocation(_ notification: Notification) {
        updateToCurrentLocation()
    }

    @objc func updateBusyStatusUI() {
        Utilities.shared.startTimer()
    }
    
// MARK: - Support Methods
    
    fileprivate func updateToCurrentLocation() {
        Utilities.shared.enteredForeground = false
        LocationManager.shared.delegate = self
        LocationManager.shared.createLocationManager()
    }
    
    fileprivate func loadLocation() {

        if let userLocation = Utilities.getUserLocation() {
            
            let addComponents = userLocation.getLocationAddressComponents()
            locatonButton?.setTitle(addComponents.count > 0 ? addComponents.first : "", for: UIControl.State())
            if userLocation.country == "Bahrain" {
                if infoView != nil {
                    infoView?.removeFromSuperview()
                    infoView = nil
                }
                containerView.isHidden = false
                homeHeader.isHidden = false
                updateAmenities([Amenity]())//clearing prev amenity outlet data
                getAmenitiesList()
            } else {
                if let child = children.last, child is HomePageController {
                    if let childController = child as? HomePageController {
                        childController.loadPageController([])
                    }
                }
                homeHeader.isHidden = true
                showInfoMessageWitType(.outOfBahrain)
                infoView?.center = CGPoint(x: view.center.x, y: view.center.y + 32.0)
            }
        }
    }

    func setDelegates() {
        homeHeader.delegate = self
        if let child = children.last, child is HomePageController {
            if let childController = child as? HomePageController {
                childController.homeDelegate = self
            }
        }
    }
    
// MARK: - API Methods
    
    fileprivate func getAmenitiesList() {
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }

        if Utilities.shared.isNetworkReachable() {
            Utilities.showHUD(to: view, "Loading...")
            _ = ApiManager.shared.apiService.getAmenities().subscribe(onNext: { [weak self](amenities) in
                Utilities.hideHUD(from: self?.view)
                if amenities.count > 0 {
                    Utilities.shared.amenities = amenities
                    self?.updateAmenities(amenities)
                }
            }, onError: { [weak self](error) in
                Utilities.hideHUD(from: self?.view)
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
    }
    
    fileprivate func updateAmenities(_ amenities: [Amenity]) {
        self.homeHeader.titles = amenities
        if let child = children.last, child is HomePageController {
            if let childController = child as? HomePageController {
                if let amenityArray = self.homeHeader.titles {
                    childController.loadPageController(amenityArray)
                }
            }
        }
    }
    
// MARK: - IBButton Actions
    
    @IBAction func showLocationSelectionScreen(_ sender: AnyObject) {
        if let locationSearchViewController = self.storyboard?.instantiateViewController(withIdentifier: "LocationSearchViewController") as? LocationSearchViewController {
            locationSearchViewController.isFromRestaurantsScreen = true
            locationSearchViewController.delegate = self
            
            let navC = UINavigationController(rootViewController: locationSearchViewController)
            navC.isNavigationBarHidden = true
            navigationController?.present(navC, animated: true, completion: nil)
        }
    }
    
// MARK: - LocationSearchProtocol
    
    func reloadOutletsWithNewLocation() {
        DispatchQueue.main.async {            
            if let child = self.children.last, child is HomePageController {
                if let childController = child as? HomePageController {
                    childController.updateCurrentPage(0)
                }
            }
        }
   }
    
    func refreshLocation() {
        loadLocation()
    }
    
// MARK: - HomePageControllerProtocol
    
    func scrollToHeaderIndex(_ atIndex: Int) {
        homeHeader.updateSelectedDepartment(atIndex)
    }

// MARK: - HeaderProtocol
    
    func scrollToViewController(_ atIndex: Int) {
        if let child = children.last, child is HomePageController {
            if let childController = child as? HomePageController {
                childController.updateCurrentPage(atIndex)
            }
        }
    }

}

extension HomeViewController: LocationManagerDelegate {
    
    func locationManager(_ locationManager: LocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopLocationUpdates()
        guard let location: CLLocation = locations.last else {
            return
        }
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        geoCodeLocation(locationManager, location, shouldUseCurrentlocation: true).subscribe(onNext: { (locationDict) in
            self.loadLocation()
            Utilities.updateSearchLocationHistoryWith(locaionObj: locationDict)
        }).disposed(by: disposbleBag)
    }
    
    func locationManager(_ locationManager: LocationManager, didFailWithError error: NSError) { }
    
}
