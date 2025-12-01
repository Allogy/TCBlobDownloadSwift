//
//  TCBlobDownload.swift
//  TCBlobDownloadSwift
//
//  Created by Thibault Charbonnier on 30/12/14.
//  Copyright (c) 2014 thibaultcha. All rights reserved.
//

let kTCBlobDownloadQueueKey = "com.tcblobdownloadswift.queue"

import Foundation

public typealias progressionHandler = ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)
public typealias completionHandler = ((_ download: TCBlobDownload, _ error: NSError?, _ location: URL?) -> Void)

open class TCBlobDownload: @unchecked Sendable {
    /// The underlying download task.
    public let downloadTask: URLSessionDownloadTask

    /// An optional delegate to get notified of events.
    open weak var delegate: TCBlobDownloadDelegate?

    /// An optional progression closure periodically executed when a chunk of data has been received.
    open var progression: progressionHandler?

    /// An optional completion closure executed when a download was completed by the download task.
    open var completion: completionHandler?

    /// An optional file name set by the user.
    fileprivate let preferedFileName: String?

    /// An optional destination path for the file. If nil, the file will be downloaded in the current user temporary directory.
    public let directory: URL?

    /// Will contain an error if the downloaded file couldn't be moved to its final destination.
    var error: NSError?

    /// Current progress of the download, a value between 0 and 1. 0 means nothing was received and 1 means the download is completed.
    open var progress: Float = 0

    /// If the moving of the file after downloading was successful, will contain the `NSURL` pointing to the final file.
    open var resultingURL: URL?

    /// A computed property to get the filename of the downloaded file.
    open var fileName: String? {
        return self.preferedFileName ?? self.downloadTask.response?.suggestedFilename
    }

    /// A computed destination URL depending on the `destinationPath`, `fileName`, and `suggestedFileName` from the underlying `NSURLResponse`.
    open var destinationURL: URL {
        let destinationPath = self.directory ?? URL(fileURLWithPath: NSTemporaryDirectory())

        
        return URL(string: self.fileName!, relativeTo: destinationPath)!.standardized
    }

    fileprivate let sessionConfigurationIdentifier: String
    /**
        Initialize a new download assuming the `NSURLSessionDownloadTask` was already created.
    
        - parameter downloadTask: The underlying download task for this download.
        - parameter directory: The directory where to move the downloaded file once completed.
        - parameter fileName: The preferred file name once the download is completed.
        - parameter delegate: An optional delegate for this download.
    */
    init(downloadTask: URLSessionDownloadTask, toDirectory directory: URL?, fileName: String?, delegate: TCBlobDownloadDelegate?, sessionConfigurationIdentifier: String) {
        self.downloadTask = downloadTask
        self.directory = directory
        self.preferedFileName = fileName
        self.delegate = delegate
        self.sessionConfigurationIdentifier = sessionConfigurationIdentifier
    }

    /**
        
    */
    convenience init(downloadTask: URLSessionDownloadTask, toDirectory directory: URL?, fileName: String?, sessionConfigurationIdentifier: String, progression: progressionHandler?, completion: completionHandler?) {
        self.init(downloadTask: downloadTask, toDirectory: directory, fileName: fileName, delegate: nil, sessionConfigurationIdentifier: sessionConfigurationIdentifier)
        self.progression = progression
        self.completion = completion
    }

    /**
        Cancel a download. The download cannot be resumed after calling this method.
    
        :see: `NSURLSessionDownloadTask -cancel`
    */
    open func cancel() {
        self.downloadTask.cancel()
    }

    /**
        Suspend a download. The download can be resumed after calling this method.
    
        :see: `TCBlobDownload -resume`
        :see: `NSURLSessionDownloadTask -suspend`
    */
    open func suspend() {
        self.downloadTask.suspend()
    }

    /**
        Resume a previously suspended download. Can also start a download if not already downloading.
    
        :see: `NSURLSessionDownloadTask -resume`
    */
    open func resume() {
        self.downloadTask.resume()
    }

    /**
        Cancel a download and produce resume data. If stored, this data can allow resuming the download at its previous state.

        :see: `TCBlobDownloadManager -downloadFileWithResumeData`
        :see: `NSURLSessionDownloadTask -cancelByProducingResumeData`

        - parameter completionHandler: A completion handler that is called when the download has been successfully canceled. If the download is resumable, the completion handler is provided with a resumeData object.
    */
	open func cancelWithResumeData(_ completionHandler: @escaping @Sendable (Data?) -> Void) {
        self.downloadTask.cancel(byProducingResumeData: completionHandler)
    }

    // TODO: remaining time
    // TODO: instanciable TCBlobDownloads
}

public protocol TCBlobDownloadDelegate: AnyObject {
    /**
        Periodically informs the delegate that a chunk of data has been received (similar to `NSURLSession -URLSession:dataTask:didReceiveData:`).
    
        :see: `NSURLSession -URLSession:dataTask:didReceiveData:`
    
        - parameter download: The download that received a chunk of data.
        - parameter progress: The current progress of the download, between 0 and 1. 0 means nothing was received and 1 means the download is completed.
        - parameter totalBytesWritten: The total number of bytes the download has currently written to the disk.
        - parameter totalBytesExpectedToWrite: The total number of bytes the download will write to the disk once completed.
    */
    func download(_ download: TCBlobDownload, didProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)

