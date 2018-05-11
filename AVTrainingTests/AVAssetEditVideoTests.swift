//
//  AVAssetEditVideoTests.swift
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

class AVAssetEditVideoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPlayback() {

        let assets = [AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "highway", ofType: "mp4")!)),
                      AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "roller", ofType: "mp4")!)),
                      AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "canal", ofType: "mp4")!)),
                      AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "flower", ofType: "mov")!))]
        
        let assetRanges = [CMTimeRange(start: CMTimeMakeWithSeconds(0, 1), duration: CMTimeMakeWithSeconds(10, 1)),
                           CMTimeRange(start: CMTimeMakeWithSeconds(5, 1), duration: CMTimeMakeWithSeconds(20, 1)),
                           CMTimeRange(start: CMTimeMakeWithSeconds(0, 1), duration: CMTimeMakeWithSeconds(20, 1)),
                           CMTimeRange(start: CMTimeMakeWithSeconds(0, 1), duration: CMTimeMakeWithSeconds(10, 1))]
        
        let builder = AVAssetBuilder()
        let playerFactory = AVPlayerFactory()
        let player = playerFactory.prepareToPlay(builder, withAssets: assets, ranges: assetRanges, transition: TransitionType.crossDissolve)
        
        player.play()
        Wait(for: CMTimeGetSeconds((player.currentItem?.duration)!))
    }
}
