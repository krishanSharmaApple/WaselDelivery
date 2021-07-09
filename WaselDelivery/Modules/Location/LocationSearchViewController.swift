//
//  LocationSearchViewController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 27/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation
import Unbox
import Upshot

class LocationSearchViewController: BaseViewController {
    
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var locationsTableView: UITableView!
    @IBOutlet weak var locationsSearchField: UITextField!
    @IBOutlet weak var topViewConstraint: NSLayoutConstraint!

    var disposbleBag = DisposeBag()
    var disposeObj: Disposable?
    weak var delegate: LocationSearchProtocol?
    
    var isFromRestaurantsScreen: Bool = false
    fileprivate let googleMapsKey = "AIzaSyB0GD7EyWp7D5kPJZ_AWPbOudMVzrTKDYs"
    fileprivate let baseURLString = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
    fileprivate var dataTask: URLSessionDataTask?
    fileprivate var locationsResults = [LocationSearchResult]()
    fileprivate var locationHistory = [UserLocation]()
    fileprivate var locationCellIdentifier = "LocationResultCell"
    
    // MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationsTableView.tableFooterView = UIView(frame: CGRect.zero)
        locationsTableView.register(UITableViewCell.self, forCellReuseIdentifier: locationCellIdentifier)
        locationsTableView.isHidden = true
        locationsSearchField.becomeFirstResponder()
        
        historyTableView.tableFooterView = UIView(frame: CGRect.zero)
        // keyboard notifications
        _ = registerForKeyboardDidShowNotification(tableBottomConstraint, shouldUseTabHeight: false)
        _ = registerForKeyboardWillHideNotification(tableBottomConstraint)
        
        loadLocationHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topViewConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 20.0 : 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.LOCATION_SEARCH_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.LOCATION_SEARCH_TAG)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - IBActions
    
    @IBAction func useCurrentLocation(_ sender: AnyObject) {
        locationsSearchField.resignFirstResponder()
        LocationManager.shared.delegate = self
        LocationManager.shared.createLocationManager()
        
        let userInfo = BKUserInfo.init()
        let infoDict = ["ChooseLocation": "GPS"]
        userInfo.others = infoDict
        userInfo.build(completionBlock: nil)
    }
    
    @IBAction func goBack(_ sender: AnyObject) {
        locationsSearchField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func textFieldValueChanged(_ sender: UITextField) {
        
        let textCount = sender.text?.count ?? 0
        if textCount >= 3 {
            if Utilities.shared.isNetworkReachable() {
                
                if let disposeObj_ = disposeObj {
                    disposeObj_.dispose()
                }
                disposeObj = LocationManager.shared.fetchAutocompletePlaces(sender.text ?? "").observeOn(MainScheduler.instance).subscribe(onNext: { (locations) in
                        if textCount == 0 {
                            return
                        }
                        self.locationsResults = locations
                        self.locationsTableView.reloadData()
                }, onError: { (error) in
                    if let error_ = error as? ResponseError {
                        Utilities.showToastWithMessage(error_.description())
                    }
                })//.addDisposableTo(disposbleBag)
                
            } else {
                showNoInternetMessage()
            }
        } else {
            self.locationsResults.removeAll()
            self.locationsTableView.reloadData()
        }
    }
    
    // MARK: - Support Methods
    
    func loadLocationHistory() {
        let historyResults = UserDefaults.standard.object(forKey: LocationSearchHistory) as? [[String: Any]]
        if let historyResults_ = historyResults {
            for history in historyResults_ {
                do {
                    let location: UserLocation = try unbox(dictionary: history)
                    self.locationHistory.append(location)
                } catch let error as NSError {
                    Utilities.log(error as AnyObject, type: .trace)
                }
            }
        }
        historyTableView.reloadData()
    }
    
    fileprivate func loadLocation() {
        
        self.locationsSearchField.resignFirstResponder()
        
        self.dismiss(animated: true, completion: {
            self.delegate?.refreshLocation()
            
            if self.isFromRestaurantsScreen == true {
                self.delegate?.reloadOutletsWithNewLocation()
            } else {
                if let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController {
                    let navController = UINavigationController(rootViewController: tabBarController)
                    navController.navigationBar.isHidden = true
                    UIApplication.shared.keyWindow?.rootViewController = navController
                }
            }
        })
    }
    
    fileprivate func uniq<S: Sequence, E: Hashable>(source: S) -> [E] where E==S.Iterator.Element {
        var seen: [E: Bool] = [:]
        return source.filter({ (v) -> Bool in
            return seen.updateValue(true, forKey: v) == nil
        })
    }

}

