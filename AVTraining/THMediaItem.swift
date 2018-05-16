//
//  THMediaItem.swift
//  AVTraining
//
//  Created by MJ.KONG-MAC on 16/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import Foundation
import AVFoundation

class THMediaItem: THTimelineItem {
    
    var asset: AVAsset?
    var prepared = false
    
    init(withURL url: URL) {
        let options: [String: Bool] = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        asset = AVURLAsset.init(url: url, options: options)
    }
    
    func prepareWithAClosure(completeClosure: @escaping (_ complete: Bool) -> Void) {

        self.asset?.loadValuesAsynchronously(forKeys: ["tracks", "duration", "commonMetadata"]) {
            [weak self] in
            var error: NSError? = nil
            let tracksStatus: AVKeyValueStatus = (self?.asset?.statusOfValue(forKey: "tracks", error: &error))!
            let durationStatus: AVKeyValueStatus = (self?.asset?.statusOfValue(forKey: "duration", error: &error))!
            self?.prepared = (tracksStatus == .loaded) && (durationStatus == .loaded)
            if (self?.prepared)! {
                self?.startTimeInTimeline = kCMTimeZero
                self?.timeRange = CMTimeRangeMake(kCMTimeZero, (self?.asset?.duration)!)
                completeClosure(true)
            } else {
                completeClosure(false)
            }
        }
    }
}
