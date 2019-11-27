//
//  VideoWatermarker.swift
//  FlappyBirdScream
//
//  Created by Mikita Manko on 5/4/17.
//  Copyright © 2017 Mikita Manko. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import SpriteKit

class VideoWatermarker {
    
    private func getImageLayer(height: CGFloat) -> CALayer {
        let imglogo = UIImage(named: "logo.png")
        
        let imglayer = CALayer()
        imglayer.contents = imglogo?.cgImage
        imglayer.frame = CGRect(
            x: 0, y: height - imglogo!.size.height/4,
            width: imglogo!.size.width/4, height: imglogo!.size.height/4)
        imglayer.opacity = 0.6
        
        return imglayer
    }
    
    private func getFramesAnimation(frames: [UIImage], duration: CFTimeInterval) -> CAAnimation {
        let animation = CAKeyframeAnimation(keyPath:#keyPath(CALayer.contents))
        animation.calculationMode = CAAnimationCalculationMode.discrete
        animation.duration = duration
        animation.values = frames.map {$0.cgImage!}
        animation.repeatCount = Float(frames.count)
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        
        return animation
    }
    
    private func addAudioTrack(composition: AVMutableComposition, videoAsset: AVURLAsset) {
        let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
        let audioTracks = videoAsset.tracks(withMediaType: AVMediaType.audio)
        for audioTrack in audioTracks {
            try! compositionAudioTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: CMTime.zero)
        }
    }

    func addOverlay(url: URL, frames: [UIImage], framesToSkip: Int, complete: @escaping(_:URL?)->()) {
        do {
            let composition = AVMutableComposition()
            let vidAsset = AVURLAsset(url: url)
            
            // get video track
            let videoTrack = vidAsset.tracks(withMediaType: AVMediaType.video)[0]
            let duration = vidAsset.duration
            let vid_timerange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
            let size = videoTrack.naturalSize
            // Due to the 90 deg rotation
            let width = size.height
            let height = size.width
            
            let compositionvideoTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
            
            try compositionvideoTrack.insertTimeRange(vid_timerange, of: videoTrack, at: CMTime.zero)
            compositionvideoTrack.preferredTransform = videoTrack.preferredTransform
            // Watermark Effect
            
            // Set up layers
            let imglayer = getImageLayer(height: height)
            
            // Original video from frontal camera.
            let videolayer = CALayer()
            videolayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
            videolayer.opacity = 1.0
            
            // Low fps Frames from the game.
            let watermarkLayer = CALayer()
            watermarkLayer.contents = frames[0].cgImage
            watermarkLayer.add(
                getFramesAnimation(frames: frames, duration: vidAsset.duration.seconds), forKey: nil)
            let frameAspectRatio = CGFloat(frames[0].cgImage!.height) / CGFloat(frames[0].cgImage!.width)
            let newHeight = height/3
            let newWidth = newHeight/frameAspectRatio
            watermarkLayer.frame = CGRect(
                x: width - newWidth, y: 0, width: newWidth, height: newHeight)
            watermarkLayer.opacity = 0.85
            
            
            // Combine layers
            let parentlayer = CALayer()
            parentlayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
            parentlayer.addSublayer(videolayer)
            parentlayer.addSublayer(watermarkLayer)
            parentlayer.addSublayer(imglayer)
            
            let layercomposition = AVMutableVideoComposition()
            layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
            layercomposition.renderScale = 1.0
            layercomposition.renderSize = CGSize(width: size.height, height: size.width)
            
            // Enable animation for video layers
            layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(
                postProcessingAsVideoLayers: [videolayer], in: parentlayer)

            
            // instruction for watermark
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
            let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            layerinstruction.setTransform(videoTrack.preferredTransform, at: CMTime.zero)
            instruction.layerInstructions = [layerinstruction] as [AVVideoCompositionLayerInstruction]
            layercomposition.instructions = [instruction] as [AVVideoCompositionInstructionProtocol]

            
            // Add audio track.
            addAudioTrack(composition: composition, videoAsset: vidAsset)
            
            // Clear url.
            let movieDestinationUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "/watermark.mp4")
            try? FileManager().removeItem(at: movieDestinationUrl)

            
            
            // Use AVAssetExportSession to export video
            let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality)
            assetExport?.outputFileType = AVFileType.mov
            assetExport?.outputURL = movieDestinationUrl
            assetExport?.videoComposition = layercomposition
            
            assetExport?.exportAsynchronously(completionHandler: {
                switch assetExport!.status {
                case AVAssetExportSessionStatus.failed:
                    print("failed")
                    print(assetExport?.error ?? "unknown error")
                    complete(nil)
                case AVAssetExportSessionStatus.cancelled:
                    print("cancelled")
                    print(assetExport?.error ?? "unknown error")
                    complete(nil)
                default:
                    print("Movie complete")
                    complete(movieDestinationUrl)
                }
            })
        } catch {
            print("VideoWatermarker->getWatermarkLayer everything is baaaad =(")
        }
    }
    
}
