//
//  District.swift
//  MyLocations
//
//  Created by John Shiver on 3/6/17.
//  Copyright © 2017 Razeware. All rights reserved.
//

import Foundation
import UIKit


class District: NSObject {

    let politician_name, politician_image_url, state, district_id, politician_url, district_url, phone_number: String

    init(politician_name: String, politician_image_url: String,
         politician_url: String, state: String, district_id: String,
         district_url: String, phone_number: String) {

        self.politician_name = politician_name
        self.politician_image_url = politician_image_url
        self.politician_url = politician_url
        self.district_url = district_url
        self.state = state
        self.district_id = district_id
        self.phone_number = phone_number
    }

    func getFullName() -> String {
        return "District \(self.district_id): \(self.state)"
    }

    func getFullURL() -> String {
        return "http://www.johnshiver.org/congress-reps/\(self.politician_image_url)"
    }


    class func createDistrictFromJson(with json: [String: AnyObject]) -> District {
        // Creates new district from json response
        // TODO: add error handling
        // tho i am skeptical how much this will be an issue..given that
        // i control the api
        // famouse last words
        // -------------------------------------------------------------------

        let politician_name = json["politician_name"]!
        let politician_image_url = json["politician_image_url"]!
        let politician_url = json["politician_url"]!
        let phone_number = json["phone_number"]!
        let district_url = json["district_url"]!
        let state = json["district_shape"]!["statename"]!
        let district_id = json["district_shape"]!["district"]!

        print(politician_name, politician_image_url, state!, district_id!)

        return District(politician_name: politician_name as! String,
                        politician_image_url: politician_image_url as! String,
                        politician_url: politician_url as! String,
                        state: state! as! String,
                        district_id: district_id! as! String,
                        district_url: district_url as! String,
                        phone_number: phone_number as! String)
    }

}
