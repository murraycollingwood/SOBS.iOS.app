//
//  RootViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 5/1/17.
//  Copyright © 2017 Focus Computing Pty Ltd. All rights reserved.
//

import UIKit

// Global constants
let sobsurl = "https://sobs.com.au/soap.php"
let baseurl: URL = URL(string: "https://sobs.com.au/")!
let application = "waz"

protocol RootViewDelegate {
    func hasAuthenticated(_ controller: LoginViewController) -> Void
    func hasLoggedOff() -> Void
    func getUser() -> User?
}



class RootViewController: UIViewController, RootViewDelegate {

    var currentUser: User = User()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if currentUser.isAuthenticated() {
            // print("currentUser is valid - segue to the Notices list")
            performSegue(withIdentifier: "ToNotices", sender: self)
        } else {
            // print("currentUser not authenticated - segue to the Login page")
            performSegue(withIdentifier: "ToLogin", sender: self)
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // @IBAction func unwindToRoot(segue: UIStoryboardSegue) {}

    @IBOutlet weak var splash: UIImageView!
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let segueId = segue.identifier else { return }
        
        var destvc = segue.destination
        if let navcon = destvc as? UINavigationController {
            destvc = navcon.visibleViewController ?? destvc
        }
        
        switch segueId {
        case "ToLogin":
            if let loginvc = destvc as? LoginViewController {
                loginvc.delegate = self
                
                // This should be a reference, because it is a Class
                loginvc.currentUser = currentUser
            }

        case "ToNotices":
            if let noticesvc = destvc as? NoticeTableViewController {
                noticesvc.delegate = self
            }

        default: break
        }
    }
    
    // LoginView Delegate
    func hasAuthenticated(_ controller: LoginViewController) {
        // print("CurrentUser has been set - ready to go to the notices list")
        DispatchQueue.main.async(){
            // _ = controller.navigationController?.popViewController(animated: true)
            self.performSegueToReturnBack()
            self.performSegue(withIdentifier: "ToNotices", sender: self)
        }
    }

    // LoginView Delegate
    func hasLoggedOff() {
        // print("CurrentUser has been set - ready to go to the notices list")
        DispatchQueue.main.async(){
            // _ = controller.navigationController?.popViewController(animated: true)
            self.performSegueToReturnBack()
            self.performSegue(withIdentifier: "ToLogin", sender: self)
        }
    }

    public func getUser() -> User? {
        return currentUser
    }


}

// I'm not sure we are using this
extension UIViewController {
    func performSegueToReturnBack()  {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

