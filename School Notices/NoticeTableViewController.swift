//
//  NoticeTableViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 21/12/16.
//  Copyright © 2016 Focus Computing Pty Ltd. All rights reserved.
//

import UIKit

protocol NoticeTableViewDelegate {
}

class NoticeTableViewController: UIViewController,
    NoticeListDelegate, NoticeViewDelegate,
    UITableViewDelegate, UITableViewDataSource {
    
    var noticeList: NoticeList?
    var delegate: RootViewDelegate?
    
    var backupTitle: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.sectionIndexColor = UIColor.white
        tableView.sectionIndexBackgroundColor = UIColor.black
        
        backupTitle = "00-00-0000"

        // If there is no data then we need to retrieve some
        spinner.startAnimating()
        noticeList = NoticeList()
        noticeList?.delegate = self
        if let cu = delegate?.getUser() {
            noticeList?.updateNotices(cu)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = self.backupTitle
        
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    public func failMessage(_ msg: String) {
        self.spinner.stopAnimating()
        self.title = msg
    }
    
    public func noticeListUpdated() {
        print("noticeListUpdated - we got called!")
        print(" - noticeList.count = " + String(describing: noticeList?.count()))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        if let schoolDate = noticeList?.date {
            self.backupTitle = dateFormatter.string(from: schoolDate)
            self.title = self.backupTitle
        }
        
        self.spinner.stopAnimating()
        print(" - request reloadData()")
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        let cnt = noticeList?.count() ?? 0
        print("++ asking for numberOfSections = \(cnt)")
        return cnt
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let groupname = noticeList?.groups?[section] {
            print("displaying groupname = \(groupname)")
            return groupname
        }
        return "[groupname \(section)]"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let cnt = noticeList?.count(section) ?? 0
        print("++ asking for numberOfRowsInSection(\(section)) = \(cnt)")
        return cnt
    }

    
    private struct Storyboard {
        static let NoticeCellIdentifier = "NoticeCell"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.NoticeCellIdentifier, for: indexPath)

        // Configure the cell...
        print("++ setting cell text for \(indexPath.section) by \(indexPath.row)")
        let notice = noticeList?.retrieveNotice(indexPath.section, indexPath.row)
        cell.textLabel?.text = notice?.content
        return cell
    }
    
    // Perform segue to individual notice view
    var currentIndexPath: IndexPath!
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        currentIndexPath = indexPath
        print(" => the segue to ShowNotice should happen now, with (\(indexPath.section),\(indexPath.row))")
        // performSegue(withIdentifier: "ShowNotice", sender: self)
    }
    
    public func getNotices() -> NoticeList? {
        if noticeList == nil { return nil }
        return noticeList
    }
    
    public func getCurrentIndexPath() -> IndexPath? {
        if currentIndexPath == nil { return nil }
        return currentIndexPath
    }
    
    public func nextIndexPath() -> IndexPath? {
        if currentIndexPath == nil { return nil }
        let sect = currentIndexPath.section
        let row = currentIndexPath.row
        
        // move within the current section
        if let list = noticeList {
            let maxrow = list.count(sect)
            if (row+1) < maxrow {
                currentIndexPath = IndexPath(row: (row+1), section: sect)
                return currentIndexPath
            }
            
            // we need to bump the section
            let maxsect = list.count()
            if (sect+1) < maxsect {
                currentIndexPath = IndexPath(row: 0, section: (sect+1))
                return currentIndexPath
            }
        }
        
        return nil
    }
 
    public func prevIndexPath() -> IndexPath? {
        if currentIndexPath == nil { return nil }
        let sect = currentIndexPath.section
        let row = currentIndexPath.row
        
        // move within the current section
        if let list = noticeList {
            if row > 0 {
                currentIndexPath = IndexPath(row: (row-1), section: sect)
                return currentIndexPath
            }
            
            // we need to bump the section
            if sect > 0 {
                let maxrow = list.count(sect-1)
                currentIndexPath = IndexPath(row: (maxrow-1), section: (sect-1))
                return currentIndexPath
            }
        }
        
        return nil
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
        case "ShowNotice":
            if let noticevc = destvc as? NoticeViewController {
                noticevc.delegate = self
            }
            
        default: break
        }
    }
    

}
