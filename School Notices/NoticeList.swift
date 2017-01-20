//
//  NoticeList.swift
//  School Notices
//
//  Created by Murray Collingwood on 21/12/16.
//  Copyright © 2016 Focus Computing Pty Ltd. All rights reserved.
//

import Foundation



class NoticeList: SoapResponse {
    
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
        return notices?[groupindex][noticeindex]
    }
    
    public func retrieveNotice(_ indexPath: IndexPath) -> Notice? {
        return retrieveNotice(indexPath.section, indexPath.row)
    }
    

    // Let's assume for now that this is an array of an array of notices
    public func updateNotices(_ currentUser: User) {
        
        notices = []
        
        var nodes: [XMLNode] = []
        nodes.append(currentUser.asXMLRequest(application: application))
        nodes.append(XMLNode(name: "getNotices"))
        
        weak var weakSelf = self
        Soap.call(url: sobsurl, withXMLRequests: nodes, from: weakSelf)
    }
    
    func soapFailed(code: Int!, errorObject: Any!) {
        if let del = self.delegate {
            if let msg = errorObject as? String {
                del.failMessage(msg)
            } else {
                del.failMessage("Error \(code)")
            }
        }
        
    }
    func soapSuccess(xml: XMLNode!) {
        responseSuccess = xml
    }

    
    var responseSuccess: XMLNode? {
        didSet {
            let responses = responseSuccess
            if responses != nil {

                var count = 0
                while count < (responses?.children.count)! {
                    let response:XMLNode = (responses?[count])!
                    // print("responses[\(count)] = " + response.description)
                    if response.name == "response" { // Ignore the "result"
                        switch response.attributes["function"]! {
                            case "authentication" :
                                if response["result"]?.attributes["code"]! == "100" {
                                    // print("authentication = 100")
                                } else {
                                    // print("Authentication failed")
                                    if let del = self.delegate {
                                        if let msg = response["result"]?.text {
                                            del.failMessage(msg)
                                        }
                                    }
                                }
                            case "getNotices" :
                                if response["result"]?.attributes["code"]! == "100" {
                                    // print("getNotices = 100")
                                    if let groupList: XMLNode = response["group-list"] {
                                        self.createFromXML(groupList)
                                        if let del = self.delegate {
                                            // print("** Calling noticeListUpdated() **")
                                            del.noticeListUpdated()
                                        }
                                    }
                                    
                                } else {
                                    // print("getNotices failed")
                                    if let del = self.delegate {
                                        if let code = response["result"]?.attributes["code"] {
                                            if let msg = response["result"]?.text {
                                                del.failMessage(msg + " (\(code))")
                                            }
                                        }
                                    }
                                }
                            default :
                                break // print("Unknown function: " + response.attributes["function"]!)
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
        if let schoolDate = noticeDate {
            self.date = dateFormatter.date(from: schoolDate)
        }

        // Read the XML and create the arrays
        var groupcount = 0
        var allCount = 0
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
                let groupTotal = noticeList.children.count
                allCount += groupTotal
                while noticecount < groupTotal {
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

        var icount = 1
        for group in notices! {
            for notice in group {
                notice.setPositionDescription(icount, of: allCount)
                icount += 1
            }
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
    
    var positionDescription: String!
    
    // I'm guessing there is an assumed return from the init() method
    init(_ xml: XMLNode) {
        
        author = xml["author"]?.text
        
        shortcode = xml["shortcode"]?.text
        
        content = xml["content"]?.text
        html = xml["html"]?.description // We don't want to remove the html from this piece
    }
    
    public func setPositionDescription(_ count: Int!, of total: Int!) -> Void {
        positionDescription = "Notice " + String(count!) + " of " + String(total!)
    }
    
    public func getPositionDescription() -> String! {
        return positionDescription
    }
    
    
}
