//
//  HostAppAccess.swift
//  AVTrainingTests
//
//  Created by MJ.KONG-MAC on 04/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import XCTest
@testable import AVTraining

extension XCTest {
    
    var viewController: ViewController {
        let nvc = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
        return nvc.topViewController as! ViewController
    }
    
    var preview: AVPlayerView! {
        return viewController.avPlayerView
    }
    
    var timeLabel: UILabel! {
        return viewController.timeLabel
    }
}
