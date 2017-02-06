//
//  MenuViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 27/1/17.
//  Copyright © 2017 Focus Computing Pty Ltd. All rights reserved.
//

import UIKit


class MenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if (arrayMenuOptions.count == 0) {
            updateArrayMenuOptions()
        }
        
        tblMenuOptions.dataSource = self
        tblMenuOptions.delegate = self
        
    }

    @IBOutlet weak var tblMenuOptions: UITableView!
    @IBOutlet weak var btnCloseMenuOverlay: UIButton!
    
    var arrayMenuOptions = [Dictionary<String,String>]()
    
    var btnMenu : UIButton!
    
    var delegate : NoticeListDelegate?
    
    
    public func dateSelected(_ date: Date) {
        delegate?.dateSelected(date)
    }
    
    func updateArrayMenuOptions(){
        arrayMenuOptions.append(["title":"Logoff",      "icon":"PowerIcon"])
        arrayMenuOptions.append(["title":"Change date", "icon":"CalendarIcon"])
        arrayMenuOptions.append(["title":"Add notice",  "icon":"PlusIcon"])
        
        tblMenuOptions.reloadData()
        
        // Adjust the height of the menu based on the number of entries
        tblMenuOptions.frame.size.height = CGFloat((44 * arrayMenuOptions.count))
        self.view.layoutIfNeeded()
    }

    
    // If the button is clicked above the menu, or a menu option is clicked
    @IBAction func onCloseMenuClick(_ button: UIButton) {
        btnMenu.tag = 0
        
        if (self.delegate != nil) {
            var index = Int32(button.tag)
            if(button == self.btnCloseMenuOverlay){
                index = -1
            }
            
            // Passback the index to the delegate
            delegate?.slideMenuItemSelectedAtIndex(index)
        }
        
        // Close the menu
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
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cellMenu")!
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = UIColor.white
        
        cell.imageView?.image = UIImage(named: arrayMenuOptions[indexPath.row]["icon"]!)
        cell.textLabel?.text = arrayMenuOptions[indexPath.row]["title"]!
        
        return cell
    }
    
    // If a menu option is selected, set the tag and call the close button method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let btn = UIButton(type: UIButtonType.custom)
        btn.tag = indexPath.row
        self.onCloseMenuClick(btn)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayMenuOptions.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    
}
