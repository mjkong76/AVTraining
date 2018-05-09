//
//  AVAssetsTests.swift
//  AVAssetsTests
//
//  Created by MJ.KONG-MAC on 04/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import Foundation
import AVFoundation
import XCTest

class AVAssetsTests: XCTestCase {
    
    var localURL: URL?
    
    override func setUp() {
        super.setUp()
        localURL = Bundle.main.url(forResource: "roller", withExtension: "mp4")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAssets() {
        let asset = AVAsset.init(url: localURL!)
        let keys: [String] = ["duration"];
        
        asset.loadValuesAsynchronously(forKeys: keys) {
            for key in keys {
                var error: NSError? = nil
                let status: AVKeyValueStatus = asset.statusOfValue(forKey: key, error: &error)
                if status == .loaded {
                    if key == "duration" {
                        let RollerDurationSecond = 31.68
                        XCTAssert(CMTimeGetSeconds(asset.duration) == RollerDurationSecond,
                                  "different from source: \(asset.duration.seconds)")
                    }
                } else if status == .failed {
                    print("error: \(String.init(describing: error?.localizedDescription))")
                }
            }
        }
        Wait(for: 10)
    }
    
}
