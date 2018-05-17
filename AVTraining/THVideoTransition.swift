//
//  THVideoTransition.swift
//  AVTraining
//
//  Created by MJ.KONG-MAC on 16/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import Foundation
import AVFoundation

enum THVideoTransitionType {
    case push
    case dissolve
    case wipe
    case none
}

enum THPushTransitionDirection {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
    case none
}

class THVideoTransition {

    var type: THVideoTransitionType = .none {
        willSet(newValue) {
            if (self.type != .push) {
                pushDirection = .none
            }
        }
    }
    var pushDirection: THPushTransitionDirection = .none
    var duration: CMTime = kCMTimeInvalid
    var range: CMTimeRange = kCMTimeRangeInvalid
    
    init(withTransitionType transitionType:THVideoTransitionType, transitionDuration duration:CMTime) {
        self.type = transitionType
        self.pushDirection = .none
        self.duration = duration
    }

}
