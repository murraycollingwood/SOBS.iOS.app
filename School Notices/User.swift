//
//  User.swift
//  School Notices
//
//  Created by Murray Collingwood on 1/1/17.
//  Copyright © 2017 Focus Computing Pty Ltd. All rights reserved.
//

import Foundation


class User: NSObject {
    
    var delegate: LoginViewDelegate?

    var schoolname: String? = "Daisy Hill College"
    var schoolid: Int? = 15
    
    var username: String?
    var password: String?
    
    var authenticated: Bool = false
    
   
    override init() {
        
        
        
        // let defaults = UserDefaults.standard
        let defaults = KeychainWrapper.standard
        if let name = defaults.string(forKey: "sobs.schoolname") {
            schoolname = name
        }
        let sid = defaults.integer(forKey: "sobs.schoolid") ?? 15
        if sid > 0 {
            schoolid = sid
        }
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
    
    
    // The schoolid, schoolname, username, and password should all be filled in when this is called
    public func login() {
        
        // Lets set it to false to begin with
        authenticated = false
        
        guard let soapRequest: String = createXML(nil) else {
            print("SOAP failed")
            if let del = delegate {
                del.loginUnsuccessful("900", "soapRequest is nil")
            }
            return
        }
        
        guard let url = URL(string: sobsurl) else {
            print("URL failed")
            if let del = delegate {
                del.loginUnsuccessful("900", "Error creating URL from " + sobsurl)
            }
            return
        }

        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = soapRequest.data(using: .utf8)

        // print("url = " + urlRequest.debugDescription)
        // print("url.data = " + soapRequest)
        
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if error != nil {
                print(error.debugDescription)
            } else {
                // print ("response = " + response.debugDescription)
  
                DispatchQueue.main.async(){

                    if data == nil {
                        print("Unable to load data as XML document")
                    }
                    let soapResponse = XML(data: data!)
                    print ("data = " + soapResponse[0].description) // Ignore the <?xml...?> wrapper

                    // Read through the soapenv:Envelope | soapenv:Body | sobsQuery
                    if let envelope = soapResponse[0] as XMLNode? {
                        print("envelope = " + envelope.name!)
                        if envelope.name == "SOAP-ENV:Envelope" {
                            let body = envelope[0]
                            print("body = " + body.name!)
                            if body.name == "SOAP-ENV:Body" {
                                let ns1 = body[0]
                                print("ns1 = " + ns1.name!)
                                if ns1.name == "ns1:sobsQueryResponse" {
                                    let sobsQuery = ns1[0]
                                    print("sobsQuery = " + sobsQuery.name!)
                                    if sobsQuery.name == "sobsQuery" {
                                        let sobsSoap = sobsQuery[0]
                                        print("sobs-soap = " + sobsSoap.name!)
                                        if sobsSoap.name == "sobs-soap" {
                                            self.responseSuccess = sobsSoap
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } // End of queue

                
            }
            
        }.resume()

    }
    
    public func createXML(_ additionalFunctions: XMLNode?) -> String? {

        
        guard let url = Bundle.main.url(forResource: "soap-template", withExtension: "xml") else {
            print("Unable to locate supporting file: soap-template.xml")
            return nil
        }
        guard let soapRequest = XML(contentsOf: url) else {
            print("Unable to load XML from soap-template.xml")
            return nil
        }
        
        let auth = XMLNode(name: "authentication")
        auth.addChild(name: "schoolid", value: String(describing: schoolid!))
        auth.addChild(name: "username", value: username!)
        auth.addChild(name: "password", value: password!)
        auth.addChild(name: "application", value: "waz")

        let soap = XMLNode(name: "sobs-soap")
        soap.attributes["version"] = "2.3"
        soap.addChild(auth)
        
        // Only do this is additionalFunctions is not nil
        if let addons = additionalFunctions {
            soap.addChild(addons)
        }
        
        let query = XMLNode(name: "sobs:sobsQuery")
        query.addChild(soap)
        let body = soapRequest[0]["soapenv:Body"]
        body?.addChild(query)

        // print("XML request = " + soapRequest.description)
        
        return soapRequest.description

    }
    
    var responseSuccess: XMLNode? {
        didSet {
            let responses = responseSuccess
            if responses != nil {
                var count = 0
                print("responses is not nil")
                while count < (responses?.children.count)! {
                    let response:XMLNode = (responses?[count])!
                    print("responses[\(count)] = " + response.description)
                    if response.name == "response" { // Ignore the "result"
                        if response.attributes["function"] == "authentication" {
                            if response["result"]?.attributes["code"]! == "100" {
                                print("We have reached a state of authentication - we need a message or an action")
                                if let del = delegate {
                                    updateDefaults()
                                    del.loginSuccessful()
                                }
                            } else {
                                print("Authentication failed")
                                if let del = delegate {
                                    let code = response["result"]?.attributes["code"]
                                    let msg = response["result"]?.text
                                    del.loginUnsuccessful(code, msg)
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

        if username != nil && defaults.string(forKey: "sobs.username") != username {
            print("UserDefaults updated with new username: \(username)")
            defaults.set(username!, forKey: "sobs.username")
        }
        if password != nil && defaults.string(forKey: "sobs.password") != password {
            defaults.set(password!, forKey: "sobs.password")
        }
        if schoolid! > 0 && defaults.integer(forKey: "sobs.schoolid") != schoolid! {
            defaults.set(schoolid!, forKey: "sobs.schoolid")
            defaults.set(schoolname!, forKey: "sobs.schoolname")
        }

    }
    
}



