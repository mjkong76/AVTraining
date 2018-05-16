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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.videoItems = [
            videoAsset(withURL: URL(fileURLWithPath: Bundle.main.path(forResource: "highway", ofType: "mp4")!),
                       timeRange: CMTimeRangeMake(CMTimeMake(10,1), kCMTimeZero)),
            videoAsset(withURL: URL(fileURLWithPath: Bundle.main.path(forResource: "roller", ofType: "mp4")!),
                       timeRange: CMTimeRangeMake(CMTimeMake(15,1), CMTimeMake(10,1))),
            videoAsset(withURL: URL(fileURLWithPath: Bundle.main.path(forResource: "canal", ofType: "mp4")!),
                       timeRange: CMTimeRangeMake(CMTimeMake(15,1), kCMTimeZero))
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
    
    func videoAsset(withURL url:URL, timeRange range:CMTimeRange) -> THVideoItem {
        let videoItem = THVideoItem.init(withURL: url)
        videoItem.prepareWithAClosure { (complete: Bool) in
            if range != kCMTimeRangeInvalid {
                var duration = range.duration
                if range.duration == kCMTimeZero {
                    duration = CMTimeSubtract((videoItem.asset?.duration)!, range.start)
                }
                videoItem.timeRange = CMTimeRange(start: range.start, duration: duration)
                print("closure rangeInfo: \(self.StringFromCMTimeRange(range: videoItem.timeRange))")

                self.index = self.index + 1
                if self.index == self.videoItems.count {
                    self.finishRunLoop = true
                }
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
        
        let composition = THBasicComposition.init(withVideoItems: videoItems, audioItems:[], transition: nil)
        
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
        
    }
        
}
