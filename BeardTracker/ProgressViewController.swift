import UIKit
import CoreData
import ImageIO
import MobileCoreServices
import AVFoundation
import Photos
import Foundation
import Photos

class ProgressViewController: UIViewController {

    var images: [NSManagedObject] = []
    
    var backgroundImageView: UIImageView!
    var cancelButton: UIButton!
    var downloadButton: UIButton!
    
    let outputSize = CGSize(width: 900, height: 1600)
    let imagesPerSecond: TimeInterval = 1
    var selectedPhotosArray = ModelController().images
    var imageArrayToVideoURL = NSURL()
    let audioIsEnabled: Bool = false
    var asset: AVAsset!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBOutlet weak var notEnoughDaysLabel: UILabel!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        
        backgroundImageView = UIImageView(frame: view.frame)
        backgroundImageView.contentMode = UIView.ContentMode.scaleAspectFill
        backgroundImageView.animationImages = ModelController().images;
        backgroundImageView.animationDuration = 4.0
        backgroundImageView.startAnimating()
        view.addSubview(backgroundImageView)
        
        cancelButton = UIButton(frame: CGRect(x: 0.0, y: view.frame.height - 112, width: 106.0, height: 112.0))
        cancelButton.setImage(#imageLiteral(resourceName: "back"), for: UIControl.State())
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        downloadButton = UIButton(frame: CGRect(x: view.frame.width - 140, y: view.frame.height - 112, width: 148.0, height: 112.0))
        downloadButton.setImage(#imageLiteral(resourceName: "download"), for: UIControl.State())
        downloadButton.addTarget(self, action: #selector(download), for: .touchUpInside)
        downloadButton.isEnabled = false
        downloadButton.alpha = 0.6
        view.addSubview(downloadButton)
        
        let daysTillOk = (5 - MainMenuController().getDayCounter())
        notEnoughDaysLabel.text = (daysTillOk > 1) ? "\(daysTillOk) more days needed" : "\(daysTillOk) more day needed"
        notEnoughDaysLabel.alpha = 0.6;
        notEnoughDaysLabel.layer.zPosition = 1
    
        // permit user to save timelapse
        if (MainMenuController().getDayCounter() > 4) {
            downloadButton.isEnabled = true
            downloadButton.alpha = 1
            
            notEnoughDaysLabel.alpha = 0;
        }
        
        // Photos Permissions
        let status = PHPhotoLibrary.authorizationStatus()
        if (status == PHAuthorizationStatus.authorized) {
            print("User granted photo library")
        } else if (status == PHAuthorizationStatus.denied) {
            print("User has declined photo library")
        } else if (status == PHAuthorizationStatus.notDetermined) {
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if (newStatus == PHAuthorizationStatus.authorized) {} else {}
            })
        } else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
        }
    }

    func buildVideoFromImageArray() {
        imageArrayToVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video.mp4")
        removeFileAtURLIfExists(url: imageArrayToVideoURL)
        
        guard let videoWriter = try? AVAssetWriter(outputURL: imageArrayToVideoURL as URL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter error")
        }
        let outputSettings = [AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : NSNumber(value: Float(outputSize.width)), AVVideoHeightKey : NSNumber(value: Float(outputSize.height))] as [String : Any]
        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Failed to apply output settings")
        }
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        
        if videoWriter.startWriting() {
            let zeroTime = CMTimeMake(value: Int64(imagesPerSecond), timescale: Int32(1))
            videoWriter.startSession(atSourceTime: zeroTime)

            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                let fps: Int32 = 1
                let framePerSecond: Int64 = Int64(self.imagesPerSecond)
                let frameDuration = CMTimeMake(value: Int64(self.imagesPerSecond), timescale: fps)
                var frameCount: Int64 = 0
                var appendSucceeded = true
                while (!self.selectedPhotosArray.isEmpty) {
                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let nextPhoto = self.selectedPhotosArray.remove(at: 0)
                        let lastFrameTime = CMTimeMake(value: frameCount * framePerSecond, timescale: fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        if let pixelBuffer = pixelBuffer, status == 0 {
                            let managedPixelBuffer = pixelBuffer
                            CVPixelBufferLockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGContext(data: data, width: Int(self.outputSize.width), height: Int(self.outputSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(managedPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                            context!.clear(CGRect(x: 0, y: 0, width: CGFloat(self.outputSize.width), height: CGFloat(self.outputSize.height)))
                            let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto.size.width
                            let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto.size.height
                            //let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
                            let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
                            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
                            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0
                            context?.draw(nextPhoto.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                    frameCount += 1
                }
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { () -> Void in
                    
                    print("----Video URL = \(self.imageArrayToVideoURL)")
                    self.asset = AVAsset(url: self.imageArrayToVideoURL as URL)

                    let outputURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video-merged.mp4")
                    self.removeFileAtURLIfExists(url: outputURL)

                    let inputURL = self.imageArrayToVideoURL
                    
                    self.addWatermark(image: UIImage(named: "logo-white")!, x: 30 , y: 30, inputURL: inputURL as URL, outputURL: outputURL as URL, handler: { (exportSession) in
                        guard let session = exportSession else {
                            return
                        }
                        switch session.status {
                            case .completed:
                            guard NSData(contentsOf: outputURL as URL) != nil else {
                                return
                            }
                            PHPhotoLibrary.shared().performChanges({
                               PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL as URL)
                            }) { saved, error in
                               if saved {
                                   print("----Video successfully saved.")
                               }
                            }
                        default: break
                        }
                    })
                    

                }
            })
        }
    }
    
    func addWatermark(image: UIImage, x: CGFloat, y: CGFloat, inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let mixComposition = AVMutableComposition()
        let asset = AVAsset(url: inputURL)
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        let timerange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        let compositionVideoTrack:AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))!

        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error.localizedDescription)
        }

        let watermarkFilter = CIFilter(name: "CISourceOverCompositing")!
        let watermarkImage = CIImage(image: image)

        let videoComposition = AVVideoComposition(asset: asset) { (filteringRequest) in
            let source = filteringRequest.sourceImage.clampedToExtent()
            
            watermarkFilter.setValue(source, forKey: "inputBackgroundImage")
            
            let transform = CGAffineTransform(translationX: filteringRequest.sourceImage.extent.width - (watermarkImage?.extent.width)! - x, y: y)
            
            watermarkFilter.setValue(watermarkImage?.transformed(by: transform), forKey: "inputImage")
            
            filteringRequest.finish(with: watermarkFilter.outputImage!, context: nil)
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            handler(nil)
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
    func removeFileAtURLIfExists(url: NSURL) {
        if let filePath = url.path {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                do{
                    try fileManager.removeItem(atPath: filePath)
                } catch let error as NSError {
                    print("Couldn't remove existing destination file: \(error)")
                }
            }
        }
    }

    @objc func download() {
        buildVideoFromImageArray()
        
        downloadButton.setImage(#imageLiteral(resourceName: "accept"), for: UIControl.State())
        
        let secondsToDelay = 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsToDelay) {
            self.dismiss(animated: true, completion: nil)
            UIApplication.shared.open(URL(string:"photos-redirect://")!)
        }
    }
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

}
