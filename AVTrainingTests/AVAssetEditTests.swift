//
//  AVAssetEditTests.swift
//  AVTrainingTests
//
//  Created by MJ.KONG-MAC on 08/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import XCTest
import AVFoundation
import Foundation
import CoreFoundation
import CoreGraphics
import Photos

/*
 The transition type: diagonal wipe or cross dissolve.
 These values correspond to the underlying UITableViewCell.tag values in the "Set Transition" Table View in
 the Storyboard.
 */
enum TransitionType: Int {
    case diagonalWipe = 0
    case crossDissolve = 1
}

class AVAssetEditTests: XCTestCase {
    
    /// instance of AVPlayer used for movie playback
    var player: AVPlayer? = nil
    
    /// movie clips
    fileprivate var clips: [AVAsset] = []
    
    /// movie clip time ranges
    fileprivate var clipTimeRanges: [CMTimeRange] = []
    
    /// define constant for the key-value observation context
    fileprivate var playerItemStatusContext = 0
    
    /// instacne of AVPlayerItem used to represent the presentation state of the asset played by the AVPlayer
    fileprivate var playerItem: AVPlayerItem? = nil {
        didSet {
            // replace the current player item with the new item
            player?.replaceCurrentItem(with: self.playerItem)
        }
    }
    
    /// observers
    fileprivate var timeObserver: Any? = nil
    fileprivate var itemEndObserver: Any? = nil
    
    /// play for duration of asset
    fileprivate var duration: CMTime = kCMTimeZero
    
    ///
    fileprivate let dispatchGroup = DispatchGroup()
    
    ///
    fileprivate var finishRunLoop = true
    
    /// refresh interval for time observation of AVPlayer
    fileprivate let refresh_interval = 0.5
    
    /// the composition into which the tracks from the different media assets will added
    fileprivate var composition: AVMutableComposition?
    
    /// a video composition that describes the number and IDs of video tracks that are to be used in order to produce a composed video frame
    fileprivate var videoComposition: AVMutableVideoComposition?
    
    /// The time range in which the clips should pass through.
    private lazy var passThroughTimeRanges: [CMTimeRange] = self.initTimeRanges()
    
    /// The transition time range for the clips.
    private lazy var transitionTimeRanges: [CMTimeRange] = self.initTimeRanges()

    /// The currently selected transition.
    var transitionType = TransitionType.diagonalWipe.rawValue
    /// The duration of the transition.
    var transitionDuration = CMTimeMake(1200, 600)

