//
//  TestTool.swift
//  AVTrainingTests
//
//  Created by MJ.KONG-MAC on 04/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import Foundation
import AVFoundation
import XCTest

extension XCTest {
    
    func Wait(for timeInterval: TimeInterval) {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: timeInterval))
    }
    
    func Wait() {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
    }
    
    func StringFromCMTimeRange(range: CMTimeRange) -> String
    {
        return String.init(format: "(start:%2.3f, duration:%2.3f)",
                           CMTimeGetSeconds(range.start),
                           CMTimeGetSeconds(range.duration))
    }

}
