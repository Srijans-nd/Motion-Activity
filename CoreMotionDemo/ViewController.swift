//
//  ViewController.swift
//  CoreMotionDemo
//
//  Created by srijans on 19/02/19.
//  Copyright © 2019 srijan. All rights reserved.
//

import UIKit
import CoreMotion
import UserNotifications
import CoreLocation
import AVFoundation

class MotionActivityViewController: UIViewController, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {
    
    let motionManager = CMMotionManager()
    let locationManager = CLLocationManager()
    let motionActivityManager = CMMotionActivityManager()
    var timer: Timer!
    var currentMotionActivity: CMMotionActivity!
    var currentLocation: CLLocation!

    @IBOutlet weak var accelerometerData: UITextView!
    @IBOutlet weak var gyroscopeData: UITextView!
    @IBOutlet weak var magnetometerData: UITextView!
    @IBOutlet weak var deviceMotionData: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupLocalNotificationCenter()
        setupMotionActivityManager()
    }
    
    // MARK: LOCATION
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        }
        locationManager.startMonitoringSignificantLocationChanges()
        
//        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
//        locationManager.distanceFilter = kCLDistanceFilterNone
//        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.count > 0 else { return }
        currentLocation = locations.last!
        gyroscopeData.text =
        """
        Latitude:   \(currentLocation.coordinate.latitude)
        Longitude:  \(currentLocation.coordinate.longitude)
        Altitude:   \(currentLocation.altitude)
        Floor:      \(String(describing: currentLocation.floor))
        Speed:      \(currentLocation.speed)
        Course:     \(currentLocation.course)
        Timestamp:  \(currentLocation.timestamp)
        VerticalAccuracy: \(currentLocation.verticalAccuracy)
        HorizontalAccuracy: \(currentLocation.horizontalAccuracy)
        """
        assessMotionActivity()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
    
    // MARK: LOCAL NOTIFICATIONS
    func setupLocalNotificationCenter() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (isAuthorized, error) in
            print(isAuthorized)
            print(error ?? "No error")
        }
    }
    
    func createLocalNotification(activity: CMMotionActivity) {
        let localNotificationContent = UNMutableNotificationContent()
        localNotificationContent.title = "Motion Activity Detected"
        localNotificationContent.body =
        """
        Stationary:     \(activity.stationary)
        Walking:        \(activity.walking)
        Running:        \(activity.running)
        Automotive:     \(activity.automotive)
        Cycling:        \(activity.cycling)
        Unknown:        \(activity.unknown)
        Confidence:     \(activity.confidence.rawValue)
        """
        
        if(activity.automotive == true) {
            localNotificationContent.sound = UNNotificationSound.default
        }
        
        localNotificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "TEST NOTIFICATION", content: localNotificationContent, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    // MARK: MOTION ACTIVITY
    func setupMotionActivityManager() {
        motionActivityManager.startActivityUpdates(to: OperationQueue.main) { [weak self](CMMotionActivity) in
            print(".......\(String(describing: CMMotionActivity))")
            self?.currentMotionActivity = CMMotionActivity
            self?.deviceMotionData.text =
            """
            Stationary:     \(self?.currentMotionActivity.stationary ?? false)
            Walking:        \(self?.currentMotionActivity.walking ?? false)
            Running:        \(self?.currentMotionActivity.running ?? false)
            Automotive:     \(self?.currentMotionActivity.automotive ?? false)
            Cycling:        \(self?.currentMotionActivity.cycling ?? false)
            Unknown:        \(self?.currentMotionActivity.unknown ?? false)
            Confidence:     \(self?.currentMotionActivity.confidence.rawValue ?? 0)
            """
            
            self?.createSpeechSynthesizer(activity: CMMotionActivity)
        }
    }
    
    func assessMotionActivity() {
        guard  let activity = currentMotionActivity else { return }
        createLocalNotification(activity: activity)
    }
    
    // MARK: AUDIO PLAYBACK
    func createSpeechSynthesizer(activity: CMMotionActivity?) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        guard let motionActivity = activity else { return }
        
        var speechText = ""
        let speed = currentLocation != nil ? Int(currentLocation.speed) : 0
        if(motionActivity.automotive && speed > 0) {
            speechText = "Automotive Motion Activity Detected. Vehicle is moving at a speed of \(Int(currentLocation.speed)) meters per second."
        }
        
        if (motionActivity.walking) {
            speechText = "Walking Activity Detected."
        }
        
        if(motionActivity.running && speed > 0) {
            speechText = "Running Activity detected. Running at a speed of \(Int(currentLocation.speed)) meters per second."
        }
        
        if (motionActivity.cycling && speed > 0) {
            speechText = "Cycling Activity Detected. Cycling at a speed of \(Int(currentLocation.speed)) meters per second."
        }
        
        let utterance = AVSpeechUtterance(string: speechText)
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}

