//
//  LoginViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 31/12/16.
//  Copyright © 2016 Focus Computing Pty Ltd. All rights reserved.
//

import UIKit

protocol LoginViewDelegate {
    func loginSuccessful() -> Void
    func loginUnsuccessful(_: Int!, _: String!) -> Void
    func displayMessage(_: String!) -> Void
    func schoolSelected( schoolId: Int!, schoolName: String!) -> Void
}


class LoginViewController: UIViewController, LoginViewDelegate, UITextFieldDelegate {

    var currentUser: User!
    var delegate: RootViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the delegates for the textfields to call back to here
        username.delegate = self
        password.delegate = self
        
        // Initialise currentuser
        if (currentUser.schoolname != nil) {
            schoolnameText.setTitle(currentUser.schoolname ?? "",for: .normal)
        }
        if (currentUser.username != nil) {
            username.text = currentUser.username ?? ""
        }
        if (currentUser.password != nil) {
            password.text = currentUser.password ?? ""
        }

        // Blank the error message
        msglabel.text = "";
    }

    
    
    
    // This aims to focus the user input to the required field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        resignFirstResponder()
        
        // If the user is blank then go there
        if let name = username?.text {
            if (name == "") {
                username.becomeFirstResponder()
                return true
            }
        }
        // If the password is blank then go there
        if let pass = password?.text {
            if (pass == "") {
                password.becomeFirstResponder()
                return true
            }
        }
        
        // We have username and password - simulate a login click
        login(loginButton);
        
        // Do not add a line break
        return true
    }

    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if currentUser.schoolid == 0 {
            performSegue(withIdentifier: "LookupSchool", sender: self)
        } else {
            self.username.becomeFirstResponder()
            if currentUser.hasValues() {
                // First time in we can attempt a login with the current user details
                login(loginButton)
            }

        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let segueId = segue.identifier else { return }
        
        var destvc = segue.destination
        if let navcon = destvc as? UINavigationController {
            destvc = navcon.visibleViewController ?? destvc
        }
        
        switch segueId {
        case "LookupSchool":
            if let lookupvc = destvc as? SchoolTableViewController {
                lookupvc.delegate = self
                lookupvc.currentUser = currentUser
            }
        default: break
        }
    }


    @IBOutlet weak var schoolnameText: UIButton!
    @IBAction func schoolname(_ sender: UIButton) {
        performSegue(withIdentifier: "LookupSchool", sender: sender)
    }
    
    // LoginView Delegate
    func schoolSelected( schoolId: Int!, schoolName: String!) {
        // print("School has been chosen id=\(schoolId) name=\(schoolName)")
        
        // Set the school into the user record
        currentUser.schoolid = schoolId
        currentUser.schoolname = schoolName
        schoolnameText.setTitle(currentUser.schoolname ?? "",for: .normal)
        
        DispatchQueue.main.async(){
            // Close the SchoolTableViewController
            self.performSegueToReturnBack()
        }
    }

    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var msglabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBAction func login(_ sender: UIButton) {
        
        // print("Login button clicked")
        
        // Do we have values for each?
        if (schoolnameText.currentTitle == "Search for school")  { return }
        if (currentUser.schoolid == 0)              { return }
        if (username.text == "")        { return }
        if (password.text == "")        { return }
        
        // Remove any existing message
        msglabel.text = ""
        
        // Set the delegate for the call back
        currentUser.delegate = self
        currentUser.username = username.text
        currentUser.password = password.text
        
        // Can we login?
        spinner?.startAnimating()

        currentUser.login(application: application);
        
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    // This function is called on a successful login - using the details in the currentuser object
    func loginSuccessful() {
        
        // currentUser is a class, therefore it is just a reference to currentUser in the RootVC
        currentUser.authenticated = true
        
        DispatchQueue.main.async {
            self.spinner?.stopAnimating()
            // print("Show a login success message")
            self.msglabel.text = "Login successful"
            // self.performSegueToReturnBack()
            // print("unwindSegue - FromLoginToRoot")
            // self.performSegue(withIdentifier: "FromLoginToRoot", sender: self)
            
            if let del = self.delegate {
                del.hasAuthenticated(self)
            }
        }
        
        
    }
  

    
    // Called when the login is unsuccessful
    func loginUnsuccessful(_ code: Int!, _ msg: String!) {
        
        // currentUser is a class, therefore it should be updating currentUser in the RootVC
        currentUser.authenticated = false
        
        DispatchQueue.main.async {
            self.spinner?.stopAnimating()
            if let icode = code {
                self.msglabel.text = msg + " (\(icode))"
            } else {
                self.msglabel.text = msg
            }
        }
    }
  
    
    func displayMessage(_ msg: String!) {
        DispatchQueue.main.async {
            self.msglabel.text = msg
        }
    }
    

}
