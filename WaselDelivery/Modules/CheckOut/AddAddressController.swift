//
//  AddAddressController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 14/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import Unbox
import GoogleMaps

class AddAddressController: BaseViewController, GMSMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var confirmLocationButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var locationsTableView: UITableView!
    @IBOutlet weak var mapSwitchingButton: UIButton!

    var disposbleBag = DisposeBag()
    var disposeObj: Disposable?
    var address: Address?
    var isFromProfile = false
    var isFromOrderAnyThing = false
    var isMapLoaded = false
    let bahrainCoordinates = CLLocationCoordinate2DMake(26.0667, 50.5577)
    var bahrainBounds = GMSCoordinateBounds(coordinate: CLLocationCoordinate2D(latitude: 26.357009, longitude: 50.731927), coordinate: CLLocationCoordinate2D(latitude: 25.740200, longitude: 50.325213))
    weak var pickupDelegate: UpdatePickupLocation?

    fileprivate var locationCellIdentifier = "LocationResultCell"
    fileprivate var locationsResults = [LocationSearchResult]()
    fileprivate var currentPlaceID: String?
    
// MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationView()
        var title = "Add Address"
        if isFromOrderAnyThing == true {
            title = "Pickup Location"
        }
        navigationView?.titleLabel.text = title
        
        locationsTableView.tableFooterView = UIView(frame: CGRect.zero)
        locationsTableView.register(UITableViewCell.self, forCellReuseIdentifier: locationCellIdentifier)
        locationsTableView.isHidden = true

        mapView.delegate = self
        mapView.setMinZoom(9.8, maxZoom: 100)
        mapView.settings.consumesGesturesInView = false
        mapView.isMyLocationEnabled = true
        
        if let userLocation = Utilities.getUserLocation() {
            let coordinate = CLLocationCoordinate2DMake(userLocation.latitude ?? 0.0, userLocation.longitude ?? 0.0)
            if self.isCoordinateInsideBahrain(coordinate, shouldShowToast: false) {
                goToLocation(coordinate: coordinate)
            } else {
                goToLocation(coordinate: bahrainCoordinates)
            }
        }
        
        let imageView = UIImageView(image: UIImage(named: "location"))
        imageView.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 19.0)
        imageView.contentMode = .center
        searchField.leftViewMode = .always
        searchField.leftView = imageView
        
        searchField.layer.shadowColor = UIColor.red.cgColor
        searchField.layer.shadowOffset = CGSize(width: 0.0, height: 10.0)
        searchField.layer.shadowOpacity = 0.7
        searchField.layer.shadowRadius = 10.0
        
        // keyboard notifications
        _ = registerForKeyboardDidShowNotification(tableBottomConstraint, shouldUseTabHeight: false)
        _ = registerForKeyboardWillHideNotification(tableBottomConstraint)

        if true == Utilities.shared.isIphoneX() {
            confirmLocationButtonBottomConstraint.constant = 0.0
        } else {
            confirmLocationButtonBottomConstraint.constant = 30.0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hidesBottomBarWhenPushed = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hidesBottomBarWhenPushed = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFromOrderAnyThing == true {
            UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.PICKUP_LOCATION_SCREEN)
            UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.PICKUP_LOCATION_TAG)
        } else {
            UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.ADD_ADDRESS_SCREEN)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

