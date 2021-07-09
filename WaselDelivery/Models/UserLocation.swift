//
//  UserLocation.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 26/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import CoreLocation

struct UserLocation: Unboxable {
    
    let sublocality1: String?
    let sublocality2: String?
    let sublocality3: String?
    let city: String?
    let state: String?
    let country: String?
    let zip: String?
    let latitude: CLLocationDegrees?
    let longitude: CLLocationDegrees?
    var detailedAddress: String?
    
    init(unboxer: Unboxer) throws {
        self.sublocality1 = try? unboxer.unbox(key: "sublocality1")
        self.sublocality2 = try? unboxer.unbox(key: "sublocality2")
        self.sublocality3 = try? unboxer.unbox(key: "sublocality3")
        self.city = try? unboxer.unbox(key: "city")
        self.state = try? unboxer.unbox(key: "state")
        self.country = try? unboxer.unbox(key: "country")
        self.zip = try? unboxer.unbox(key: "zip")
        self.latitude = try? unboxer.unbox(key: "latitude")
        self.longitude = try? unboxer.unbox(key: "longitude")
        
        var addressComponents = [String]()

        if  let sublocality3_ = sublocality3 {
            addressComponents.append(sublocality3_)
        }
        
        if let sublocality2_ = sublocality2 {
            addressComponents.append(sublocality2_)
        }
        
        if  let sublocality1_ = sublocality1 {
            addressComponents.append(sublocality1_)
        }
        
        if let city_ = city {
            addressComponents.append(city_)
        }
        
        if let state_ = state {
            addressComponents.append(state_)
        }
        
        if let country_ = country {
            addressComponents.append(country_)
        }

        if let zip_ = zip {
            addressComponents.append(zip_)
        }

        if addressComponents.count > 0 {
            self.detailedAddress = addressComponents[0...addressComponents.count-1].joined(separator: ",")
        }
    }
    
    func getLocationAddressComponents() -> [String] {
        var addressComponents = [String]()
        
        if  let sublocality3_ = sublocality3 {
            addressComponents.append(sublocality3_)
        }
        
        if let sublocality2_ = sublocality2 {
            addressComponents.append(sublocality2_)
        }
        
        if  let sublocality1_ = sublocality1 {
            addressComponents.append(sublocality1_)
        }
        
        if let city_ = city {
            addressComponents.append(city_)
        }
        
        if let state_ = state {
            addressComponents.append(state_)
        }
        
        if let country_ = country {
            addressComponents.append(country_)
        }
        return addressComponents
    }
}
