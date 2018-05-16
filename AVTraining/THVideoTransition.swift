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

    var type: THVideoTransitionType = .none
    var pushDirection: THPushTransitionDirection {
        get {
            return self.pushDirection
        }
        set(newValue) {
            if (type != .push) {
                self.pushDirection = .none
            }
            self.pushDirection = newValue
        }
    }
    var duration: CMTime = kCMTimeInvalid
    var range: CMTimeRange = kCMTimeRangeInvalid
    
    init(withTransitionType transitionType:THVideoTransitionType, transitionDuration duration:CMTime) {
        self.type = transitionType
        self.pushDirection = .none
        self.duration = duration
    }

}
