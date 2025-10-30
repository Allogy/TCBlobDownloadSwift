//
//  TCBlobBackgroundDownloadManager.swift
//  CapillaryMVP
//
//  Created by Jeremy Bone on 6/26/15.
//  Copyright (c) 2015 Allogy Interactive. All rights reserved.
//

import Foundation

open class TCBlobBackgroundDownloadManager: TCBlobDownloadManager {

	nonisolated(unsafe) public static let sharedBackground = TCBlobBackgroundDownloadManager()

    convenience init() {
        let config = URLSessionConfiguration.background(withIdentifier: "tcblobdownloadmanager.background.session")
        self.init(config: config)
    }
}