    /**
        Informs the delegate that the download was completed (similar to `NSURLSession -URLSession:task:didCompleteWithError:`).
    
        :see: `NSURLSession -URLSession:task:didCompleteWithError:`
    
        - parameter download: The download that received a chunk of data.
        - parameter error: An eventual error. If `nil`, consider the download as being successful.
        - parameter location: The location where the downloaded file can be found.
    */
    func download(_ download: TCBlobDownload, didFinishWithError error: NSError?, atLocation location: URL?)
}

// MARK: Printable

extension TCBlobDownload: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        var state: String
        
        switch self.downloadTask.state {
            case .running: state = "running"
            case .completed: state = "completed"
            case .canceling: state = "canceling"
            case .suspended: state = "suspended"
            @unknown default: state = "suspended"
        }
        
        parts.append("TCBlobDownload")
        parts.append("URL: \(String(describing: self.downloadTask.originalRequest!.url))")
        parts.append("Download task state: \(state)")
        parts.append("destinationPath: \(String(describing: self.directory))")
        parts.append("fileName: \(String(describing: self.fileName))")
        
        return parts.joined(separator: " | ")
    }
}

class TCBlobDownloadArchivable: NSObject, NSSecureCoding, @unchecked Sendable {
    nonisolated(unsafe) static var supportsSecureCoding: Bool = true
    let taskIdentifier: String!
    let sessionConfigurationIdentifier: String!
    let fileName: String!
    let directory: String!
    var resumeData: Data?

    init(taskIdentifier: String, sessionConfigurationIdentifier: String, fileName: String?, directory: String?) {
        self.taskIdentifier = taskIdentifier
        self.sessionConfigurationIdentifier = sessionConfigurationIdentifier
        self.fileName = fileName
        self.directory = directory
    }

    required init?(coder aDecoder: NSCoder) {
        self.taskIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "taskIdentifier") as String?
        self.sessionConfigurationIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "sessionConfigurationIdentifier") as String?
        self.fileName = aDecoder.decodeObject(of: NSString.self, forKey: "fileName") as String?
        self.directory = aDecoder.decodeObject(of: NSString.self, forKey: "directory") as String?
        self.resumeData = aDecoder.decodeObject(of: NSData.self, forKey: "resumeData") as Data?
        super.init()
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.taskIdentifier, forKey: "taskIdentifier")
        aCoder.encode(self.sessionConfigurationIdentifier, forKey: "sessionConfigurationIdentifier")
        aCoder.encode(self.fileName, forKey: "fileName")
        aCoder.encode(self.directory, forKey: "directory")
        aCoder.encode(self.resumeData, forKey: "resumeData")
    }

    func taskQueue() -> [String: TCBlobDownloadArchivable]? {
        let data = UserDefaults.standard.data(forKey: self.sessionConfigurationIdentifier)

        if let data {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSString.self, TCBlobDownloadArchivable.self], from: data) as? [String : TCBlobDownloadArchivable]
        }
        return nil
    }

    func save() {
        var downloads: [String: TCBlobDownloadArchivable] = [:]
        if let d = self.taskQueue() {
            downloads = d
        }

        downloads[taskIdentifier] = self

        let archive = try? NSKeyedArchiver.archivedData(withRootObject: downloads, requiringSecureCoding: true)
		
		Task { @MainActor in
			UserDefaults.standard.set(archive, forKey: self.sessionConfigurationIdentifier)
			UserDefaults.standard.synchronize()
		}
    }

    func delete() {
        TCBlobDownloadArchivable.deleteForTaskIdentifier(taskIdentifier, sessionConfigurationIdentifier: sessionConfigurationIdentifier)
    }

    class func deleteForTaskIdentifier(_ taskIdentifier: String, sessionConfigurationIdentifier: String) {
        if var d = TCBlobDownloadManager.taskQueueForSessionConfigurationIdentifier(sessionConfigurationIdentifier) {
            d.removeValue(forKey: taskIdentifier)

            let archive = try? NSKeyedArchiver.archivedData(withRootObject: d, requiringSecureCoding: true)
            UserDefaults.standard.set(archive, forKey: sessionConfigurationIdentifier)
            UserDefaults.standard.synchronize()
        }
    }

    func downloadForTask(_ downloadTask: URLSessionDownloadTask) -> TCBlobDownload {
        return TCBlobDownload(downloadTask: downloadTask, toDirectory: self.directory != nil ? URL(fileURLWithPath: self.directory!, isDirectory: true) : nil, fileName: self.fileName, delegate: nil, sessionConfigurationIdentifier: self.sessionConfigurationIdentifier)
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

        return parts.joined(separator: " | ")
    }
}

extension TCBlobDownload {
    
    func save() {
        let archivable = TCBlobDownloadArchivable(taskIdentifier: String(self.downloadTask.taskIdentifier), sessionConfigurationIdentifier: self.sessionConfigurationIdentifier, fileName: self.fileName, directory: self.directory != nil ? self.directory!.path : nil)
        archivable.save()
    }

    func delete() {
        TCBlobDownloadArchivable.deleteForTaskIdentifier(String(self.downloadTask.taskIdentifier), sessionConfigurationIdentifier: self.sessionConfigurationIdentifier)
    }

    func archive() -> TCBlobDownloadArchivable? {
        if let tasks = TCBlobDownloadManager.taskQueueForSessionConfigurationIdentifier(self.sessionConfigurationIdentifier) {
            if let task = tasks[String(self.downloadTask.taskIdentifier)] {
                return task
            }
        }
        return nil
    }
}
