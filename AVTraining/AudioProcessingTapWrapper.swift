//
//  AudioProcessingTapWrapper.swift
//  AVTraining
//
//  Created by MJ.KONG-MAC on 18/05/2018.
//  Copyright © 2018 NexStreaming Corp. All rights reserved.
//

import Foundation
import MediaToolbox
import CoreAudioKit

extension String {
    public static func fourByteCodeString(code: UInt32) -> String {
        return String.init(format: "'%c%c%c%c'", (code >> 24) & 0xFF, (code >> 16) & 0xFF, (code >> 8) & 0xFF, code & 0xFF)
    }
}

class AudioProcessingTapWrapper {
    
    var tap: Unmanaged<MTAudioProcessingTap>?
    
    let tapInit: MTAudioProcessingTapInitCallback = {
        /*
         @param tap
                The processing tap.
         @param clientInfo
                The client data of the processing tap passed in callbacks struct in MTAudioProcessingTapCreate().
         @param tapStorageOut
                Additional client data.  The intent is for clients to allocate a block of memory for use within their custom
                MTAudioProcessingTap implementation that will be freed when the finalize callback is invoked.  This argument
                is optional.
         */
        (tap: MTAudioProcessingTap, clientInfo: UnsafeMutableRawPointer?, tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>) in
        
        print("mj-debug. tapInit \(clientInfo, tapStorageOut)")
    }
    
    let tapFinalize: MTAudioProcessingTapFinalizeCallback = {
        /*
         @param tap
                The processing tap.
         */
        (tap: MTAudioProcessingTap) in
        
        print("mj-debug. tapFinalize")
    }
    
    let tapPrepare: MTAudioProcessingTapPrepareCallback = {
        /*
         @param tap
                The processing tap.
         @param maxFrames
                The maximum number of sample frames that can be requested of a processing
                tap at any one time. Typically this will be approximately 50 msec of audio
                (2048 samples @ 44.1kHz).
         @param processingFormat
                The format in which the client will receive the audio data to be processed.
                This will always be the same sample rate as the client format and usually
                the same number of channels as the client format of the audio queue. (NOTE:
                the number of channels may be different in some cases if the client format
                has some channel count restrictions; for example, if the client provides 5.1
                AAC, but the decoder can only produce stereo). The channel order, if the
                same as the client format, will be the same as the client channel order. If
                the channel count is changed, it will be to either 1 (mono) or 2 (stereo, in
                which case the first channel is left, the second right).

                If the data is not in a convenient format for the client to process in, then
                the client should convert the data to and from that format. This is the most
                efficient mechanism to use, as the audio system may choose a format that is
                most efficient from its playback requirement.
         */
        (tap: MTAudioProcessingTap, maxFrames: CMItemCount, processingFormat: UnsafePointer<AudioStreamBasicDescription>) in
        
        print("mj-debug. tapPrepare \(maxFrames, String.fourByteCodeString(code: processingFormat.pointee.mFormatID))")
    }
    
    let tapUnprepare: MTAudioProcessingTapUnprepareCallback = {
        /*
         @param tap
                The processing tap.
         */
        (tap: MTAudioProcessingTap) in
        
        print("mj-debug. tapUnprepare")
    }
    
    let tapProcess: MTAudioProcessingTapProcessCallback = {
        /*
         @param tap
            The processing tap.
         @param numberFrames
            The requested number of sample frames that should be rendered.
         @param flags
            The flags passed at construction time are provided.
         @param bufferListInOut
             The audio buffer list which will contain processed source data.
             On input, all fields except for the buffer pointers will be filled in,
             and can be passed directly to GetSourceAudio() if in-place processing is
             desired.
             On output, the bufferList should contain the processed audio buffers.
         @param numberFramesOut
            The number of frames of audio data provided in the processed data. Can be 0.
         @param flagsOut
            The start/end of stream flags should be set when appropriate (see Discussion, above).
         */
        (tap: MTAudioProcessingTap, numberFrames: CMItemCount, flags: MTAudioProcessingTapFlags, bufferListInOut:  UnsafeMutablePointer<AudioBufferList>, numberFramesOut: UnsafeMutablePointer<CMItemCount>, flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>) in
        
        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
        print("mj-debug. tapProcess \(status, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)\n")
    }
    
    init() {
        var callbacks = MTAudioProcessingTapCallbacks(version: kMTAudioProcessingTapCallbacksVersion_0,
                                                      clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                                                      init: tapInit,
                                                      finalize: tapFinalize,
                                                      prepare: tapPrepare,
                                                      unprepare: tapUnprepare,
                                                      process: tapProcess)
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        if err != noErr {
            // error
            tap = nil
        }
    }
}
