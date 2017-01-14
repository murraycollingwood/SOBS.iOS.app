//
//  ViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 12/12/16.
//  Copyright © 2016 Focus Computing Pty Ltd. All rights reserved.
//


// importing a module
import UIKit
import WebKit

protocol NoticeViewDelegate {
    func getCurrentIndexPath() -> IndexPath?
    func nextIndexPath() -> IndexPath?
    func prevIndexPath() -> IndexPath?
    func getNotices() -> NoticeList?
}


class NoticeViewController: UIViewController {
    
    var delegate: NoticeViewDelegate?
    var notice: Notice!
    var notices: NoticeList!
    
    override func viewDidLoad() {
        print("NoticeViewController:viewDidLoad")
        if let allNotices = delegate?.getNotices() {
            print(" - we have loaded all notices")
            notices = allNotices
            if delegate == nil {
                print(" * the delegate is nil")
            }
            if let notice = retrieveNotice(delegate?.getCurrentIndexPath()) {
                print(" - display the noticearea with string = " + notice.html!)
                noticeArea.loadHTMLString(notice.html!, baseURL: nil)
            }
        }
    }
    
    // We should assert that notices
    private func retrieveNotice(_ indexPath: IndexPath?) -> Notice? {
        if let ip = indexPath {
            print(" - we have an indexPath \(ip.section),\(ip.row)")
            if let current = notices.retrieveNotice(ip) {
                print(" - we have retrieved a notice")
                return current
            }
        }
        return nil
    }

    @IBOutlet weak var noticeArea: WKWebView! {
        didSet {
            let swipeNext = UISwipeGestureRecognizer(target: self, action: #selector(NoticeViewController.nextButton))
            swipeNext.direction = .left
            noticeArea.addGestureRecognizer(swipeNext)

            let swipePrev = UISwipeGestureRecognizer(target: self, action: #selector(NoticeViewController.prevButton))
            swipePrev.direction = .right
            noticeArea.addGestureRecognizer(swipePrev)
        }
    }
    
    func nextButton(_ gesture: UIGestureRecognizer) {
        print(" - gesture next")
        if let notice = retrieveNotice(delegate?.nextIndexPath()) {
            print(" - display the noticearea with string = " + notice.html!)
            noticeArea.loadHTMLString(notice.html!, baseURL: nil)
        }

    }
    
    func prevButton(_ gesture: UIGestureRecognizer) {
        print(" - gesture prev")
        if let notice = retrieveNotice(delegate?.prevIndexPath()) {
            print(" - display the noticearea with string = " + notice.html!)
            noticeArea.loadHTMLString(notice.html!, baseURL: nil)
        }

    }
    
}

