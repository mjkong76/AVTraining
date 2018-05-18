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
    
    fileprivate var mutableComposition: AVMutableComposition?
    fileprivate var audioTracks: AVMutableCompositionTrack?
    fileprivate var videoComposition: AVVideoComposition?
    fileprivate var audioMix: AVMutableAudioMix?
    fileprivate var videoItems:[THVideoItem] = []
    fileprivate var audioItems:[THAudioItem] = []
    fileprivate var videoTransition: THVideoTransition?
    
    /* test 이기에 하나의 transition을 공통으로 적용한다.
     */
    init(withVideoItems vItems:[THVideoItem], audioItems aItems:[THAudioItem], transition: THVideoTransition?) {

        self.mutableComposition = AVMutableComposition.init()
        self.mutableComposition?.naturalSize = (vItems.first?.asset?.tracks(withMediaType: AVMediaTypeVideo)[0].naturalSize)!
        self.videoItems = vItems
        self.audioItems = aItems
        self.videoTransition = transition
        self.audioMix = AVMutableAudioMix()

        buildCompositionTrack()
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
    
    fileprivate func buildCustomVideoCompositionInstruction(withVideoComposition vc: AVMutableVideoComposition) -> [Any] {
        
        var instructions:[Any] = []
        var trackIndex = 0
        let compositionInstructions = vc.instructions as! [AVMutableVideoCompositionInstruction]
        for compositionInstruction in compositionInstructions {
            let vci = compositionInstruction
            if vci.layerInstructions.count == 1 {
                let videoInstruction = APLCustomVideoCompositionInstruction(thePassthroughTrackID: vci.layerInstructions[0].trackID,
                                                                            forTimeRange: vci.timeRange)
                instructions.append(videoInstruction)
            } else if vci.layerInstructions.count == 2 {
                let videoInstruction = APLCustomVideoCompositionInstruction(theSourceTrackIDs:[NSNumber(value:vci.layerInstructions[0].trackID),
                                                                                               NSNumber(value:vci.layerInstructions[1].trackID)],
                                                                            forTimeRange: vci.timeRange)
                videoInstruction.foregroundTrackID = vci.layerInstructions[trackIndex].trackID
                videoInstruction.backgroundTrackID = vci.layerInstructions[1-trackIndex].trackID
                instructions.append(videoInstruction)
                trackIndex = (trackIndex + 1) % 2
            } else {
                instructions.append(vci)
            }
        }
        
        return instructions
    }
    
    fileprivate func buildVideoComposition() -> AVVideoComposition? {
        
        let vc = AVMutableVideoComposition.init(propertiesOf: mutableComposition!)
        
        if videoTransition?.type == .dissolve || videoTransition?.type == .wipe {
            if videoTransition?.type == .dissolve {
                vc.customVideoCompositorClass = APLCrossDissolveCompositor.self
            } else {
                vc.customVideoCompositorClass = APLDiagonalWipeCompositor.self
            }
            let instructions = buildCustomVideoCompositionInstruction(withVideoComposition: vc) as! [AVVideoCompositionInstructionProtocol]
            vc.instructions = instructions
        }
        
        return vc
    }
    
    fileprivate func buildCompositionTrackWithVideo() {
        
        let trackID = kCMPersistentTrackID_Invalid
        
        let compositionTrackA = (mutableComposition?.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: trackID))!
        let compositionTrackB = (mutableComposition?.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: trackID))!
        let compositionTrackC = (mutableComposition?.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: trackID))!
        let compositionTrackD = (mutableComposition?.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: trackID))!
        
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
            let naturalSizeOfAsset = (videoItem.asset?.tracks(withMediaType: AVMediaTypeVideo)[0].naturalSize)!
            let scaleX = (mutableComposition?.naturalSize.width)! / naturalSizeOfAsset.width
            let scaleY = (mutableComposition?.naturalSize.height)! / naturalSizeOfAsset.height
            compositionVideoTrack.preferredTransform = CGAffineTransform.init(scaleX: scaleX, y: scaleY)
            
            guard let videoTrack = videoItem.asset?.tracks(withMediaType: AVMediaTypeVideo)[0] else {
                continue
            }
            try? compositionVideoTrack.insertTimeRange(videoItem.timeRange, of: videoTrack, at: cursorTime)
            let compositionAudioTrack = audioTracks[trackIndex]
            if let audioTrack = videoItem.asset?.tracks(withMediaType: AVMediaTypeAudio)[0] {
                try? compositionAudioTrack.insertTimeRange(videoItem.timeRange, of: audioTrack, at: cursorTime)
            }
            
            trackIndex = trackIndex + 1

            print("trackId: \(compositionVideoTrack.trackID), startTime:\(StringFromCMTime(cursorTime)), videoItem timeRange Info:\(StringFromCMTimeRange(range:videoItem.timeRange))")

            cursorTime = CMTimeAdd(cursorTime, videoItem.timeRange.duration)
            cursorTime = CMTimeSubtract(cursorTime, transitionDuration)
        }
    }
    
    fileprivate func buildCompositionTrackWithAudio() {
        
        let trackID = kCMPersistentTrackID_Invalid
        
        for audioItem in audioItems {
            let compositionTrack = mutableComposition!.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: trackID)
            try? compositionTrack.insertTimeRange(audioItem.timeRange, of: (audioItem.asset?.tracks[0])!, at: audioItem.startTimeInTimeline)
            print("trackId: \(compositionTrack.trackID), startTime:\(StringFromCMTime(audioItem.startTimeInTimeline)), audioItem timeRange Info:\(StringFromCMTimeRange(range:audioItem.timeRange))")
            
            let halfSeconds = CMTimeMake(Int64(compositionTrack.asset!.duration.seconds), Int32(2))
            let finishSeconds = CMTimeMake(Int64(halfSeconds.seconds), Int32(2))
            
            let audioMixInputParameter = AVMutableAudioMixInputParameters.init(track: compositionTrack)
            audioMixInputParameter.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1,
                                                 timeRange: CMTimeRangeMake(kCMTimeZero, halfSeconds))
            audioMixInputParameter.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0,
                                                 timeRange: CMTimeRangeMake(halfSeconds, finishSeconds))
            audioMixInputParameter.audioTapProcessor = AudioProcessingTapWrapper.init().tap?.takeUnretainedValue()
            audioMix!.inputParameters.append(audioMixInputParameter)
        }
    }
    
    fileprivate func buildCompositionTrack() {
        
        buildCompositionTrackWithVideo()
        buildCompositionTrackWithAudio()
    }
    
    func makePlayable() -> AVPlayerItem {
        
        let playerItem: AVPlayerItem = AVPlayerItem.init(asset: mutableComposition!)
        
        playerItem.videoComposition = videoComposition
        playerItem.audioMix = audioMix
        
        return playerItem
    }
    
    func makeExportable() -> AVAssetExportSession {
        
        let presetName = AVAssetExportPresetHighestQuality
        let session: AVAssetExportSession = AVAssetExportSession.init(asset: mutableComposition!, presetName: presetName)!
        
        session.videoComposition = videoComposition
        session.audioMix = audioMix
        
        return session
    }
}
