//
//  Address.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 16/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation
import Unbox

struct Address: Unboxable {
    
    let id: Int?
    let latitude: Double?
    let longitude: Double?
    let deliveryCharge: Double?
    var landmark: String?
    var doorNumber: String?
    var zipCode: Int?
    var formattedAddress: String?
    var addressType: String?
    var location: String?
    var country: String?
    var countryCode: Int?
    var castOff = false
    var city: String?
    var state: String?

    init(unboxer: Unboxer) throws {
        self.id = try? unboxer.unbox(key: "id")
        self.latitude = try? unboxer.unbox(key: "latitude")
        self.longitude = try? unboxer.unbox(key: "longitude")
        self.deliveryCharge = try? unboxer.unbox(key: "deliveryCharge")
        self.landmark = try? unboxer.unbox(key: "landmark")
        self.doorNumber = try? unboxer.unbox(key: "doorNumber")
        self.formattedAddress = try? unboxer.unbox(key: "formattedAddress")
        self.zipCode = try? unboxer.unbox(key: "zipCode")
        self.addressType = try? unboxer.unbox(key: "addressType")
        self.country = try? unboxer.unbox(key: "country")
        self.countryCode = try? unboxer.unbox(key: "countryCode")
        self.castOff = (try? unboxer.unbox(key: "castOff")) ?? false
        
        let location_: String? = try? unboxer.unbox(key: "location")
        
        if let _location = location_ {
            self.location = _location
        } else {
            var addressComponents = [String]()

            let sublocality3: String? = try? unboxer.unbox(key: "sublocality3")
            if  let sublocality3_ = sublocality3, sublocality3_.count > 0 {
                addressComponents.append(sublocality3_)
            }
            
            let sublocality2: String? = try? unboxer.unbox(key: "sublocality2")
            if let sublocality2_ = sublocality2, sublocality2_.count > 0 {
                addressComponents.append(sublocality2_)
            }
            
            let sublocality1: String? = try? unboxer.unbox(key: "sublocality1")
            if  let sublocality1_ = sublocality1, sublocality1_.count > 0 {
                addressComponents.append(sublocality1_)
            }
            
            let city: String? = try? unboxer.unbox(key: "city")
            if let city_ = city, city_.count > 0 {
                addressComponents.append(city_)
            }
            self.city = city ?? ""

            let state: String? = try? unboxer.unbox(key: "state")
            if let state_ = state, state_.count > 0 {
                addressComponents.append(state_)
            }
            self.state = state ?? ""
            
            if let country_ = country, country_.count > 0 {
                addressComponents.append(country_)
            }
            
            if let zip_ = zipCode {
                addressComponents.append(String(zip_))
            }
            
            if addressComponents.count > 0 {
                self.location = addressComponents[0...addressComponents.count-1].joined(separator: ",")
            }
        }
    }
    
    func getAddressString() -> String {
        
        var addString = ""
        if let location_ = location, location_.count > 0 {
            if let doorNumber_ = doorNumber, doorNumber_.count > 0 {
                addString.append("\(doorNumber_)")
                if let landmark_ = landmark, landmark_.count > 0 {
                    addString.append(",\n\(landmark_)")
                    addString.append(",\n\(location_)")
                } else {
                    addString.append(",\n\(location_)")
                }
            } else if let landmark_ = landmark, landmark_.count > 0 {
                addString.append("\(landmark_)")
                addString.append(",\n\(location_)")
            } else {
                addString.append(location_)
            }
        }
        return addString
    }
    
}
