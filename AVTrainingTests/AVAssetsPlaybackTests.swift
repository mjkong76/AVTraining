//
//  AVAssetsPlaybackTests.swift
//  AVTrainingTests
//
//  Created by MJ.KONG-MAC on 04/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import XCTest
import AVFoundation
import Foundation
import CoreFoundation
import CoreGraphics
import Photos

class AVAssetsPlaybackTests: XCTestCase {
    
    /// instance of AVPlayer used for movie playback
    var player: AVPlayer? = nil
    
    /// movie clips
    fileprivate var clips: [AVAsset] = []
    
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
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }
    
    override func setUp() {
        super.setUp()
        loadResource(forResource: "roller", ofType: "mp4")
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
            dispatchGroup.leave()
            self.finishRunLoop = true
        }
    }
    
    func prepareToPlay() {
        
        dispatchGroup.enter()
        
        self.playerItem = AVPlayerItem(asset: self.clips.first!)
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
            } else if playerItem.status == .failed {
                XCTAssert(false, "playerItem status is failed.");
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        dispatchGroup.leave()
        finishRunLoop = true
    }
    
    func addPlayerItemTimeObserver() {
        
        // create 0.5 seconds refresh interval
        let interval: CMTime = CMTime(seconds: refresh_interval,
                                      preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: nil) {
            [weak self] time in
                self?.timeLabel.text = String(Int(CMTimeGetSeconds(time)))
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
