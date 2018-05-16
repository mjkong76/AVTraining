//
//  THComposition.swift
//  AVTraining
//
//  Created by MJ.KONG-MAC on 16/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import Foundation
import AVFoundation

protocol THComposition {
    
    func makePlayable() -> AVPlayerItem
    func makeExportable() -> AVAssetExportSession
}
