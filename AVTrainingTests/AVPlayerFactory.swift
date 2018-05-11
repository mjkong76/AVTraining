//
//  AVPlayerFactory.swift
//  AVTrainingTests
//
//  Created by MJ.KONG-MAC on 11/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import XCTest
import AVFoundation
import Foundation

/*
 The transition type: diagonal wipe or cross dissolve.
 These values correspond to the underlying UITableViewCell.tag values in the "Set Transition" Table View in
 the Storyboard.
 */
enum TransitionType: Int {
    case diagonalWipe = 0
    case crossDissolve = 1
    case none = 2
}

class AVPlayerFactory: XCTestCase {
    
    /// instance of AVPlayer used for movie playback
    fileprivate var player: AVPlayer? = nil
    
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
    
    func prepareToPlay(_ builder: AVAssetBuilder, withAssets assets:[AVAsset], ranges assetRanges:[CMTimeRange], transition transitionType: TransitionType) -> AVPlayer {
        var customCompositor: AVVideoCompositing.Type?
        if (transitionType.rawValue == TransitionType.none.rawValue) {
            customCompositor = nil
        } else {
            customCompositor = transitionType.rawValue == TransitionType.crossDissolve.rawValue ? APLCrossDissolveCompositor.self : APLDiagonalWipeCompositor.self
        }
        let compostionInfos = builder.buildComposition(assets, assetRanges, customCompositor)
        
        XCTAssert((compostionInfos.composition != nil), "composition is nil.")
        XCTAssert((compostionInfos.videoComposition != nil), "videoComposition is nil.")
        
        self.playerItem = AVPlayerItem(asset: compostionInfos.composition!)
        self.playerItem!.videoComposition = compostionInfos.videoComposition
        self.playerItem!.addObserver(self, forKeyPath: "status", options: [.new], context: &playerItemStatusContext)
        
        self.player = AVPlayer.init(playerItem: self.playerItem!)
        preview.player = self.player
        addPlayerItemTimeObserver()
        
        finishRunLoop = false
        while !finishRunLoop {
            Wait()
        }
        return self.player!
    }
}
