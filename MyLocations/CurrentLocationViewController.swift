//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Matthijs on 19/07/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import QuartzCore
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var districtName: UILabel!
    @IBOutlet weak var locationAccuracy: UIButton!



    let locationManager = CLLocationManager()
    var location: CLLocation?
    var district: District?
    var updatingLocation = false
    var found = false
    var lastLocationError: Error?
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
  
    var timer: Timer?
  
    var managedObjectContext: NSManagedObjectContext!
  
    var logoVisible = false

    var json: [String: AnyObject]?
  
    lazy var logoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(getLocation),
                        for: .touchUpInside)
        button.center.x = self.view.bounds.midX
        button.center.y = 220
        return button
    }()

    var soundID: SystemSoundID = 0
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // make accuracy button round
        locationAccuracy.layer.cornerRadius = 5.0

        updateLabels()
        configureGetButton()
        loadSoundEffect("Sound.caf")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueDistrictDetail" {
            stopLocationManager()
            updateLabels()
            configureGetButton()
            found = false
            // create district from json + attach new district to target controller
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            if let j = self.json {
                let district = District.createDistrictFromJson(with: j)
                controller.district = district
            } else {
            }
        }
    }

    @IBAction func getDistrictDetails(_ sender: Any) {
        // called when the district info button is pressed
        // alerts the user if current location accuracy
        // is considered to be highly inaccurate (red)
        // otherwise performs detail segue if there is json
        // ---------------------------------------------
        print("pressed the find my district button")
        if locationAccuracy?.backgroundColor == UIColor.red {
            print("Tell user accuracy is bad before performing segue")
            let alert = UIAlertController(title: "Location is inaccurate!",
                                          message: "Our current location data for you is off by a few hundreed meters. I cannot guarantee you selected the correct district :/ ",
                                          preferredStyle: .alert)

            let dontSegueAction = UIAlertAction(title: "Dont do it", style: .default, handler: nil)
            let doSegueAction = UIAlertAction(title: "Proceed", style: .default, handler: {(alert: UIAlertAction) in
                if self.json != nil {
                    self.performSegue(withIdentifier: "segueDistrictDetail", sender: self)
                }
            })
            alert.addAction(dontSegueAction)
            alert.addAction(doSegueAction)
            present(alert, animated: true, completion: nil)
        }
        if json != nil {
            self.performSegue(withIdentifier: "segueDistrictDetail", sender: self)
        }
    }

    func performDistrictLookup(performSegue:Bool = false) {
        var url_string: String
        if let location = location {
            url_string = "http://www.johnshiver.org/voter-registration/api/v1/district/?format=json&lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)"

        } else {
            // let the user know there was an error
            print("****ERROR Tried to perform look up without location" )
            return
        }
        let url = URL(string: url_string)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // go make request
        URLSession.shared.dataTask(with: url!, completionHandler: {
            (data, response, error) in
            if error != nil {
                print("\(error)")
            } else {
                do {
                    let json_response = try JSONSerialization.jsonObject(with: data!,
                                                                         options: .allowFragments)
                                                                         as! [String :AnyObject]
                    self.json = json_response

                    // update labels in main thread, otherwise this takes
                    // forever to execute
                    DispatchQueue.main.async {
                        if performSegue {
                            self.performSegue(withIdentifier: "segueDistrictDetail", sender: self)
                        }
                        self.updateLabels()
                    }

                } catch let error as NSError {
                    print(error)
                }
            }
        }).resume()

    }

    // ------------------------------------------------------------------

  
    @IBAction func getLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
    
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
    
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
    
        if logoVisible {
            hideLogoView()
        }
    
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }

        updateLabels()
        configureGetButton()
    }
  
  func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled",
                                      message: "Please enable location services for this app in Settings.",
          preferredStyle: .alert)
    
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    func updateLabels() {
        print("updating labels")
        if let location = location {
            messageLabel.text = ""
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }

            if location.horizontalAccuracy > 2000 {
                locationAccuracy.backgroundColor = UIColor.red
            } else if location.horizontalAccuracy <= locationManager.desiredAccuracy {
                locationAccuracy.backgroundColor = UIColor.green
            } else {
                locationAccuracy.backgroundColor = UIColor.yellow
            }

        } else {
            addressLabel.text = ""
            let statusMessage: String
            if let error = lastLocationError as? NSError {
                if error.domain == kCLErrorDomain &&
                    error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = ""
                showLogoView()
            }
            messageLabel.text = statusMessage
        }

        if let json = json {
            district = District.createDistrictFromJson(with: json)
            districtName.isHidden = false
            districtName.text = district?.getFullName()
        }

  }
  
  func string(from placemark: CLPlacemark) -> String {
    var line1 = ""
    line1.add(text: placemark.subThoroughfare)
    line1.add(text: placemark.thoroughfare, separatedBy: " ")
    
    var line2 = ""
    line2.add(text: placemark.locality)
    line2.add(text: placemark.administrativeArea, separatedBy: " ")
    line2.add(text: placemark.postalCode, separatedBy: " ")
    
    line1.add(text: line2, separatedBy: "\n")
    return line1
  }
  
  func configureGetButton() {
    let spinnerTag = 1000
    
    if updatingLocation {
      
      if view.viewWithTag(spinnerTag) == nil {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        spinner.center = messageLabel.center
        spinner.center.y += spinner.bounds.size.height/2 + 15
        spinner.startAnimating()
        spinner.tag = spinnerTag
        containerView.addSubview(spinner)
      }
    } else {
      
      if let spinner = view.viewWithTag(spinnerTag) {
        spinner.removeFromSuperview()
      }
    }
  }
  
  func startLocationManager() {
    print("starting location manager")
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true
      timer = Timer.scheduledTimer(timeInterval: 60, target: self,
                                   selector: #selector(didTimeOut), userInfo: nil, repeats: false)
    }
  }
  
  func stopLocationManager() {
    print("stopping location manager")
    if updatingLocation {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
      
      if let timer = timer {
        timer.invalidate()
      }
    }
  }
  
  func didTimeOut() {
    // stops location manager
    // sets error
    // updates labels accordingly 
    // ---------------------------------------------------------------------

    print("*** Time out")
    stopLocationManager()
    if location == nil {
      lastLocationError = NSError(domain: "MyLocationsErrorDomain",
                                  code: 1, userInfo: nil)

    } else {
        performDistrictLookup(performSegue: true)
    }
    updateLabels()
    configureGetButton()
  }


    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("didFailWithError \(error)")
    
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
    
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
  
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        print("new location!")

        let newLocation = locations.last!
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            // invalid time
            return
        }
        if newLocation.horizontalAccuracy < 0 {
            // invalid accuracy
            return
        }
        if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
            // if we reached desired accuracy
            // we're done
            if location == nil {
                location = newLocation
            }
            print("*** Super accurate! \(newLocation.horizontalAccuracy) We're done!")
            if !found {
                performDistrictLookup(performSegue: true)
                found = true
            }
            performReverseGeoLookUp(newLocation)
            stopLocationManager()
            configureGetButton()
            updateLabels()
            return
        }

        performDistrictLookup(performSegue: false)
        // if we already have location, find
        // distance between old location and new location
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location {
            distance = newLocation.distance(from: location)
        }

        // if no location or new accuracy better than current accuracy
        // update current location to new location
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {

            lastLocationError = nil
            location = newLocation
            updateLabels()

            if !performingReverseGeocoding {
                performReverseGeoLookUp(newLocation)
            }

        } else if distance < 1 {
            // if we're getting small distance and there is a long time 
            // interval just call it
            let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
            if timeInterval > 10 {
                print("*** Time interval is \(timeInterval) Force done!")
                if self.json == nil {
                    performDistrictLookup(performSegue: true)
                }
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
    }


    func performReverseGeoLookUp(_ location: CLLocation) {
        print("*** Going to geocode")
        performingReverseGeocoding = true
        geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            print("*** Found placemarks: \(placemarks), error: \(error)")
            self.lastGeocodingError = error
            if error == nil, let p = placemarks, !p.isEmpty {

                if self.placemark == nil {
                    print("first placemark found!")
                    self.playSoundEffect()
                }
                self.placemark = p.last!
            } else {
                self.placemark = nil
            }

            self.performingReverseGeocoding = false
            self.updateLabels()
        })
    }

  // MARK: - Logo View

  func showLogoView() {
    if !logoVisible {
      logoVisible = true
      containerView.isHidden = true
      view.addSubview(logoButton)
    }
  }
  
  func hideLogoView() {
    if !logoVisible { return }
    
    logoVisible = false
    containerView.isHidden = false
    containerView.center.x = view.bounds.size.width * 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    
    let centerX = view.bounds.midX
    
    let panelMover = CABasicAnimation(keyPath: "position")
    panelMover.isRemovedOnCompletion = false
    panelMover.fillMode = kCAFillModeForwards
    panelMover.duration = 0.6
    panelMover.fromValue = NSValue(cgPoint: containerView.center)
    panelMover.toValue = NSValue(cgPoint:
      CGPoint(x: centerX, y: containerView.center.y))
    panelMover.timingFunction = CAMediaTimingFunction(
      name: kCAMediaTimingFunctionEaseOut)
    panelMover.delegate = self
    containerView.layer.add(panelMover, forKey: "panelMover")
    
    let logoMover = CABasicAnimation(keyPath: "position")
    logoMover.isRemovedOnCompletion = false
    logoMover.fillMode = kCAFillModeForwards
    logoMover.duration = 0.5
    logoMover.fromValue = NSValue(cgPoint: logoButton.center)
    logoMover.toValue = NSValue(cgPoint:
      CGPoint(x: -centerX, y: logoButton.center.y))
    logoMover.timingFunction = CAMediaTimingFunction(
      name: kCAMediaTimingFunctionEaseIn)
    logoButton.layer.add(logoMover, forKey: "logoMover")
    
    let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
    logoRotator.isRemovedOnCompletion = false
    logoRotator.fillMode = kCAFillModeForwards
    logoRotator.duration = 0.5
    logoRotator.fromValue = 0.0
    logoRotator.toValue = -2 * M_PI
    logoRotator.timingFunction = CAMediaTimingFunction(
      name: kCAMediaTimingFunctionEaseIn)
    logoButton.layer.add(logoRotator, forKey: "logoRotator")
  }
  
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    containerView.layer.removeAllAnimations()
    containerView.center.x = view.bounds.size.width / 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    
    logoButton.layer.removeAllAnimations()
    logoButton.removeFromSuperview()
  }
  
  // MARK: - Sound Effect
  
  func loadSoundEffect(_ name: String) {
    if let path = Bundle.main.path(forResource: name, ofType: nil) {
      let fileURL = URL(fileURLWithPath: path, isDirectory: false)
      let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
      if error != kAudioServicesNoError {
        print("Error code \(error) loading sound at path: \(path)")
      }
    }
  }
  
  func unloadSoundEffect() {
    AudioServicesDisposeSystemSoundID(soundID)
    soundID = 0
  }
  
  func playSoundEffect() {
    AudioServicesPlaySystemSound(soundID)
  }
}
