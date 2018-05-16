//
//  THBasicComposition.swift
//  AVTraining
//
//  Created by MJ.KONG-MAC on 16/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import Foundation
import AVFoundation

class THBasicComposition: THComposition {
    
    fileprivate var composition: AVMutableComposition?
    fileprivate var videoComposition: AVVideoComposition?
    fileprivate var audioMix: AVMutableAudioMix?
    fileprivate var videoItems:[THVideoItem] = []
    fileprivate var audioItems:[THAudioItem] = []
    fileprivate var videoTransition: THVideoTransition?
    
    /* test 이기에 하나의 transition을 공통으로 적용한다.
     */
    init(withVideoItems vItems:[THVideoItem], audioItems aItems:[THAudioItem], transition: THVideoTransition?) {

        self.composition = AVMutableComposition.init()
        self.composition?.naturalSize = (vItems.first?.asset?.tracks.first!.naturalSize)!
        self.videoItems = vItems
        self.audioItems = aItems
        self.videoTransition = transition

        buildCompositionTracks()

        self.videoComposition = buildVideoComposition()
    }
    
    fileprivate func StringFromCMTime(_ time: CMTime) -> String
    {
        return String.init(format: "(time:%2.3f)", CMTimeGetSeconds(time))
    }
    
    fileprivate func StringFromCMTimeRange(range: CMTimeRange) -> String
    {
        return String.init(format: "(start:%2.3f, duration:%2.3f)",
                           CMTimeGetSeconds(range.start),
                           CMTimeGetSeconds(range.duration))
    }
    
    fileprivate func buildVideoComposition() -> AVVideoComposition? {
        
        let videoComposition = AVMutableVideoComposition.init(propertiesOf: composition!)
        
        return videoComposition
    }
    
    fileprivate func addCompositionTrackOfVideoType() {
        
        let trackID = kCMPersistentTrackID_Invalid
        
        let compositionTrackA = (composition?.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: trackID))!
        let compositionTrackB = (composition?.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: trackID))!
        let compositionTrackC = (composition?.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: trackID))!
        let compositionTrackD = (composition?.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: trackID))!
        
        let videoTracks:[AVMutableCompositionTrack] = [compositionTrackA, compositionTrackB]
        let audioTracks:[AVMutableCompositionTrack] = [compositionTrackC, compositionTrackD]
        
        var trackIndex = 0
        var cursorTime = kCMTimeZero
        var transitionDuration = kCMTimeZero
        
        if videoTransition?.type != .none {
            transitionDuration = (videoTransition?.duration)!
        }
        
        for videoItem in self.videoItems {
            trackIndex = trackIndex % 2
            
            let compositionVideoTrack = videoTracks[trackIndex]
            guard let videoTrack = videoItem.asset?.tracks(withMediaType: AVMediaTypeVideo).first else {
                continue
            }
            try? compositionVideoTrack.insertTimeRange(videoItem.timeRange, of: videoTrack, at: cursorTime)
            let compositionAudioTrack = audioTracks[trackIndex]
            if let audioTrack = videoItem.asset?.tracks(withMediaType: AVMediaTypeAudio).first {
                try? compositionAudioTrack.insertTimeRange(videoItem.timeRange, of: audioTrack, at: cursorTime)
            }
            
            trackIndex = trackIndex + 1

            print("trackId: \(compositionVideoTrack.trackID), startTime:\(StringFromCMTime(cursorTime)), videoItem timeRange Info:\(StringFromCMTimeRange(range:videoItem.timeRange))")

            cursorTime = CMTimeAdd(cursorTime, videoItem.timeRange.duration)
            cursorTime = CMTimeSubtract(cursorTime, transitionDuration)
        }
    }
    
    fileprivate func addCompositionTrackOfAudioType() {
        
        let trackID = kCMPersistentTrackID_Invalid
        
        var cursorTime = kCMTimeZero

        for audioItem in audioItems {
            
            let compositionTrack = composition?.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: trackID)
            try? compositionTrack?.insertTimeRange(audioItem.timeRange, of: (audioItem.asset?.tracks.first)!, at: audioItem.startTimeInTimeline)
            
            cursorTime = CMTimeAdd(cursorTime, audioItem.timeRange.duration)
        }
    }
    
    fileprivate func buildCompositionTracks() {
        
        addCompositionTrackOfVideoType()
        addCompositionTrackOfAudioType()
    }
    
    func makePlayable() -> AVPlayerItem {
        
        let playerItem: AVPlayerItem = AVPlayerItem.init(asset: self.composition!)
        
        playerItem.videoComposition = videoComposition
        playerItem.audioMix = audioMix
        
        return playerItem
    }
    
    func makeExportable() -> AVAssetExportSession {
        
        let presetName = AVAssetExportPresetHighestQuality
        let session: AVAssetExportSession = AVAssetExportSession.init(asset: self.composition!, presetName: presetName)!
        
        session.videoComposition = videoComposition
        session.audioMix = audioMix
        
        return session
    }
}
