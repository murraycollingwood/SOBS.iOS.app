//
//  SchoolTableViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 14/1/17.
//  Copyright © 2017 Focus Computing Pty Ltd. All rights reserved.
//

import UIKit

class SchoolTableViewController: UITableViewController, UISearchBarDelegate, SoapResponse {

    var delegate: LoginViewController!
    var currentUser: User!

    var schoolids: [Int] = []
    var schools: [String] = []
    var strategy: String = "" {
        didSet {
            schools.removeAll()
            searchForSchools()
        }
    }
    
    private func searchForSchools() -> Void {
        
        // Reset the result areas
        schools = []
        schoolids = []
        
        var nodes: [XMLNode] = []
        let findSchoolNode: XMLNode = XMLNode(name: "findschool")
        findSchoolNode.text = strategy
        let authNode: XMLNode = XMLNode(name: "authentication")
        authNode.addChild(findSchoolNode)
        nodes.append(authNode)
        
        weak var weakSelf = self
        Soap.call(url: sobsurl, withXMLRequests: nodes, from: weakSelf)
    }
    
    func soapFailed(code: Int!, errorObject: Any!) {
        if let msg = errorObject as? String {
            searchFailure(msg)
        } else {
            searchFailure("Error \(code)")
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
                                if let schoolList: XMLNode = response["school-list"] {
                                    self.createFromXML(schoolList)
                                }
                            } else {
                                // print("Authentication failed")
                                if let msg = response["result"]?.text {
                                    searchFailure(msg)
                                }
                            }
                            
                        default :
                            break; // print("Unknown function: " + response.attributes["function"]!)
                        }
                    }
                    count += 1
                }
                
            }
            
        }
    }
    
    // We will need a couple of constructors, one from the local database, one from the XML
    public func createFromXML(_ schoolList: XMLNode) {
        
        // Read the XML and create the arrays
        var col: [String] = []
        var ids: [Int] = []
        var schoolcount = 0
        while schoolcount < schoolList.children.count {
            let schoolNode: XMLNode = schoolList.children[schoolcount]
            col.append((schoolNode["name"]?.text)!)
            ids.append(Int((schoolNode["id"]?.text)!)!)
            
            // Increment
            schoolcount += 1
        }
        
        // Set schools in one hit so we don't keep running didSet
        schools.append(contentsOf: col)
        schoolids.append(contentsOf: ids)
        
        /**
        for schoolname in schools {
            print("school: \(schoolname)")
        } **/
        
        DispatchQueue.main.async {
            self.stableView.reloadData()
        }
    }
    
    private func searchFailure(_ msg: String!) -> Void {
        schools = ["[** " + msg + " **]"]
        DispatchQueue.main.async {
            self.stableView.reloadData()
        }

    }

    
    
    @IBOutlet weak var stableView: UITableView!
    @IBOutlet weak var searchbar: UISearchBar! {
        didSet {
            searchbar.delegate = self
            searchbar.text = strategy
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        strategy = searchBar.text!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        stableView.delegate = self
        stableView.dataSource = self
    }

    // MARK: - Table view data source

    // override func numberOfSections(in tableView: UITableView) -> Int  (Defaults to 1)
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schools.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "schoolname", for: indexPath)
        cell.textLabel?.text = schools[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        // If it was an error message then we don't want to go anywhere... get them to search again
        if schoolids.count > indexPath.row {
            let sid = schoolids[indexPath.row]
            if let del = delegate {
                let row = indexPath.row
                del.schoolSelected(schoolId: sid, schoolName: schools[row])
            }
            // print(" => the segue to LoginView should happen now, with (\(indexPath.section),\(indexPath.row))")
        }
    }



}
