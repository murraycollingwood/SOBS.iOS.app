//
//  NoticeList.swift
//  School Notices
//
//  Created by Murray Collingwood on 21/12/16.
//  Copyright © 2016 Focus Computing Pty Ltd. All rights reserved.
//

import Foundation

protocol NoticeListDelegate {
    // The failMessage will always have a string
    func failMessage(_: String)
    
    // On success
    func noticeListUpdated()
}


class NoticeList {
    
    var groups: [String]?
    var notices: [Array<Notice>]?
    var date: Date?
    
    var delegate: NoticeListDelegate?

    
    public func count() -> Int {
        if notices == nil {
            return 0
        }
        return notices!.count as Int
    }

    public func count(_ section: Int) -> Int {
        if notices == nil {
            return 0
        }
        return notices![section].count as Int
    }
    
    public func retrieveNotice(_ groupindex: Int, _ noticeindex: Int) -> Notice? {
        print(" = retrieve notice[\(groupindex)][\(noticeindex)]")
        return notices?[groupindex][noticeindex]
    }
    
    public func retrieveNotice(_ indexPath: IndexPath) -> Notice? {
        return retrieveNotice(indexPath.section, indexPath.row)
    }
    

    // Let's assume for now that this is an array of an array of notices
    public func updateNotices(_ currentUser: User) {
        
        print("START updateNotices(user)")
        notices = []
        
        let getNotices = XMLNode(name: "getNotices")
     
        guard let soapRequest: String = currentUser.createXML(getNotices) else {
            print("SOAP failed")
            if let del = delegate {
                del.failMessage("soapRequest is nil")
            }
            return
        }
        
        guard let url = URL(string: sobsurl) else {
            print("URL failed")
            if let del = delegate {
                del.failMessage("Error creating URL from " + sobsurl)
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = soapRequest.data(using: .utf8)
        
        print("url = " + urlRequest.debugDescription)
        print("url.data = " + soapRequest)
        
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if error != nil {
                print(error.debugDescription)
            } else {
                // print ("response = " + response.debugDescription)
                
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
                                        DispatchQueue.main.async(){
                                            print("*** dispatching main queue ***")
                                            self.responseSuccess = sobsSoap
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }.resume()

    }
  
    var responseSuccess: XMLNode? {
        didSet {
            let responses = responseSuccess
            if responses != nil {

                var count = 0
                while count < (responses?.children.count)! {
                    let response:XMLNode = (responses?[count])!
                    print("responses[\(count)] = " + response.description)
                    if response.name == "response" { // Ignore the "result"
                        switch response.attributes["function"]! {
                            case "authentication" :
                                if response["result"]?.attributes["code"]! == "100" {
                                    print("authentication = 100")
                                } else {
                                    print("Authentication failed")
                                    if let del = self.delegate {
                                        if let msg = response["result"]?.text {
                                            del.failMessage(msg)
                                        }
                                    }
                                }
                            case "getNotices" :
                                if response["result"]?.attributes["code"]! == "100" {
                                    print("getNotices = 100")
                                    if let groupList: XMLNode = response["group-list"] {
                                        self.createFromXML(groupList)
                                        if let del = self.delegate {
                                            print("** Calling noticeListUpdated() **")
                                            del.noticeListUpdated()
                                        }
                                    }
                                    
                                } else {
                                    print("getNotices failed")
                                    if let del = self.delegate {
                                        if let code = response["result"]?.attributes["code"] {
                                            if let msg = response["result"]?.text {
                                                del.failMessage(msg + " (\(code))")
                                            }
                                        }
                                    }
                                }
                            default :
                                print("Unknown function: " + response.attributes["function"]!)
                        }
                    }
                    count += 1
                }
                    
            }
            
        }
    }
    
    
    // We will need a couple of constructors, one from the local database, one from the XML
    public func createFromXML(_ groupList: XMLNode) {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // date is an attribute on the group-list
        let noticeDate: String? = groupList.attributes["date"]
        print ("group-list date=\(noticeDate!)")
        if let schoolDate = noticeDate {
            self.date = dateFormatter.date(from: schoolDate)
        }

        // Read the XML and create the arrays
        var groupcount = 0
        groups = []
        while groupcount < groupList.children.count {
            let group: XMLNode = groupList.children[groupcount]
            
            if let groupname = group["name"]?.text {
                
                // print(" - group=\(groupname)")
                
                // Add the groupname to the groups
                groups?.append(groupname)
                
                // Create the array for the notices for this group
                notices?.append([])
                
                let noticeList: XMLNode = group["notice-list"] ?? XMLNode()
                
                var noticecount = 0
                while noticecount < noticeList.children.count {
                    let noticeNode: XMLNode = noticeList.children[noticecount]
                    let notice: Notice = Notice(noticeNode)
                    
                    // Add the date
                    if let date = noticeDate {
                        notice.date = dateFormatter.date(from: date)
                    }
                        
                    // Add this notice to our array
                    notices?[groupcount].append(notice)
                    
                    // Increment
                    noticecount += 1
                }
                
            }
            
            // Increment the loop
            groupcount += 1
        }

    }
    
    // The local database will store notices based on the date of the notice
    public func loadFromLocalDatabase(_ date: Date) {
        
    }
    
    
    
}


class Notice {
    
    var content: String?
    var html: String?
    
    var date: Date?
    var author: String?
    var shortcode: String?
    
    
    // I'm guessing there is an assumed return from the init() method
    init(_ xml: XMLNode) {
        
        print(" -- build a notice from xml = " + xml.debugDescription)
        author = xml["author"]?.text
        print(" --- author = " + author!)
        
        shortcode = xml["shortcode"]?.text
        
        content = xml["content"]?.text
        html = xml["html"]?.description // We don't want to remove the html from this piece
    }
    
    
}
