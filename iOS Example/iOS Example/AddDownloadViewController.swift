//
//  AddDownloadViewController.swift
//  iOS Example
//
//  Created by Thibault Charbonnier on 13/01/15.
//  Copyright (c) 2015 Thibault Charbonnier. All rights reserved.
//

import UIKit
import TCBlobDownloadSwift

struct Download {
    var name: String
    var url: String
}

class AddDownloadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: DownloadsViewController?

    @IBOutlet weak var fieldURL: UITextField!
    
    @IBOutlet weak var fieldName: UITextField!

    let downloads = [ Download(name: "10MB", url: "http://ipv4.download.thinkbroadband.com/10MB.zip"),
                      Download(name: "50MB", url: "http://ipv4.download.thinkbroadband.com/50MB.zip"),
                      Download(name: "100MB", url: "http://ipv4.download.thinkbroadband.com/100MB.zip"),
                      Download(name: "512MB", url: "http://ipv4.download.thinkbroadband.com/512MB.zip") ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onAddDownload(_ sender: UIBarButtonItem) {
        self.addDownload(fromString: self.fieldURL.text!)
    }

    func addDownload(fromString string: String) {
        let downloadURL = URL(string: string)
        self.delegate?.addDownloadWithURL(downloadURL, name: self.fieldName.text)

        self.dismiss(animated: true, completion: nil)
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.downloads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addDownloadCell", for: indexPath) 

        cell.textLabel?.text = self.downloads[(indexPath as NSIndexPath).row].name
        
        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.fieldURL.text = self.downloads[(indexPath as NSIndexPath).row].url
        tableView.deselectRow(at: indexPath, animated: false)
    }

}
