//
//  TCBlobDownload.swift
//  TCBlobDownloadSwift
//
//  Created by Thibault Charbonnier on 30/12/14.
//  Copyright (c) 2014 thibaultcha. All rights reserved.
//

let kTCBlobDownloadQueueKey = "com.tcblobdownloadswift.queue"

import Foundation

public typealias progressionHandler = ((progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void)!
public typealias completionHandler = ((error: NSError?, location: NSURL?) -> Void)!

public class TCBlobDownload {
    /// The underlying download task.
    public let downloadTask: NSURLSessionDownloadTask

    /// An optional delegate to get notified of events.
    public weak var delegate: TCBlobDownloadDelegate?

    /// An optional progression closure periodically executed when a chunk of data has been received.
    public var progression: progressionHandler

    /// An optional completion closure executed when a download was completed by the download task.
    public var completion: completionHandler

    /// An optional file name set by the user.
    private let preferedFileName: String?

    /// An optional destination path for the file. If nil, the file will be downloaded in the current user temporary directory.
    public let directory: NSURL?

    /// Will contain an error if the downloaded file couldn't be moved to its final destination.
    var error: NSError?

    /// Current progress of the download, a value between 0 and 1. 0 means nothing was received and 1 means the download is completed.
    public var progress: Float = 0

    /// If the moving of the file after downloading was successful, will contain the `NSURL` pointing to the final file.
    public var resultingURL: NSURL?

    /// A computed property to get the filename of the downloaded file.
    public var fileName: String? {
        return self.preferedFileName ?? self.downloadTask.response?.suggestedFilename
    }

    /// A computed destination URL depending on the `destinationPath`, `fileName`, and `suggestedFileName` from the underlying `NSURLResponse`.
    public var destinationURL: NSURL {
        let destinationPath = self.directory ?? NSURL(fileURLWithPath: NSTemporaryDirectory())

        return NSURL(string: self.fileName!, relativeToURL: destinationPath)!.URLByStandardizingPath!
    }

    /**
        Initialize a new download assuming the `NSURLSessionDownloadTask` was already created.
    
        - parameter downloadTask: The underlying download task for this download.
        - parameter directory: The directory where to move the downloaded file once completed.
        - parameter fileName: The preferred file name once the download is completed.
        - parameter delegate: An optional delegate for this download.
    */
    init(downloadTask: NSURLSessionDownloadTask, toDirectory directory: NSURL?, fileName: String?, delegate: TCBlobDownloadDelegate?) {
        self.downloadTask = downloadTask
        self.directory = directory
        self.preferedFileName = fileName
        self.delegate = delegate
    }

    /**
        
    */
    convenience init(downloadTask: NSURLSessionDownloadTask, toDirectory directory: NSURL?, fileName: String?, progression: progressionHandler?, completion: completionHandler?) {
        self.init(downloadTask: downloadTask, toDirectory: directory, fileName: fileName, delegate: nil)
        self.progression = progression
        self.completion = completion
    }

    /**
        Cancel a download. The download cannot be resumed after calling this method.
    
        :see: `NSURLSessionDownloadTask -cancel`
    */
    public func cancel() {
        self.downloadTask.cancel()
    }

    /**
        Suspend a download. The download can be resumed after calling this method.
    
        :see: `TCBlobDownload -resume`
        :see: `NSURLSessionDownloadTask -suspend`
    */
    public func suspend() {
        self.downloadTask.suspend()
    }

    /**
        Resume a previously suspended download. Can also start a download if not already downloading.
    
        :see: `NSURLSessionDownloadTask -resume`
    */
    public func resume() {
        self.downloadTask.resume()
    }

    /**
        Cancel a download and produce resume data. If stored, this data can allow resuming the download at its previous state.

        :see: `TCBlobDownloadManager -downloadFileWithResumeData`
        :see: `NSURLSessionDownloadTask -cancelByProducingResumeData`

        - parameter completionHandler: A completion handler that is called when the download has been successfully canceled. If the download is resumable, the completion handler is provided with a resumeData object.
    */
    public func cancelWithResumeData(completionHandler: (NSData?) -> Void) {
        self.downloadTask.cancelByProducingResumeData(completionHandler)
    }

    // TODO: remaining time
    // TODO: instanciable TCBlobDownloads
}

public protocol TCBlobDownloadDelegate: class {
    /**
        Periodically informs the delegate that a chunk of data has been received (similar to `NSURLSession -URLSession:dataTask:didReceiveData:`).
    
        :see: `NSURLSession -URLSession:dataTask:didReceiveData:`
    
        - parameter download: The download that received a chunk of data.
        - parameter progress: The current progress of the download, between 0 and 1. 0 means nothing was received and 1 means the download is completed.
        - parameter totalBytesWritten: The total number of bytes the download has currently written to the disk.
        - parameter totalBytesExpectedToWrite: The total number of bytes the download will write to the disk once completed.
    */
    func download(download: TCBlobDownload, didProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)

    /**
        Informs the delegate that the download was completed (similar to `NSURLSession -URLSession:task:didCompleteWithError:`).
    
        :see: `NSURLSession -URLSession:task:didCompleteWithError:`
    
        - parameter download: The download that received a chunk of data.
        - parameter error: An eventual error. If `nil`, consider the download as being successful.
        - parameter location: The location where the downloaded file can be found.
    */
    func download(download: TCBlobDownload, didFinishWithError error: NSError?, atLocation location: NSURL?)
}

// MARK: Printable

extension TCBlobDownload: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        var state: String
        
        switch self.downloadTask.state {
            case .Running: state = "running"
            case .Completed: state = "completed"
            case .Canceling: state = "canceling"
            case .Suspended: state = "suspended"
        }
        
        parts.append("TCBlobDownload")
        parts.append("URL: \(self.downloadTask.originalRequest!.URL)")
        parts.append("Download task state: \(state)")
        parts.append("destinationPath: \(self.directory)")
        parts.append("fileName: \(self.fileName)")
        
        return parts.joinWithSeparator(" | ")
    }
}

