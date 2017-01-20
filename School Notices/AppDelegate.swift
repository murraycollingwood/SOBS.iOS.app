//
//  AppDelegate.swift
//  School Notices
//
//  Created by Murray Collingwood on 12/12/16.
//  Copyright © 2016 Focus Computing Pty Ltd. All rights reserved.
//

import UIKit
import UserNotifications

var mydevicetoken: String? = nil

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in

                if error == nil{
                    // Enable or disable features based on authorization.
                    if granted {
                        let generalCategory = UNNotificationCategory(identifier: "SOBS",
                                                                     actions: [],
                                                                     intentIdentifiers: [],
                                                                     options: .customDismissAction)
                        
                        center.setNotificationCategories([generalCategory])
                        
                        print("Registering for remote notifications... hoping for a call back")
                        // application.registerUserNotificationSettings((center as? UIUserNotificationSettings)!)
                        
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    // print("ios10: requestAuthorisation has failed: \(error)")
                }
            }
            
        } else {
            // Older ios <= 9.3
            let setting = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(setting)
            application.registerForRemoteNotifications()
        }
        
        return true
    }


    @nonobjc func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        print("we are capturing the device token for the mobile device... ")
        
        // This function isn't called in the simulator - you can only test this with a real one!
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        print("deviceToken is being stored awaiting the login: \(deviceTokenString)")
        
        // Store this in the global, we can't send it until we have a valid logged in user
        mydevicetoken = deviceTokenString
    }
    
    @nonobjc func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        // print("Failed to register:", error)
    }
    
    @nonobjc @available(iOS 10.0, *)
    func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
        print("hello - willPresentNotification")
    }
    
    @nonobjc @available(iOS 10.0, *)
    func userNotificationCenter(center: UNUserNotificationCenter, didReceiveNotificationResponse response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void) {
        print("hello - didReceiveNotification")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

