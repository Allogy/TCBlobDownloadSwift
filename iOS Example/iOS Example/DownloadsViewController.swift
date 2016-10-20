//
//  DownloadsViewController.swift
//  iOS Example
//
//  Created by Thibault Charbonnier on 12/01/15.
//  Copyright (c) 2015 Thibault Charbonnier. All rights reserved.
//

import Foundation
import UIKit
import TCBlobDownloadSwift

private let kDownloadCellidentifier = "downloadCellIdentifier"

class DownloadsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TCBlobDownloadDelegate {

    let manager = TCBlobDownloadManager.sharedInstance

    // Keep track of the current (and probably past soon) downloads
    // This is the tableview's data source
    var downloads = [TCBlobDownload]()

    @IBOutlet weak var downloadsTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "DownloadTableViewCell", bundle: nil)
        self.downloadsTableView.register(nib, forCellReuseIdentifier: kDownloadCellidentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAddDownload" {
            let destinationNC = segue.destination as! UINavigationController
            let destinationVC = destinationNC.topViewController as! AddDownloadViewController
            destinationVC.delegate = self
        }
    }

    fileprivate func getDownloadFromButtonPress(_ sender: UIButton, event: UIEvent) -> (download: TCBlobDownload, indexPath: IndexPath) {
        let touch = event.touches(for: sender)?.first
        let location = touch?.location(in: self.downloadsTableView)
        let indexPath = self.downloadsTableView.indexPathForRow(at: location!)

        return (self.downloads[indexPath!.row], indexPath!)
    }

    // MARK: Downloads management

    func addDownloadWithURL(_ url: URL?, name: String?) {
        let download = self.manager.downloadFileAtURL(url!, toDirectory: nil, withName: name, andDelegate: self)
        self.downloads.append(download)

        let insertIndexPath = IndexPath(row: self.downloads.count - 1, section: 0)
        self.downloadsTableView.insertRows(at: [insertIndexPath], with: .automatic)
    }

    func didPressPauseButton(_ sender: UIButton!, event: UIEvent) {
        let e = self.getDownloadFromButtonPress(sender, event: event)

        if e.download.downloadTask.state == URLSessionTask.State.running {
           e.download.suspend()
        } else {
            e.download.resume()
        }

        self.downloadsTableView.reloadRows(at: [e.indexPath as IndexPath], with: UITableViewRowAnimation.none)
    }

    func didPressCancelButton(_ sender: UIButton!, event: UIEvent) {
        let e = self.getDownloadFromButtonPress(sender, event: event)

        e.download.cancel()
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.downloads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kDownloadCellidentifier) as! DownloadTableViewCell
        let download: TCBlobDownload = self.downloads[indexPath.row]

        if let fileName = download.fileName {
            cell.labelFileName.text = fileName
        } else {
            cell.labelFileName.text = "..."
        }

        if download.downloadTask.state == URLSessionTask.State.running {
            cell.buttonPause.setTitle("Pause", for: UIControlState())
        } else if download.downloadTask.state == URLSessionTask.State.suspended {
            cell.buttonPause.setTitle("Resume", for: UIControlState())
        }

        cell.progress = download.progress
        cell.labelDownload.text = download.downloadTask.originalRequest?.url?.absoluteString
        cell.buttonPause.addTarget(self, action: #selector(DownloadsViewController.didPressPauseButton(_:event:)), for: UIControlEvents.touchUpInside)
        cell.buttonCancel.addTarget(self, action: #selector(DownloadsViewController.didPressCancelButton(_:event:)), for: UIControlEvents.touchUpInside)

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    // MARK: TCBlobDownloadDelegate

    func download(_ download: TCBlobDownload, didProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let downloads: NSArray = self.downloads as NSArray
        let index = downloads.index(of: download)
        let updateIndexPath = IndexPath(row: index, section: 0)

        let cell = self.downloadsTableView.cellForRow(at: updateIndexPath) as! DownloadTableViewCell
        cell.progress = progress
    }

    func download(_ download: TCBlobDownload, didFinishWithError: NSError?, atLocation location: URL?) {
        let downloads: NSArray = self.downloads as NSArray
        let index = downloads.index(of: download)
        self.downloads.remove(at: index)

        
        let deleteIndexPath = IndexPath(row: index, section: 0)
        self.downloadsTableView.deleteRows(at: [deleteIndexPath], with: .automatic)
    }

}
