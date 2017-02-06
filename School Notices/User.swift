//
//  User.swift
//  School Notices
//
//  Created by Murray Collingwood on 1/1/17.
//  Copyright © 2017 Focus Computing Pty Ltd. All rights reserved.
//

import Foundation


class User: NSObject, SoapResponse {
    
    var delegate: LoginViewDelegate?

    var schoolname: String?
    var schoolid: Int?
    
    var username: String?
    var password: String?
    
    var authenticated: Bool = false
    
   
    override init() {
        // let defaults = UserDefaults.standard
        let defaults = KeychainWrapper.standard
        if let name = defaults.string(forKey: "sobs.schoolname") {
            schoolname = name
        }
        schoolid = defaults.integer(forKey: "sobs.schoolid") ?? 0
        if let uname = defaults.string(forKey: "sobs.username") {
            username = uname
        }
        if let pwd = defaults.string(forKey: "sobs.password") {
            password = pwd
        }
        
    }
    
    public func isAuthenticated() -> Bool {
        return authenticated
    }
    
    public func hasValues() -> Bool {
        if schoolid == 0 {
            return false
        }
        if (username == nil) {
            return false
        }
        if (password == nil) {
            return false
        }
        if (username?.isEmpty)! {
            return false
        }
        if (password?.isEmpty)! {
            return false
        }
        return true
    }
    
    
    public func asXMLRequest(application: String!) -> XMLNode! {
        let auth = XMLNode(name: "authentication")
        if let sid = schoolid {
            auth.addChild(name: "schoolid", value: String(describing: sid))
            if let name = username {
                auth.addChild(name: "username", value: name)
                if let pass = password {
                    auth.addChild(name: "password", value: pass)
                }
            }
        }
        auth.addChild(name: "application", value: application)
        
        // If the deviceToken has been recorded, then we can send that here
        if let mdt = mydevicetoken {
            auth.addChild(name: "deviceToken", value: mdt)
        }
        
        return auth
    }

    
    
    // The schoolid, schoolname, username, and password should all be filled in when this is called
    public func login(application: String!) {
   
        // Lets set it to false to begin with
        authenticated = false
        
        // Get the authentication node
        let authenticationNode: XMLNode! = self.asXMLRequest(application: application)
        
        weak var weakSelf = self
        Soap.call(url: sobsurl, withXMLRequests: [authenticationNode], from: weakSelf)
    }
    
    
    
    public func logoff() {
        schoolname = nil
        schoolid = 0
        username = nil
        password = nil
        
        // Remove the previous values from the KeyChain
        updateDefaults()
        
        // We are no longer authenticated
        authenticated = false
    }
    
    func soapFailed(code: Int!, errorObject: Any!) {
        if let del = delegate {
            if let msg = errorObject as? String {
                del.loginUnsuccessful(code, msg)
            } else {
                del.loginUnsuccessful(999, "Login failed, not sure why")
            }
            return
        }
        // print("Delegate not set: error \(code) object \(errorObject)")
    }
    
    func soapSuccess(xml: XMLNode!) {
        responseSuccess = xml
    }

    
    
    var responseSuccess: XMLNode? {
        didSet {
            let responses = responseSuccess
            if responses != nil {
                var count = 0
                // print("responses is not nil")
                while count < (responses?.children.count)! {
                    let response:XMLNode = (responses?[count])!
                    // print("responses[\(count)] = " + response.description)
                    if response.name == "response" { // Ignore the "result"
                        if response.attributes["function"] == "authentication" {
                            if response["result"]?.attributes["code"]! == "100" {
                                // print("We have reached a state of authentication - we need a message or an action")
                                if let del = delegate {
                                    updateDefaults()
                                    del.loginSuccessful()
                                }
                            } else {
                                // print("Authentication failed")
                                if let del = delegate {
                                    let code = response["result"]?.attributes["code"]
                                    let msg = response["result"]?.text
                                    del.loginUnsuccessful(Int(code!), msg)
                                }
                            }
                        }
                    }
                    count += 1
                }
            }
            
        }
    }
    
    private func updateDefaults() {

        // let defaults = UserDefaults.standard
        let defaults = KeychainWrapper.standard

        if username == nil {
            defaults.set("", forKey: "sobs.username")
        } else if defaults.string(forKey: "sobs.username") != username {
            // print("UserDefaults updated with new username: \(username)")
            defaults.set(username!, forKey: "sobs.username")
        }
        
        if password == nil {
            defaults.set("", forKey: "sobs.password")
        } else if defaults.string(forKey: "sobs.password") != password {
            defaults.set(password!, forKey: "sobs.password")
        }
        
        if schoolid == nil {
            defaults.set(0, forKey: "sobs.schoolid")
            defaults.set("", forKey: "sobs.schoolname")
        } else if schoolid! > 0 && defaults.integer(forKey: "sobs.schoolid") != schoolid! {
            defaults.set(schoolid!, forKey: "sobs.schoolid")
            defaults.set(schoolname!, forKey: "sobs.schoolname")
        }

    }
    
}