    func initTimeRanges() -> [CMTimeRange] {
        let time = CMTimeMake(0, 0)
        return Array(repeating: CMTimeRangeMake(time, time), count: clips.count)
    }

    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }

    override func setUp() {
        super.setUp()

        loadResource(forResource: "highway", ofType: "mp4")
        finishRunLoop = false
        while !finishRunLoop {
            Wait()
        }
        
        loadResource(forResource: "roller", ofType: "mp4")
        finishRunLoop = false
        while !finishRunLoop {
            Wait()
        }
        
        loadResource(forResource: "canal", ofType: "mp4")
        finishRunLoop = false
        while !finishRunLoop {
            Wait()
        }
}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func loadResource(forResource name: String?, ofType ext: String?) {
        
        guard let clipPath = Bundle.main.path(forResource: name, ofType: ext) else {
            XCTAssert(false, "Failed to get clipPath from main bundle"); return
        }
        
        let asset = AVURLAsset(url: URL(fileURLWithPath: clipPath))
        let assetKeysToLoadAndTest = ["tracks", "duration", "composable"]
        loadAsset(asset, withKeys: assetKeysToLoadAndTest, usingDispatchGroup: dispatchGroup)
    }
    
    func loadAsset(_ asset: AVAsset, withKeys assetKeysToLoad: [String], usingDispatchGroup dispatchGroup: DispatchGroup) {
        
        dispatchGroup.enter()
        asset.loadValuesAsynchronously(forKeys: assetKeysToLoad) {
            
            // whether the values of each of keys we need have been successfully loaded
            for item in assetKeysToLoad {
                var error: NSError?
                if asset.statusOfValue(forKey: item, error: &error) == AVKeyValueStatus.failed {
                    dispatchGroup.leave()
                    XCTAssert(false, "Key value loading failed for key: \(item) with error:\(error!)"); return
                }
            }
            self.clips.append(asset)
            //
            self.clipTimeRanges.append(CMTimeRange(start: CMTimeMakeWithSeconds(10, 1),
                                                   duration: CMTimeMakeWithSeconds(10, 1)))
            dispatchGroup.leave()
            self.finishRunLoop = true
        }
    }
    
    func buildComposition(compositionVideoTracks: inout [AVMutableCompositionTrack],
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
        }
        
        for i in 0..<clipCount {
            print("\(i)th debug passThroughTimeRange info. \(StringFromCMTimeRange(range: passThroughTimeRanges[i]))\t")
            print("\(i)th debug transitionTimeRanges info. \(StringFromCMTimeRange(range: transitionTimeRanges[i]))\n")
        }
    }

    func makeTransitionInstructions(videoComposition: AVMutableVideoComposition,
                                    compositionVideoTracks: [AVMutableCompositionTrack]) -> [Any] {
        var alternatingIndex = 0
        
        // Set up the video composition to perform cross dissolve or diagonal wipe transitions between clips.
        var instructions = [Any]()
        
        // Cycle between "pass through A", "transition from A to B", "pass through B".
        for i in 0..<clips.count {
            alternatingIndex = i % 2 // Alternating targets.
            
            if videoComposition.customVideoCompositorClass != nil {
                let videoInstruction =
                    APLCustomVideoCompositionInstruction(thePassthroughTrackID:
                        compositionVideoTracks[alternatingIndex].trackID,
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
        
        return instructions
    }
    
    func buildTransitionComposition(_ composition: AVMutableComposition, andVideoComposition videoComposition: AVMutableVideoComposition) {
        
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
    
    func buildCompositionObjectsForPlayback() {
        
        // use the naturalSize of the first video track
        let videoTracks = clips[0].tracks(withMediaType: AVMediaTypeVideo)
        let videoSize = videoTracks.first!.naturalSize
        
        // create AVMutableComposition
        let composition = AVMutableComposition()
        composition.naturalSize = videoSize
        
        // create AVMutableVideoComposition
        let videoComposition = AVMutableVideoComposition()
        
        /// transition
        if self.transitionType == TransitionType.diagonalWipe.rawValue {
            videoComposition.customVideoCompositorClass = APLDiagonalWipeCompositor.self
        } else {
            videoComposition.customVideoCompositorClass = APLCrossDissolveCompositor.self
        }

        // every videoComposition needs these properties to be set:
        videoComposition.frameDuration = CMTimeMake(1, 30)  // 30 fps
        videoComposition.renderSize = videoSize
        
        buildTransitionComposition(composition, andVideoComposition: videoComposition)
        
        self.composition = composition
        self.videoComposition = videoComposition
    }

    func prepareToPlay() {
        
        buildCompositionObjectsForPlayback()
        
        XCTAssert(self.composition != nil, "composition is nil.")
        XCTAssert(self.videoComposition != nil, "videoComposition is nil.")

        self.playerItem = AVPlayerItem(asset: self.composition!)
        self.playerItem!.videoComposition = self.videoComposition
        self.playerItem!.addObserver(self, forKeyPath: "status", options: [.new], context: &playerItemStatusContext)
        self.player = AVPlayer.init(playerItem: self.playerItem!)
        preview.player = self.player
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // make sure that this callback was intented for this test
        if (context == &playerItemStatusContext) {
            
            guard let playerItem = object as? AVPlayerItem else { return }
            if playerItem.status == .readyToPlay {
                
                /**
                 *  once the AVPlayerItem becomes ready to play, i.e.
                 *  playerItem.status == AVPlayerItemStatusReadyToPlay,
                 *  its duration can be fetech from the item
                 */
                duration = playerItem.duration

                finishRunLoop = true
           } else if playerItem.status == .failed {
                XCTAssert(false, "playerItem status is failed.");
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func updateTimeLabel() {
        
        var seconds = CMTimeGetSeconds(self.player!.currentTime())
        if __inline_isfinited(seconds) <= 0 {
            seconds = 0
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        guard let formattedString = formatter.string(from: TimeInterval(seconds)) else { return }
        self.timeLabel.text = formattedString
    }

    func addPlayerItemTimeObserver() {
        
        // create 0.5 seconds refresh interval
        let interval: CMTime = CMTime(seconds: refresh_interval,
                                      preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: nil) {
            [weak self] time in
            self?.updateTimeLabel()
        }
    }
    
    func addItemEndObserverForPlayerItem() {
        
        let center = NotificationCenter.default
        let mainQueue = OperationQueue.main
        itemEndObserver = center.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: mainQueue) {
            [weak self] notification in
            self?.timeLabel.text = "End"
        }
    }
    
    func testPlayback() {

        prepareToPlay()
        addPlayerItemTimeObserver()
        addItemEndObserverForPlayerItem()
        
        finishRunLoop = false
        while !finishRunLoop {
            Wait()
        }
        // playing for duration of asset
        self.player!.play()
        Wait(for: CMTimeGetSeconds(duration))
    }
}
