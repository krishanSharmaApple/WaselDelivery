//
//  LocationManager.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 26/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import CoreLocation
import RxSwift

let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
let googleMapsKey = "AIzaSyA4sub0uK24ZtKSHrCRejuTzSntIg6DQs8"
let baseURLPlaces = "https://maps.googleapis.com/maps/api/place/autocomplete/json?"

@objc protocol LocationManagerDelegate: class {
    func locationManager(_ locationManager: LocationManager, didUpdateLocations locations: [CLLocation])
    func locationManager(_ locationManager: LocationManager, didFailWithError error: NSError)
    @objc optional func locationManager(_ locationManager: LocationManager, shouldShowSettingsAlert shouldShow: Bool)
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    var locationManager: CLLocationManager?
    weak var delegate: LocationManagerDelegate?
    
    fileprivate override init() { }
    
    func createLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
                if let delegate_ = self.delegate {
                    delegate_.locationManager?(self, shouldShowSettingsAlert: true)
                }
                return
            }
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.distanceFilter = kCLDistanceFilterNone
            locationManager?.requestWhenInUseAuthorization()
            locationManager?.startUpdatingLocation()
        } else {
            if let delegate_ = self.delegate {
                delegate_.locationManager?(self, shouldShowSettingsAlert: true)
            }
        }
    }
        
    func startLocationUpdates() {
        if let locationManager_ = locationManager {
            locationManager_.startUpdatingLocation()
        }
    }
    
    func stopLocationUpdates() {
        if let locationManager_ = locationManager {
            locationManager_.stopUpdatingLocation()
        }
    }
    
    // MARK: - Location Manager Delegates
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let delegate_ = self.delegate {
            delegate_.locationManager(self, didUpdateLocations: locations)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let delegate_ = self.delegate {
            delegate_.locationManager(self, didFailWithError: error as NSError)
        }
    }
    
    func convertAddressDictToLocation(_ dict: [String: AnyObject]) -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        if let geometry = dict["geometry"] as? [String: AnyObject] {
            if let location = (geometry["location"] as? [String: AnyObject]) {
                if let latitude = location["lat"] as? NSNumber {
                    dictionary["latitude"] = latitude.doubleValue as AnyObject?
                } else {
                    dictionary["latitude"] = 0.0 as AnyObject?
                }
                if let longitude = location["lng"] as? NSNumber {
                    dictionary["longitude"] = longitude.doubleValue as AnyObject?
                } else {
                    dictionary["longitude"] = 0.0 as AnyObject?
                }
            }
        }
        dictionary["formattedAddress"] = dict["formatted_address"]
        
        if let addressArray: [AnyObject] = dict["address_components"] as? [AnyObject] {
            for aDict in addressArray {
                if let aDict_: [String: AnyObject] = aDict as? [String: AnyObject] {
                    Utilities.log(aDict_ as AnyObject, type: .info)
                    if let typesArray: [AnyObject] = aDict_["types"] as? [AnyObject] {
                        let longName: String = "long_name"
                        if typesArray.count != 0 {
                            let array: NSArray = NSArray(array: typesArray)
                            
                            if array.contains("point_of_interest") {
                                dictionary["sublocality3"] = aDict_[longName]
                            } else if array.contains("sublocality_level_2") || array.contains("route") {
                                dictionary["sublocality2"] = aDict_[longName]
                            } else if array.contains("sublocality_level_1") || array.contains("neighborhood") {
                                dictionary["sublocality1"] = aDict_[longName]
                            } else if array.contains("locality") {
                                dictionary["city"] = aDict_[longName]
                            } else if array.contains("administrative_area_level_1") {
                                dictionary["state"] = aDict_[longName]
                            } else if array.contains("country") {
                                dictionary["country"] = aDict_[longName]
                            } else if array.contains("postal_code") {
                                dictionary["zipcode"] = aDict_[longName]
                            }
                        }
                    }
                }
            }
        }
        return dictionary
    }
    
    fileprivate func geocodeWithUrl(_ url: URL) -> Observable<[String: AnyObject]> {
        
        return ApiManager.dataTask(NSMutableURLRequest(url: url))
            .map { self.getLocation(responseDict: $0) }.concat()
    }
    
    func getLocation(responseDict: AnyObject) -> Observable<[String: AnyObject]> {
        guard let responseDict_ = responseDict as? [String: AnyObject] else {
            return Observable.error(ResponseError.unkonownError)
        }
        if let results = responseDict_["results"]  as? [AnyObject] {
            if results.count != 0 {
                if let locationDict: [String: AnyObject] = results.first as? Dictionary {
                    let locationObj: Dictionary = self.convertAddressDictToLocation(locationDict)
                    return Observable.just(locationObj)
                } else {
                    return Observable.error(ResponseError.unkonownError)
                }
            } else {
                return Observable.error(ResponseError.unkonownError)
            }
        } else {
            return Observable.error(ResponseError.unkonownError)
        }
    }
    
    func geocodeLocation(_ location: CLLocation) -> Observable<[String: AnyObject]> {
        
        let coordinate = location.coordinate
        let url = "\(baseURLGeocode)key=\(googleMapsKey)&latlng=\(coordinate.latitude),\(coordinate.longitude)&amp;sensor=false"
        let geocodeURL = URL(string: url) ?? URL(fileURLWithPath: "")
        return geocodeWithUrl(geocodeURL)
    }
    
    func geocodeAddress(_ address: String!) -> Observable<[String: AnyObject]> {
        if let lookupAddress = address {
            let url = "\(baseURLGeocode)address=\(lookupAddress)&amp;sensor=false"
            let escapedUrl = url.addingPercentEncoding( withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let geocodeURL = URL(string: escapedUrl ?? "") ?? URL(fileURLWithPath: "")
            return geocodeWithUrl(geocodeURL)
        } else {
            return Observable.error(ResponseError.unkonownError)
        }
    }
    
    func geocodeWithPlaceId(_ placeId: String!) -> Observable<[String: AnyObject]> {
        if let placeId_ = placeId {
            let url = "\(baseURLGeocode)key=\(googleMapsKey)&place_id=\(placeId_)&language=en"
            let escapedUrl = url.addingPercentEncoding( withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let geocodeURL = URL(string: escapedUrl ?? "") ?? URL(fileURLWithPath: "")
            return geocodeWithUrl(geocodeURL)
        } else {
            return Observable.error(ResponseError.unkonownError)
        }
    }
    
    func fetchAutocompletePlaces(_ keyword: String) -> Observable<[LocationSearchResult]> {
        
        let urlString = "\(baseURLPlaces)key=\(googleMapsKey)&input=\(keyword)&components=country:bh"
        guard let characterSet = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as? NSMutableCharacterSet else {
            return Observable.error(ResponseError.unkonownError)
        }
        characterSet.addCharacters(in: "+&")
        if let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet) {
            if let url = URL(string: encodedString) {
                return ApiManager.dataTask(NSMutableURLRequest(url: url))
                    .map { self.getAutoCompleteResults(responseObj: $0) }.concat()
            } else {
                return Observable.error(ResponseError.unkonownError)
            }
        } else {
            return Observable.error(ResponseError.unkonownError)
        }
    }
    
    func getAutoCompleteResults(responseObj: AnyObject) -> Observable<[LocationSearchResult]> {
        
        guard let responseObj_ = responseObj as? [String: AnyObject] else {
            return Observable.error(ResponseError.unkonownError)
        }
        if let predictions = responseObj_["predictions"]  as? [AnyObject] {
            var locations = [LocationSearchResult]()
            for dict in predictions {
                let searchResult = LocationSearchResult(placeId: dict["place_id"] as? String, description: dict["description"] as? String)
                locations.append(searchResult)
            }
            return Observable.just(locations)
        } else {
            return Observable.error(ResponseError.unkonownError)
        }
    }
    
}
