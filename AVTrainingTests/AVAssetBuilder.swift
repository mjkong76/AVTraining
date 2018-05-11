//
//  AVAssetBuilder.swift
//  AVTrainingTests
//
//  Created by MJ.KONG-MAC on 11/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import XCTest
import AVFoundation
import Foundation
import CoreFoundation
import CoreGraphics
import Photos

class AVAssetBuilder: NSObject {
    
    /// movie clips
    fileprivate var clips: [AVAsset] = []
    
    /// moive clips time ranges
    fileprivate var clipTimeRanges: [CMTimeRange] = []
    
    /// The time range in which the clips should pass through.
    fileprivate lazy var passThroughTimeRanges: [CMTimeRange] = self.initTimeRanges()
    
    /// The transition time range for the clips.
    fileprivate lazy var transitionTimeRanges: [CMTimeRange] = self.initTimeRanges()
    
    /// The currently selected transition.
    var transitionType = TransitionType.crossDissolve.rawValue
    
    /// The duration of the transition.
    var transitionDuration = CMTimeMakeWithSeconds(2.0, Int32(NSEC_PER_SEC))
    
    func initTimeRanges() -> [CMTimeRange] {
        let time = CMTimeMake(0, 0)
        return Array(repeating: CMTimeRangeMake(time, time), count: clips.count)
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

    /// inner function
    fileprivate func buildComposition(compositionVideoTracks: inout [AVMutableCompositionTrack],
                                      _ compositionAudioTracks: inout [AVMutableCompositionTrack]) {
        
        var alternatingIndex = 0
        var nextClipStartTime = kCMTimeZero
        
        for clipTimeRange in clipTimeRanges {
            
            var halfClipDuration = clipTimeRange.duration
            halfClipDuration.timescale *= 2
            transitionDuration = CMTimeMinimum(transitionDuration, halfClipDuration)
        }
        
        let clipCount = clips.count
        for i in 0..<clipCount {
            
            let asset = clips[i]
            var timeRangeInAsset: CMTimeRange
            if i < clipTimeRanges.count {
                timeRangeInAsset = clipTimeRanges[i]
            } else {
                timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, asset.duration)
            }
            
            alternatingIndex = i % 2 // alternating targets: 0, 1, 0, 1, ...
            do {
                let clipVideoTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
                try compositionVideoTracks[alternatingIndex].insertTimeRange(timeRangeInAsset,
                                                                             of: clipVideoTrack, at: nextClipStartTime)
                let clipAudioTrack = asset.tracks(withMediaType: AVMediaTypeAudio)[0]
                try compositionAudioTracks[alternatingIndex].insertTimeRange(timeRangeInAsset,
                                                                             of: clipAudioTrack, at: nextClipStartTime)
            } catch {
                XCTAssert(false, "An error occurred inserting a time range of the source track into the composition.")
            }
            
            /*
             Remember the time range in which this clip should pass through.
             First clip ends with a transition.
             Second clip begins with a transition.
             Exclude that transition from the pass through time ranges.
             */
            passThroughTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, timeRangeInAsset.duration)
            if i > 0 {
                passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start, transitionDuration)
                passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration)
            }
            if i + 1 < clipCount {
                passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration)
            }
            
            /*
             The end of this clip will overlap the start of the next.
             */
            nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration)
            nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration)
            
            // Remember the time range for the transition to the next item
            if i + 1 < clipCount {
                transitionTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration)
            }
            
            /// debug track info
            if CMTIMERANGE_IS_EMPTY(passThroughTimeRanges[i]) == false {
                print("trackId: \(compositionVideoTracks[alternatingIndex].trackID), debug passThroughTimeRange info. \(StringFromCMTimeRange(range: passThroughTimeRanges[i]))")
            }
            if CMTIMERANGE_IS_EMPTY(transitionTimeRanges[i]) == false {
                print("trackId: \(compositionVideoTracks[alternatingIndex].trackID), debug transitionTimeRanges info. \(StringFromCMTimeRange(range: transitionTimeRanges[i]))")
            }
        }
    }
    
    /// inner function
    fileprivate func makeTransitionInstructions(videoComposition: AVMutableVideoComposition,
                                    compositionVideoTracks: [AVMutableCompositionTrack]) -> [Any] {
        var alternatingIndex = 0
        
        // Set up the video composition to perform cross dissolve or diagonal wipe transitions between clips.
        var instructions:[Any] = []
        
        // Cycle between "pass through A", "transition from A to B", "pass through B".
        for i in 0..<clips.count {
            alternatingIndex = i % 2 // Alternating targets.
            
            if videoComposition.customVideoCompositorClass != nil {
                let videoInstruction =
                    APLCustomVideoCompositionInstruction(thePassthroughTrackID:compositionVideoTracks[alternatingIndex].trackID,
                                                         forTimeRange: passThroughTimeRanges[i])
                
                instructions.append(videoInstruction)
            } else {
                // Pass through clip i.
                let passThroughInstruction = AVMutableVideoCompositionInstruction()
                passThroughInstruction.timeRange = passThroughTimeRanges[i]
                let passThroughLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTracks[alternatingIndex])
                passThroughInstruction.layerInstructions = [passThroughLayer]
                instructions.append(passThroughInstruction)
            }
            
            if i + 1 < clips.count {
                // Add transition from clip i to clip i+1.
                if videoComposition.customVideoCompositorClass != nil {
                    let videoInstruction =
                        APLCustomVideoCompositionInstruction(theSourceTrackIDs:
                            [NSNumber(value:compositionVideoTracks[0].trackID),
                             NSNumber(value:compositionVideoTracks[1].trackID)],
                                                             forTimeRange: transitionTimeRanges[i])
                    // First track -> Foreground track while compositing.
                    videoInstruction.foregroundTrackID = compositionVideoTracks[alternatingIndex].trackID
                    // Second track -> Background track while compositing.
                    videoInstruction.backgroundTrackID =
                        compositionVideoTracks[1 - alternatingIndex].trackID
                    
                    instructions.append(videoInstruction)
                } else {
                    if CMTIMERANGE_IS_EMPTY(transitionTimeRanges[i]) == false {
                        let transitionInstruction = AVMutableVideoCompositionInstruction()
                        transitionInstruction.timeRange = transitionTimeRanges[i]
                        let fromLayer =
                            AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTracks[alternatingIndex])
                        let toLayer =
                            AVMutableVideoCompositionLayerInstruction(assetTrack:compositionVideoTracks[1 - alternatingIndex])
                        transitionInstruction.layerInstructions = [fromLayer, toLayer]
                        instructions.append(transitionInstruction)
                    }
                }
            }
        }
        
        return instructions
    }
    
    fileprivate func buildComposition(_ composition: AVMutableComposition, andVideoComposition videoComposition: AVMutableVideoComposition) {
        
        // Add two video tracks and two audio tracks.
        var compositionVideoTracks: [AVMutableCompositionTrack] =
            [composition.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                         preferredTrackID: kCMPersistentTrackID_Invalid),
             composition.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                         preferredTrackID: kCMPersistentTrackID_Invalid)]
        var compositionAudioTracks: [AVMutableCompositionTrack] =
            [composition.addMutableTrack(withMediaType: AVMediaTypeAudio,
                                         preferredTrackID: kCMPersistentTrackID_Invalid),
             composition.addMutableTrack(withMediaType: AVMediaTypeAudio,
                                         preferredTrackID: kCMPersistentTrackID_Invalid)]
        
        buildComposition(compositionVideoTracks: &compositionVideoTracks, &compositionAudioTracks)
        
        let instructions = makeTransitionInstructions(videoComposition: videoComposition,
                                                      compositionVideoTracks: compositionVideoTracks)
        videoComposition.instructions = instructions as! [AVVideoCompositionInstructionProtocol]
    }
    
    func buildComposition(_ clips: [AVAsset], _ clipTimeRanges: [CMTimeRange], _ customComposition: AVVideoCompositing.Type?) ->
        (composition: AVComposition?, videoComposition: AVVideoComposition?) {
        
        self.clips = clips
        self.clipTimeRanges = clipTimeRanges
        
        // use the naturalSize of the first video track
        let videoTrack = clips.first!.tracks(withMediaType: AVMediaTypeVideo)
        if (videoTrack.isEmpty) {
            return (nil, nil)
        }
        
        let videoSize = videoTrack.first!.naturalSize
        
        // create AVMutableComposition
        let composition = AVMutableComposition()
        composition.naturalSize = videoSize
        
        let videoComposition = AVMutableVideoComposition()
        // must be set these properties
        videoComposition.frameDuration = CMTimeMake(1, 30) // 30fps
        videoComposition.renderSize = videoSize
        
        if let customComposition = customComposition {
            videoComposition.customVideoCompositorClass = customComposition
        }
        
        buildComposition(composition, andVideoComposition: videoComposition)
        
        return (composition, videoComposition)
    }
}