extension LocationSearchViewController: LocationManagerDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - LocationManager Delegates
    
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
            
            let userInfo = BKUserInfo.init()
            let infoDict = ["ChooseLocation": "GPS"]
            userInfo.others = infoDict
            userInfo.build(completionBlock: nil)

            Utilities.updateSearchLocationHistoryWith(locaionObj: locationDict)
        }).disposed(by: disposbleBag)
    }
    
    func locationManager(_ locationManager: LocationManager, didFailWithError error: NSError) { }
    
    // MARK: - TextField Delegates
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.locationsResults.removeAll()
        self.locationsTableView.reloadData()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - TableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == locationsTableView {
            return 1
        }
        return locationHistory.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableView == historyTableView ? 40.0 : 0.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == historyTableView {
            let aView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 200.0, height: 44.0))
            let label = UILabel(frame: CGRect(x: 20.0, y: 0.0, width: 200.0, height: 44.0))
            label.text = "RECENTLY USED LOCATION"
            label.font = UIFont(name: "Montserrat-Regular", size: 12.0)
            label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            aView.backgroundColor = UIColor.white
            aView.addSubview(label)
            return aView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == locationsTableView {
            self.locationsTableView.isHidden = false
            if self.locationsResults.count == 0 {
                self.locationsTableView.isHidden = true
            }
            return self.locationsResults.count
        }
        
        return locationHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == locationsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: locationCellIdentifier, for: indexPath)
            cell.textLabel?.font = UIFont.montserratLightWithSize(16.0)
            let locationObj = self.locationsResults[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = locationObj.description
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LocationHistoryCell.cellIdentifier()) as? LocationHistoryCell else {
                return UITableViewCell()
            }
            let locationHistory = self.locationHistory[indexPath.row]
            cell.loadCell(withLocation: locationHistory)
            return cell
        }
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets.zero
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == locationsTableView {
            let locationObj = self.locationsResults[(indexPath as NSIndexPath).row]
            
            if Utilities.shared.isNetworkReachable() {
                Utilities.showHUD(to: view, "Loading Location...")
                LocationManager.shared.geocodeWithPlaceId(locationObj.placeId).observeOn(MainScheduler.instance).subscribe(onNext: { (locationDict) in
                    Utilities.hideHUD(from: self.view)
                    Utilities.setUserLocation(locationDict, shouldUseCurrentlocation: false)
                    self.loadLocation()
                    
                    let userInfo = BKUserInfo.init()
                    var infoDict: [String: Any] = ["ChooseLocation": "Manual"]
                    if let locationCity = locationDict["city"] {
                        infoDict["UserCity"] = locationCity
                    }
                    if let locationState = locationDict["state"] {
                        infoDict["UserState"] = locationState
                    }
                    if let locationCountry = locationDict["country"] {
                        infoDict["UserCountry"] = locationCountry
                    }
                    userInfo.others = infoDict
                    userInfo.build(completionBlock: nil)

                    Utilities.updateSearchLocationHistoryWith(locaionObj: locationDict)
                }, onError: { (error) in
                        Utilities.hideHUD(from: self.view)
                        if let error_ = error as? ResponseError {
                            Utilities.showToastWithMessage(error_.description())
                        }
                }).disposed(by: disposbleBag)
            } else {
                showNoInternetMessage()
            }
        } else {
            let location = locationHistory[indexPath.row]
            var userLocation = [String: Any]()
            userLocation["sublocality3"] = location.sublocality3 as Any?
            userLocation["sublocality2"] = location.sublocality2 as Any?
            userLocation["sublocality1"] = location.sublocality1 as Any?
            userLocation["city"] = location.city as Any?
            userLocation["state"] = location.state as Any?
            userLocation["country"] = location.country as Any?
            userLocation["latitude"] = location.latitude as Any?
            userLocation["longitude"] = location.longitude as Any?
            
            Utilities.setUserLocation(userLocation, shouldUseCurrentlocation: false)
            loadLocation()
            
            let userInfo = BKUserInfo.init()
            var infoDict: [String: Any] = ["ChooseLocation": "Manual"]
            if let locationCity = location.city {
                infoDict["UserCity"] = locationCity
            }
            if let locationState = location.state {
                infoDict["UserState"] = locationState
            }
            if let locationCountry = location.country {
                infoDict["UserCountry"] = locationCountry
            }
            userInfo.others = infoDict
            userInfo.build(completionBlock: nil)

            let userDefaults = UserDefaults.standard
            var historyResults = userDefaults.object(forKey: LocationSearchHistory) as? [[String: Any]]
            historyResults?.remove(at: indexPath.row)
            historyResults?.insert(userLocation, at: 0)
            userDefaults.set(historyResults, forKey: LocationSearchHistory)
            userDefaults.synchronize()
        }
    }
}

protocol LocationSearchProtocol: class {
    func reloadOutletsWithNewLocation()
    func refreshLocation()
}
