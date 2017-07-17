//
//  PoliticianDetailViewController.swift
//  MyLocations
//
//  Created by John Shiver on 3/18/17.
//  Copyright © 2017 Razeware. All rights reserved.
//

import UIKit

class PoliticianDetailViewController: UIViewController, UIWebViewDelegate {

    var politician_url: String?
    var progressView: UIProgressView?
    var flag = true
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: make view controller delete for web view
        // so we can update progress view as updates are received
        let webView = UIWebView(frame: view.bounds)
        webView.scalesPageToFit = true
        webView.delegate = self

        if let politician_url = politician_url {
            let url = NSURL(string: politician_url)
            let request = NSURLRequest(url: url as! URL)
            webView.suppressesIncrementalRendering = true
            webView.loadRequest(request as URLRequest)
            view.addSubview(webView)

        }
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView!.center = view.center
        progressView!.trackTintColor = UIColor.lightGray
        progressView!.tintColor = UIColor.blue
        progressView!.progress = 0.1
        progressView!.isHidden = false
        progressView!.transform = CGAffineTransform(scaleX: 1, y: 6)
        webView.addSubview(progressView!)
        flag = true

    }

    override func viewWillAppear(_ animated: Bool) {
        let backButton: UIBarButtonItem = UIBarButtonItem(title: "Back",
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(back))
        self.navigationItem.leftBarButtonItem = backButton;
        super.viewWillAppear(animated);
    }

    func back() {
        self.dismiss(animated: true, completion: nil)
    }

    func startProgress() {
        print("Starting new timer")
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.1667, target: self,
                                         selector: #selector(PoliticianDetailViewController.timerCallback),
                                         userInfo: nil,
                                         repeats: true)
        }

    }


    func timerCallback() {
        print("called timer")
        if !self.flag {
            if self.progressView!.progress >= 1 {
                self.progressView!.isHidden = true
                self.timer!.invalidate()
            } else {
                self.progressView!.progress += 0.08
            }
        } else {
            self.progressView!.progress += 0.03
            if self.progressView!.progress >= 0.95 {
                self.progressView!.progress = 0.95
            }
        }

        if self.progressView!.isHidden {
            self.timer!.invalidate()
        }

    }

    func webViewDidStartLoad(_ webView: UIWebView) {
        print("Web load Started")
        if flag {
            startProgress()
        }
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("Web load Ended")
        flag = false
    }

}