// MARK: - IBActions
    
    @IBAction func textFieldValueChanged(_ sender: UITextField) {
        
        if let charactersCount = sender.text?.count, charactersCount >= 3 {
            if Utilities.shared.isNetworkReachable() {
                
                if let disposeObj_ = disposeObj {
                    disposeObj_.dispose()
                }
                disposeObj = LocationManager.shared.fetchAutocompletePlaces(sender.text ?? "").observeOn(MainScheduler.instance).subscribe(onNext: { (locations) in
                    if charactersCount == 0 {
                        return
                    }
                    self.locationsResults = locations
                    self.locationsTableView.reloadData()
                }, onError: { (error) in
                    if let error_ = error as? ResponseError {
                        Utilities.showToastWithMessage(error_.description())
                    }
                })
            } else {
                showNoInternetMessage()
            }
        } else {
            self.locationsResults.removeAll()
            self.locationsTableView.reloadData()
        }
    }
    
    @IBAction func confirmLocation(_ sender: Any) {
        guard let address_ = self.address, let location_ = address_.location, location_.count > 0 else {
            Utilities.showToastWithMessage("Please select location")
            return
        }
        
        if 0.0 == self.address?.latitude && 0.0 == self.address?.longitude {
            Utilities.showToastWithMessage("Please select location")
            return
        }
        
        if isFromOrderAnyThing == true {
            if let pickupDelegate_ = pickupDelegate {
                pickupDelegate_.updatePickupLocation(address: address_)
            }
            _ = navigationController?.popViewController(animated: true)
        } else {
            let saveAddressController = SaveAddressController.instantiateFromStoryBoard(.checkOut)
            saveAddressController.isFromProfile = isFromProfile
            saveAddressController.address = address_
            self.navigationController?.pushViewController(saveAddressController, animated: true)
        }
    }
    
    @IBAction func goToCurrentLocation(_ sender: Any) {
        LocationManager.shared.delegate = self
        LocationManager.shared.createLocationManager()
    }
    
    @IBAction func updateMapTypeButtonAction(_ sender: Any) {
        var imageName = "mapViewIcon"
        if mapView.mapType == .normal {
            mapView.mapType = .satellite
            imageName = "mapViewIcon"
        } else {
            mapView.mapType = .normal
            imageName = "satellitleViewIcon"
        }
        mapSwitchingButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    fileprivate func goToLocation(coordinate: CLLocationCoordinate2D) {
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 15.0)
        mapView.animate(to: camera)
    }
    
    fileprivate func isCoordinateInsideBahrain(_ coordinate: CLLocationCoordinate2D, shouldShowToast: Bool) -> Bool {
        let isContaining = bahrainBounds.contains(coordinate)
        if !isContaining && shouldShowToast {
            Utilities.showToastWithMessage("Opps. Looks like you are out of Bahrain.")
        }
        return isContaining
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.locationsTableView.isHidden = false
        if self.locationsResults.count == 0 {
            self.locationsTableView.isHidden = true
        }
        return self.locationsResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: locationCellIdentifier, for: indexPath)
        
        cell.textLabel?.font = UIFont.montserratLightWithSize(16.0)
        let locationObj = self.locationsResults[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = locationObj.description
//        cell.isUserInteractionEnabled = Utilities.isWaselDeliveryOpen()
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchField.resignFirstResponder()
        let locationObj = self.locationsResults[(indexPath as NSIndexPath).row]
        self.locationsTableView.isHidden = true
        currentPlaceID = locationObj.description
        if Utilities.shared.isNetworkReachable() {
            Utilities.showHUD(to: view, "Loading Location...")
            LocationManager.shared.geocodeWithPlaceId(locationObj.placeId).observeOn(MainScheduler.instance).subscribe(onNext: { (locationDict) in
                Utilities.hideHUD(from: self.view)
                if nil == locationDict["latitude"] || nil == locationDict["longitude"] {
                    return
                }
                let addressDict = ["latitude": locationDict["latitude"],
                                   "longitude": locationDict["longitude"],
                                   "location": locationDict["formatted_address"] as AnyObject,
                                   "zipCode": locationDict["zipcode"] as AnyObject,
                                   "country": locationDict["country"] as AnyObject,
                                   "sublocality1": locationDict["sublocality1"] as AnyObject,
                                   "sublocality2": locationDict["sublocality2"] as AnyObject,
                                   "sublocality3": locationDict["sublocality3"] as AnyObject,
                                   "city": locationDict["city"] as AnyObject,
                                   "state": locationDict["state"] as AnyObject] as [String : AnyObject]
                do {
                    let address: Address = try unbox(dictionary: addressDict)
                    self.address = address
                    self.searchField.text = self.currentPlaceID
                    let camera = GMSCameraPosition.camera(withLatitude: address.latitude ?? 0.0, longitude: address.longitude ?? 0.0, zoom: 15.0)
                    self.mapView.animate(to: camera)
                } catch {
                    Utilities.showToastWithMessage(ResponseError.unboxParseError.description())
                }
                
            }, onError: { (error) in
                Utilities.hideHUD(from: self.view)
                if let error_ = error as? ResponseError {
                    Utilities.showToastWithMessage(error_.description())
                }
            }).disposed(by: disposbleBag)
        } else {
            showNoInternetMessage()
        }
    }
    // MARK: - TextField Delegates
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.locationsResults.removeAll()
        self.locationsTableView.reloadData()
        return true
    }

    // MARK: - MapView Delegates
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        
        if isMapLoaded == false {
            isMapLoaded = true
        }
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        let location = CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)
        LocationManager.shared.geocodeLocation(location)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (locationDict) in
                let latitude = locationDict["latitude"] ?? 0.0 as AnyObject
                let longitude = locationDict["longitude"] ?? 0.0 as AnyObject
                let addressDict = ["latitude": latitude,
                                   "longitude": longitude,
                                   "zipCode": locationDict["zipcode"] as AnyObject,
                                   "country": locationDict["country"] as AnyObject,
                                   "sublocality1": locationDict["sublocality1"] as AnyObject,
                                   "sublocality2": locationDict["sublocality2"] as AnyObject,
                                   "sublocality3": locationDict["sublocality3"] as AnyObject,
                                   "city": locationDict["city"] as AnyObject,
                                   "formattedAddress": locationDict["formattedAddress"] as AnyObject,
                                   "state": locationDict["state"] as AnyObject] as [String : AnyObject]
                do {
                    let address: Address = try unbox(dictionary: addressDict)
                    self.address = address
                    if self.currentPlaceID != nil {
                        self.address?.location = self.currentPlaceID
                        self.searchField.text = self.address?.location
                        self.currentPlaceID = nil
                    } else {
                        self.address?.location = (address.country == "Bahrain") ? address.formattedAddress : ""
                        self.searchField.text = (address.country == "Bahrain") ? address.formattedAddress : ""
                    }
                } catch {
                    Utilities.showToastWithMessage(ResponseError.unboxParseError.description())
                }
            }, onError: { (error) in
                if let error_ = error as? ResponseError {
                    Utilities.showToastWithMessage(error_.description())
                }
            }).disposed(by: disposbleBag)
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        
        guard isMapLoaded == true else {
            return
        }
        
        var latitude  = position.target.latitude
        var longitude = position.target.longitude
        
        if position.target.latitude > bahrainBounds.northEast.latitude {
            latitude = bahrainBounds.northEast.latitude
        }
        
        if position.target.latitude < bahrainBounds.southWest.latitude {
            latitude = bahrainBounds.southWest.latitude
        }
        
        if position.target.longitude > bahrainBounds.northEast.longitude {
            longitude = bahrainBounds.northEast.longitude
        }
        
        if position.target.longitude < bahrainBounds.southWest.longitude {
            longitude = bahrainBounds.southWest.longitude
        }
        
        if latitude != position.target.latitude || longitude != position.target.longitude {
            
            var l = CLLocationCoordinate2D()
            l.latitude  = latitude
            l.longitude = longitude
            
            mapView.animate(toLocation: l)
        }
    }    
}

extension AddAddressController: LocationManagerDelegate {
    
    func locationManager(_ locationManager: LocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopLocationUpdates()
        guard let location: CLLocation = locations.last else {
            return
        }
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        geoCodeLocation(locationManager, location, shouldUseCurrentlocation: true, shouldSaveLocation: false).subscribe(onNext: { (locationDict) in
            if let lat = locationDict[LatitudeKey] as? Double, let lng = locationDict[LongitudeKey] as? Double {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                if self.isCoordinateInsideBahrain(coordinate, shouldShowToast: true) {
                    self.goToLocation(coordinate: coordinate)
                }
            }
        }).disposed(by: disposbleBag)
    }
    
    func locationManager(_ locationManager: LocationManager, didFailWithError error: NSError) { }
    
}

protocol UpdatePickupLocation: class {
    func updatePickupLocation(address: Address)
}
