//
//  LocationViewController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 26/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation

class LocationViewController: BaseViewController, LocationManagerDelegate {
    
    @IBOutlet weak var manualEntryButton: UIButton!
    var disposbleBag = DisposeBag()
    
// MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manualEntryButton.layer.borderColor = UIColor(red: 184/255.0, green: 184/255.0, blue: 184/255.0, alpha: 1.0).cgColor
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.LOCATION_SELECTION_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.LOCATION_SELECTION_TAG)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - IBActions
    
    @IBAction func useCurrentLocation(_ sender: AnyObject) {
        LocationManager.shared.delegate = self
        LocationManager.shared.createLocationManager()
    }
    
// MARK: - Support Methods
    
    fileprivate func setRootController() {
        if let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController {
            let navController = UINavigationController(rootViewController: tabBarController)
            navController.navigationBar.isHidden = true
            UIApplication.shared.keyWindow?.rootViewController = navController
        }
    }
    
// MARK: - LocationManagerDelegate

    func locationManager(_ locationManager: LocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopLocationUpdates()
        guard let location: CLLocation = locations.last else {
            return
        }
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        geoCodeLocation(locationManager, location, shouldUseCurrentlocation: true).subscribe(onNext: { (_) in
            self.setRootController()
        }).disposed(by: disposbleBag)
    }
    
    func locationManager(_ locationManager: LocationManager, didFailWithError error: NSError) { }
}
