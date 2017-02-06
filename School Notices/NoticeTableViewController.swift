//
//  NoticeTableViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 21/12/16.
//  Copyright © 2016 Focus Computing Pty Ltd. All rights reserved.
//

import UIKit

protocol NoticeListDelegate {
    // The failMessage will always have a string
    func failMessage(_: String)
    
    // On success
    func noticeListUpdated()
    
    // Called from the menu
    func slideMenuItemSelectedAtIndex(_ index : Int32)

    // Called when the date is changed by the user
    func dateSelected(_ date: Date) -> Void
    
    // Once we have received the dates from the server, slide the window in
    func slideDateSelection(_ slideIn: Bool) -> Void

    // Return the currentuser
    func getUser() -> User?
    
    // Return the current date
    func getCurrentDate() -> Date?
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
        } else {
            print("Failed to getUser from the delegate (RootViewDelegate)")
        }
        
        addSlideMenuButton()
    }
    
    public func getUser() -> User? {
        return delegate?.getUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = self.backupTitle
        
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    public func failMessage(_ msg: String) {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.title = msg
        }
    }
    
    public func noticeListUpdated() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        if let schoolDate = noticeList?.date {
            self.backupTitle = dateFormatter.string(from: schoolDate)
        }
        
        DispatchQueue.main.async {
            self.title = self.backupTitle
            self.spinner.stopAnimating()
            self.tableView.reloadData()
        }
    }
    
    public func dateSelected(_ date: Date) {
        noticeList?.date = date
        
        // Refresh the notice list
        if let cu = delegate?.getUser() {
            noticeList?.updateNotices(cu)
        } else {
            print("Failed to getUser from the delegate (RootViewDelegate)")
        }
    }
    
    public func getCurrentDate() -> Date? {
        return noticeList?.date
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        let cnt = noticeList?.count() ?? 0
        return cnt
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let groupname = noticeList?.groups?[section] {
            return groupname
        }
        return "[groupname \(section)]"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let cnt = noticeList?.count(section) ?? 0
        return cnt
    }

    
    private struct Storyboard {
        static let NoticeCellIdentifier = "NoticeCell"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.NoticeCellIdentifier, for: indexPath)
        let notice = noticeList?.retrieveNotice(indexPath.section, indexPath.row)
        cell.textLabel?.text = notice?.content
        return cell
    }
    
    // Perform segue to individual notice view
    var currentIndexPath: IndexPath!
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        currentIndexPath = indexPath
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
    
    
    
    // Slide Menu
    
    // Called from the menuVC
    func slideMenuItemSelectedAtIndex(_ index: Int32) {
        // let topViewController : UIViewController = self.navigationController!.topViewController!
        // print("View Controller is : \(topViewController) \n", terminator: "")
        switch(index){
        case 0: // Logoff
            
            if let del = delegate {
                if let user = del.getUser() {
                    user.logoff()
                }
                del.hasLoggedOff()
            }
            break
            
        case 1: // Change date
            
            slideDateSelection(true)
            break
            
        case 2: // Add notice
            let alert = UIAlertController(title: "Add notice not yet implemented", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
            
        default:
            break
        }
    }
    
    func openViewControllerBasedOnIdentifier(_ strIdentifier:String){
        let destViewController : UIViewController = self.storyboard!.instantiateViewController(withIdentifier: strIdentifier)
        
        let topViewController : UIViewController = self.navigationController!.topViewController!
        
        if (topViewController.restorationIdentifier! == destViewController.restorationIdentifier!){
            print("Same VC")
        } else {
            self.navigationController!.pushViewController(destViewController, animated: true)
        }
    }
    
    func addSlideMenuButton(){
        let btnShowMenu = UIButton(type: UIButtonType.system)
        btnShowMenu.setImage(self.defaultMenuImage(), for: UIControlState())
        btnShowMenu.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnShowMenu.addTarget(self, action: #selector(NoticeTableViewController.onSlideMenuButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        let customBarItem = UIBarButtonItem(customView: btnShowMenu)
        self.navigationItem.rightBarButtonItem = customBarItem;
    }
    
    func defaultMenuImage() -> UIImage {
        var defaultMenuImage = UIImage()
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 30, height: 22), false, 0.0)
        
        UIColor.black.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 3, width: 30, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 10, width: 30, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 17, width: 30, height: 1)).fill()
        
        UIColor.white.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 4, width: 30, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 11,  width: 30, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 18, width: 30, height: 1)).fill()
        
        defaultMenuImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return defaultMenuImage;
    }
    
    func onSlideMenuButtonPressed(_ sender : UIButton){
        if (sender.tag == 10)
        {
            
            // To Hide Menu If it already there
            self.slideMenuItemSelectedAtIndex(-1);
            
            
            sender.tag = 0;
            
            let viewMenuBack : UIView = view.subviews.last!
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                var frameMenu : CGRect = viewMenuBack.frame
                frameMenu.origin.x = UIScreen.main.bounds.size.width
                viewMenuBack.frame = frameMenu
                viewMenuBack.layoutIfNeeded()
                viewMenuBack.backgroundColor = UIColor.clear
            }, completion: { (finished) -> Void in
                viewMenuBack.removeFromSuperview()
            })
            
            return
        }
        
        
        sender.isEnabled = false
        sender.tag = 10
        
        let menuVC : MenuViewController = self.storyboard!.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        
        menuVC.btnMenu = sender
        menuVC.delegate = self
        self.view.addSubview(menuVC.view)
        self.addChildViewController(menuVC)
        menuVC.view.layoutIfNeeded()
        menuVC.view.backgroundColor = UIColor.clear
        
        menuVC.view.frame=CGRect(x: UIScreen.main.bounds.size.width, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height);
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            menuVC.view.frame=CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height);
            sender.isEnabled = true
        }, completion:nil)
    }
    
    
    internal func slideDateSelection(_ slideIn: Bool) {
        if slideIn {
            let dsVC : DateSelectionViewController = self.storyboard!.instantiateViewController(withIdentifier: "DateSelectionViewController") as! DateSelectionViewController
            
            dsVC.delegate = self
            self.view.addSubview(dsVC.view)
            self.addChildViewController(dsVC)
            dsVC.view.layoutIfNeeded()
            dsVC.view.backgroundColor = UIColor.clear
            
            dsVC.view.frame=CGRect(x: UIScreen.main.bounds.size.width, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height);
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                dsVC.view.frame=CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height);
            }, completion:nil)
            
        } else { // Slide out
            
            // I don't believe we are using this
            print("Not expecting slideDateSelection(false) to be called, but it is!")
            
            let viewMenuBack : UIView = view.subviews.last!
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                var frameMenu : CGRect = viewMenuBack.frame
                frameMenu.origin.x = UIScreen.main.bounds.size.width
                viewMenuBack.frame = frameMenu
                viewMenuBack.layoutIfNeeded()
                viewMenuBack.backgroundColor = UIColor.clear
            }, completion: { (finished) -> Void in
                viewMenuBack.removeFromSuperview()
            })

            
        }
    }
    

}
