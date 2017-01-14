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
    func loginUnsuccessful(_: String?, _: String?) -> Void
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
            schoolid = currentUser.schoolid ?? 0
        }
        if (currentUser.username != nil) {
            username.text = currentUser.username ?? ""
        }
        if (currentUser.password != nil) {
            password.text = currentUser.password ?? ""
        }

        msglabel.text = "";
        
        // Focus the cursor to the Username field (this works)
        username.becomeFirstResponder()
    }
    
    
    
    // This aims to focus the user input to the required field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        resignFirstResponder()
        // Try to find next responder
        if let placetext = textField.placeholder {
            print("we are trying to focus on the next field: placetext = \(placetext)")
        }
        
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

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBOutlet weak var schoolnameText: UIButton!
    @IBAction func schoolname(_ sender: UIButton) {
    }
    var schoolid: Int = 0
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var msglabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBAction func login(_ sender: UIButton) {
        
        print("Login button clicked")
        
        // Do we have values for each?
        if (schoolid == 0) { return }
        if (username.text == "") { return }
        if (password.text == "") { return }
        
        // Remove any existing message
        msglabel.text = ""
        
        // Set the delegate for the call back
        currentUser.delegate = self
        currentUser.username = username.text
        currentUser.password = password.text
        
        // Can we login?
        spinner?.startAnimating()
        currentUser.login()
        
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    // This function is called on a successful login - using the details in the currentuser object
    func loginSuccessful() {
        
        // currentUser is a class, therefore it is just a reference to currentUser in the RootVC
        currentUser.authenticated = true
        
        spinner?.stopAnimating()
        print("Show a login success message")
        msglabel.text = "Login successful"
        // self.performSegueToReturnBack()
        // print("unwindSegue - FromLoginToRoot")
        // self.performSegue(withIdentifier: "FromLoginToRoot", sender: self)
        
        if let del = delegate {
            del.hasAuthenticated(self)
        }
    }
  

    
    // Called when the login is unsuccessful
    func loginUnsuccessful(_ code: String?, _ msg: String?) {
        
        // currentUser is a class, therefore it should be updating currentUser in the RootVC
        currentUser.authenticated = false
        
        spinner?.stopAnimating()
        print("code=\(code) msg=\(msg)")
        msglabel.text = msg! + " (" + code! + ")"
    }
  
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}