class TCBlobDownloadArchivable: NSObject, NSCoding {
    let fileName: String?
    let directory: String?
    var resumeData: NSData?

    init(taskIdentifier: String, fileName: String?, directory: String?) {
        self.fileName = fileName
        self.directory = directory
    }

    required init?(coder aDecoder: NSCoder) {
        self.fileName = aDecoder.decodeObjectForKey("fileName") as? String
        self.directory = aDecoder.decodeObjectForKey("directory") as? String
        self.resumeData = aDecoder.decodeObjectForKey("resumeData") as? NSData
        super.init()
    }

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.fileName, forKey: "fileName")
        aCoder.encodeObject(self.directory, forKey: "directory")
        aCoder.encodeObject(self.resumeData, forKey: "resumeData")
    }

    class func taskQueue() -> [String: TCBlobDownloadArchivable]? {
        let data = NSUserDefaults.standardUserDefaults().dataForKey(kTCBlobDownloadQueueKey)

        if let d = data {
            return NSKeyedUnarchiver.unarchiveObjectWithData(d)  as? [String : TCBlobDownloadArchivable]
        }
        return nil
    }

    func saveForTaskIdentifier(taskIdentifier: String) {
        var downloads: [String: TCBlobDownloadArchivable] = [:]
        if let d = TCBlobDownloadArchivable.taskQueue() {
            downloads = d
        }

        downloads[taskIdentifier] = self

        let archive = NSKeyedArchiver.archivedDataWithRootObject(downloads)
        NSUserDefaults.standardUserDefaults().setObject(archive, forKey: kTCBlobDownloadQueueKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    class func deleteForTaskIdentifier(taskIdentifier: String) {
        if var d = TCBlobDownloadArchivable.taskQueue() {
            d.removeValueForKey(taskIdentifier)

            let archive = NSKeyedArchiver.archivedDataWithRootObject(d)
            NSUserDefaults.standardUserDefaults().setObject(archive, forKey: kTCBlobDownloadQueueKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    func downloadForTask(downloadTask: NSURLSessionDownloadTask) -> TCBlobDownload {
        return TCBlobDownload(downloadTask: downloadTask, toDirectory: self.directory != nil ? NSURL(fileURLWithPath: self.directory!, isDirectory: true) : nil, fileName: self.fileName, delegate: nil)
    }

    class func existingArchivableDownloadForTask(task: NSURLSessionDownloadTask) -> TCBlobDownloadArchivable? {
        if let downloads = TCBlobDownloadArchivable.taskQueue() {
            return downloads[String(task.taskIdentifier)]
        }
        return nil
    }

    class func downloadsForURLSession(session: NSURLSession, completion: ([Int : TCBlobDownload]) -> Void) {

        var downloads: [Int : TCBlobDownload] = [:]

        session.getTasksWithCompletionHandler { (data, uploadTasks, downloadTasks) -> Void in
            
            for t in downloadTasks {
                let task = t 
                let download = TCBlobDownloadArchivable.existingArchivableDownloadForTask(task)
                if let d = download {
                    downloads[task.taskIdentifier] = d.downloadForTask(task)
                }
            }
            completion(downloads)
        }
    }

    override var description: String {
        var parts: [String] = []

        parts.append("TCBlobDownloadArchivable")
        if let f = self.fileName {
            parts.append("fileName: \(f)")
        }
        if let d = self.directory {
            parts.append("destinationPath: \(d)")
        }
        parts.append("Has resumeData: \(self.resumeData != nil ? true : false)")

        return parts.joinWithSeparator(" | ")
    }
}

extension TCBlobDownload {
    
    func save() {
        let archivable = TCBlobDownloadArchivable(taskIdentifier: String(self.downloadTask.taskIdentifier), fileName: self.fileName, directory: self.directory != nil ? self.directory!.path : nil)
        archivable.saveForTaskIdentifier(String(self.downloadTask.taskIdentifier))
    }

    func delete() {
        TCBlobDownloadArchivable.deleteForTaskIdentifier(String(self.downloadTask.taskIdentifier))
    }

    func archive() -> TCBlobDownloadArchivable? {
        if var tasks = TCBlobDownloadArchivable.taskQueue() {
            if let task = tasks[String(self.downloadTask.taskIdentifier)] {
                return task
            }
        }
        return nil
    }
}
