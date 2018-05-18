//
//  VideoAssetsTests.swift
//  AVTrainingTests
//
//  Created by MJ.KONG-MAC on 16/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import XCTest
import AVFoundation

class AVCompositionTests: XCTestCase {

    fileprivate var timeObserver: Any?
    fileprivate var player: AVPlayer?
    fileprivate var playerItemStatusContext = 0
    fileprivate var finishRunLoop = true
    fileprivate var index = 0
    fileprivate var videoItems:[THVideoItem] = []
    fileprivate var audioItems:[THAudioItem] = []

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.videoItems = [
            // flower: duration(00:10)
            videoAsset(withURL: URL(fileURLWithPath: Bundle.main.path(forResource: "flower", ofType: "mov")!),
                       timeRangeInAsset: kCMTimeRangeInvalid),
            // video-jpeg: duration(00:07)
            videoAsset(withURL: URL(fileURLWithPath: Bundle.main.path(forResource: "video-jpeg", ofType: "MOV")!),
                       timeRangeInAsset: kCMTimeRangeInvalid),
            // sample_clip1: duration(00:10)
            videoAsset(withURL: URL(fileURLWithPath: Bundle.main.path(forResource: "sample_clip1", ofType: "m4v")!),
                       timeRangeInAsset: kCMTimeRangeInvalid)
        ]
        self.audioItems = [
            // KeepGoing: duration(00:25)
            audioAsset(withURL: URL(fileURLWithPath: Bundle.main.path(forResource: "KeepGoing", ofType: "m4a")!),
                       startTime: kCMTimeZero, timeRangeInAsset: kCMTimeRangeInvalid),
            // StarGazing: duration(00:19)
            audioAsset(withURL: URL(fileURLWithPath: Bundle.main.path(forResource: "StarGazing", ofType: "m4a")!),
                       startTime: kCMTimeZero, timeRangeInAsset: kCMTimeRangeInvalid)
        ]

        finishRunLoop = false
        while !finishRunLoop {
            Wait()
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func audioAsset(withURL url:URL, startTime sTime:CMTime, timeRangeInAsset range:CMTimeRange) -> THAudioItem {
        let audioItem = THAudioItem.init(withURL: url)
        audioItem.prepareWithAClosure { (complete: Bool) in
            if range != kCMTimeRangeInvalid {
                var duration = range.duration
                if range.duration == kCMTimeZero {
                    duration = CMTimeSubtract(audioItem.asset!.duration, range.start)
                }
                audioItem.timeRange = CMTimeRange(start: range.start, duration: duration)
                print("audioItem closure rangeInfo: \(self.StringFromCMTimeRange(range: audioItem.timeRange))")
            } else {
                audioItem.timeRange = CMTimeRange(start: kCMTimeZero, duration: audioItem.asset!.duration)
            }
            audioItem.startTimeInTimeline = sTime
            self.index = self.index + 1
            if self.index == self.videoItems.count {
                self.index = 0
                self.finishRunLoop = true
            }
        }
        return audioItem
    }
    
    func videoAsset(withURL url:URL, timeRangeInAsset range:CMTimeRange) -> THVideoItem {
        let videoItem = THVideoItem.init(withURL: url)
        videoItem.prepareWithAClosure { (complete: Bool) in
            if range != kCMTimeRangeInvalid {
                var duration = range.duration
                if range.duration == kCMTimeZero {
                    duration = CMTimeSubtract((videoItem.asset?.duration)!, range.start)
                }
                videoItem.timeRange = CMTimeRange(start: range.start, duration: duration)
                print("videoItem closure rangeInfo: \(self.StringFromCMTimeRange(range: videoItem.timeRange))")
            } else {
                videoItem.timeRange = CMTimeRange(start: kCMTimeZero, duration: (videoItem.asset?.duration)!)
                print("videoItem closure rangeInfo: \(self.StringFromCMTimeRange(range: videoItem.timeRange))")
            }
            self.index = self.index + 1
            if self.index == self.videoItems.count {
                self.index = 0
                self.finishRunLoop = true
            }
        }
        return videoItem
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
        timeLabel.text = formattedString
    }
    
    func addPlayerTimeObserver() {
        
        // create 0.5 seconds refresh interval
        let interval: CMTime = CMTime(seconds: 0.5,
                                      preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: nil) {
            [weak self] time in
            self?.updateTimeLabel()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // make sure that this callback was intented for this test
        if (context == &playerItemStatusContext) {
            
            guard let playerItem = object as? AVPlayerItem else { return }
            if playerItem.status == .readyToPlay {
                finishRunLoop = true
            } else if playerItem.status == .failed {
                XCTAssert(false, "playerItem status is failed.");
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func testPlayWithNoTransition() {
        
        let composition = THBasicComposition.init(withVideoItems: videoItems, audioItems:audioItems, transition: nil)
        
        player = AVPlayer.init(playerItem: composition.makePlayable())
        player?.currentItem?.addObserver(self, forKeyPath: "status", options: [.new], context: &playerItemStatusContext)
        preview.player = player
        finishRunLoop = false
        while !finishRunLoop {
            Wait()
        }
        
        addPlayerTimeObserver()
        player?.play()
        Wait(for: CMTimeGetSeconds((player?.currentItem?.asset.duration)!))
    }
    
    func testPlayWithTransition() {
        
        let videoTransition = THVideoTransition.init(withTransitionType: .wipe, transitionDuration: CMTimeMake(2,1))
        let composition = THBasicComposition.init(withVideoItems: videoItems, audioItems:audioItems, transition: videoTransition)
        
        player = AVPlayer.init(playerItem: composition.makePlayable())
        player?.currentItem?.addObserver(self, forKeyPath: "status", options: [.new], context: &playerItemStatusContext)
        preview.player = player
        // wait
        finishRunLoop = false
        while !finishRunLoop {
            Wait()
        }
        
        addPlayerTimeObserver()
        player?.play()
        Wait(for: CMTimeGetSeconds((player?.currentItem?.asset.duration)!))

    }
        
}
