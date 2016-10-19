//
//  TCBlobBackgroundDownloadManager.swift
//  CapillaryMVP
//
//  Created by Jeremy Bone on 6/26/15.
//  Copyright (c) 2015 Allogy Interactive. All rights reserved.
//

open class TCBlobBackgroundDownloadManager: TCBlobDownloadManager {

    open static let sharedBackground = TCBlobBackgroundDownloadManager()

    convenience init() {
        let config = URLSessionConfiguration.background(withIdentifier: "tcblobdownloadmanager.background.session")
        self.init(config: config)
    }
}
