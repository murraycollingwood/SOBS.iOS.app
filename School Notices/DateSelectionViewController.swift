//
//  DateSelectionViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 6/2/17.
//  Copyright © 2017 Focus Computing Pty Ltd. All rights reserved.
//

import UIKit

class DateSelectionViewController: UIViewController,
                UITableViewDataSource, UITableViewDelegate,
                SoapResponse {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if (arrayDateOptions.count == 0) {
            updateArrayDateOptions()
        }
        
        dsTableView.dataSource = self
        dsTableView.delegate = self

    }
    
    
    var delegate : NoticeListDelegate!

    @IBOutlet weak var dsTableView: UITableView!

    var arrayDateOptions = [Date]()
    
    
    func updateArrayDateOptions() {
        // We can request a timetable from the server, but which dates do we want?  
        // Are we looking into the future or the past?
        // For now, let's assume we can go forward or backwards 2 weeks
        
        if let currentUser = delegate?.getUser() {

            var nodes: [XMLNode] = []
            var dateFrom: Date
            var dateTo: Date
            
            nodes.append(currentUser.asXMLRequest(application: application))
            
            if let currentDate = delegate?.getCurrentDate() {
                dateFrom = currentDate.addingTimeInterval(60 * 60 * 24 * -14)
                dateTo = currentDate.addingTimeInterval(60 * 60 * 24 * 14)
            } else {
                dateFrom = Date().addingTimeInterval(60 * 60 * 24 * -14)
                dateTo = Date().addingTimeInterval(60 * 60 * 24 * 14)
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let gettimetable = XMLNode(name: "getTimetable");
            gettimetable.addChild(name: "dateFrom", value: dateFormatter.string(from: dateFrom))
            gettimetable.addChild(name: "dateTo", value: dateFormatter.string(from: dateTo))
            nodes.append(gettimetable)
            
            weak var weakSelf = self
            Soap.call(url: sobsurl, withXMLRequests: nodes, from: weakSelf)
            
        } else {
            print("Error retrieving the timetable: Unable to determine the currentuser")
        }

        
        /***
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // date is an attribute on the group-list
        arrayDateOptions.append(dateFormatter.date(from: "2017-01-30")!)
        arrayDateOptions.append(dateFormatter.date(from: "2017-02-02")!)
        arrayDateOptions.append(dateFormatter.date(from: "2017-02-03")!)
        
        dsTableView.reloadData()
         ***/
    }
    
    func alert(_ msg: String!) {
        let alert = UIAlertController(title: msg, message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func soapFailed(code: Int!, errorObject: Any!) {
        if let msg = errorObject as? String {
            alert(msg)
        } else {
            alert("Error \(code)")
        }
    }
    
    func soapSuccess(xml: XMLNode!) {
        let responses = xml
        if responses != nil {
            
            var count = 0
            while count < (responses?.children.count)! {
                let response:XMLNode = (responses?[count])!
                // print("responses[\(count)] = " + response.description)
                if response.name == "response" { // Ignore the "result"
                    switch response.attributes["function"]! {
                    case "getTimetable" :
                        if response["result"]?.attributes["code"]! == "100" {
                            // print("getNotices = 100")
                            if let dateList: XMLNode = response["date-list"] {
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd"

                                arrayDateOptions = []
                                var datecount = 0
                                while datecount < dateList.children.count {
                                    let date: XMLNode = dateList.children[datecount]
                                    if date["prefix"]?.text == "D" {
                                        arrayDateOptions.append(dateFormatter.date(from: (date["actualDate"]?.text)!)!)
                                    }
                                    datecount += 1
                                }
                            }
                            
                        } else {
                            // print("getTimetable failed")
                            if let code = response["result"]?.attributes["code"] {
                                if let msg = response["result"]?.text {
                                    alert(msg + " (\(code))")
                                }
                            }
                        }
                    default :
                        break // print("Unknown function: " + response.attributes["function"]!)
                    }
                }
                count += 1
            }

            DispatchQueue.main.async {
                self.dsTableView.reloadData()
            }
        }
    }
    
    private func dateSelected(_ thedate: Date) {
        
        // Passback the date
        delegate.dateSelected(thedate)
  
        // Close the date selection
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.view.frame = CGRect(x: UIScreen.main.bounds.size.width, y: 0, width: UIScreen.main.bounds.size.width,height: UIScreen.main.bounds.size.height)
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.clear
        }, completion: { (finished) -> Void in
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        })

    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "dateCell")!
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = UIColor.white
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        cell.textLabel?.text = dateFormatter.string(from: arrayDateOptions[indexPath.row] )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Here we need the call back to the menu, to roll back the dateselection view
        self.dateSelected(arrayDateOptions[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayDateOptions.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
 

}
