//
//  ViewController.swift
//  School Notices
//
//  Created by Murray Collingwood on 12/12/16.
//  Copyright © 2016 Focus Computing Pty Ltd. All rights reserved.
//


// importing a module
import UIKit

protocol NoticeViewDelegate {
    func getCurrentIndexPath() -> IndexPath?
    func nextIndexPath() -> IndexPath?
    func prevIndexPath() -> IndexPath?
    func getNotices() -> NoticeList?
}


class NoticeViewController: UIViewController, UIWebViewDelegate { 
    
    var delegate: NoticeViewDelegate?
    var notice: Notice!
    var notices: NoticeList!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noticeArea.delegate = self
        if let allNotices = delegate?.getNotices() {
            notices = allNotices
            if let del = delegate {
                if let notice = retrieveNotice(del.getCurrentIndexPath()) {
                    DispatchQueue.main.async {
                        self.noticeArea.loadHTMLString(notice.html!, baseURL: baseurl)
                        // print("html = \(notice.html!)")
                    }
                }
            }
        }
    }


    // We should assert that notices
    private func retrieveNotice(_ indexPath: IndexPath?) -> Notice? {
        if let ip = indexPath {
            if let current = notices.retrieveNotice(ip) {
                counter.text = current.getPositionDescription()
                return current
            }
        }
        return nil
    }

    @IBOutlet weak var counter: UILabel!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    @IBOutlet weak var noticeArea: UIWebView! {
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
        if let notice = retrieveNotice(delegate?.nextIndexPath()) {
            noticeArea.loadHTMLString(notice.html!, baseURL: baseurl)
        }

    }
    
    func prevButton(_ gesture: UIGestureRecognizer) {
        if let notice = retrieveNotice(delegate?.prevIndexPath()) {
            noticeArea.loadHTMLString(notice.html!, baseURL: baseurl)
        }

    }
   
    func webViewDidStartLoad(_ webView : UIWebView) {
        self.spinner.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView : UIWebView) {
        self.spinner.stopAnimating()
    }
}

