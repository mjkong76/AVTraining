//
//  AssetTests.swift
//  AVTrainingTests
//
//  Created by MJ.KONG-MAC on 16/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import XCTest
import AVFoundation

class AssetTests: XCTestCase {
    
    var videoAsset: THVideoItem?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        timeLabel.isHidden = true
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPrepareVideoAsset() {
        
        let rollerURL = Bundle.main.url(forResource: "roller", withExtension: "mp4")
        videoAsset = THVideoItem(withURL: rollerURL!)
        videoAsset?.prepareWithAClosure { [weak self](complete: Bool) in
            
            XCTAssert(complete, "videoAsset not prepared. prepared value: \(String(describing:(self?.videoAsset?.prepared)!))")

            let asset = self?.videoAsset?.asset
            let rollerAssetDurationInSecond = 31.68
            XCTAssert(CMTimeGetSeconds((asset?.duration)!) == rollerAssetDurationInSecond,
                      "different from source: \(String(describing: asset?.duration.seconds))")
        }
        Wait(for: 10)
    }
}
