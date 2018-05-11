//
//  AVAssetEditAudioTests.swift
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
import MediaToolbox

class AVAssetEditAudioTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func buildAudioMix(player: AVPlayer) {
        let audioMix = AVMutableAudioMix()
        let audioTracks = player.currentItem?.asset.tracks(withMediaType: AVMediaTypeAudio)
        XCTAssertTrue(audioTracks?.count != 0, "audioTrack not exist")
        let audioMixInputParameter = AVMutableAudioMixInputParameters.init(track: audioTracks?.first)
        audioMixInputParameter.setVolume(0, at: kCMTimeZero)
        audioMixInputParameter.setVolume(1, at: CMTimeMake(5, 1))
        audioMixInputParameter.setVolume(0, at: CMTimeMake(8, 1))
        audioMix.inputParameters = [audioMixInputParameter]
        player.currentItem?.audioMix = audioMix
    }
    
    func testPlayback() {
        
        let assets = [AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "sample_clip1", ofType: "m4v")!))]
        let assetRanges = [CMTimeRange(start: CMTimeMakeWithSeconds(0, 1), duration: CMTimeMakeWithSeconds(10, 1))]
        
        let builder = AVAssetBuilder()
        let playerFactory = AVPlayerFactory()
        let player = playerFactory.prepareToPlay(builder, withAssets: assets, ranges: assetRanges, transition: TransitionType.none)
        
        buildAudioMix(player: player)
        player.play()
        Wait(for: CMTimeGetSeconds((player.currentItem?.duration)!))
    }

}
