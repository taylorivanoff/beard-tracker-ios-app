import UIKit
import AVFoundation
import AVKit

class ViewController: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    
    @IBOutlet weak var captureButton    : SwiftyRecordButton!
    @IBOutlet weak var flipCameraButton : UIButton!
    @IBOutlet weak var flashButton      : UIButton!
    
	override func viewDidLoad() {
		super.viewDidLoad()
    
        shouldPrompToAppSettings = true
		cameraDelegate = self
        defaultCamera = .front
        doubleTapCameraSwitch = false
        tapToFocus = true
		maximumVideoDuration = 10.0
        shouldUseDeviceOrientation = false
        allowAutoRotate = false
        audioEnabled = false
        flashMode = .off
        captureButton.buttonEnabled = false
        
        let faceOutline = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 272.0, height: 437.0))
        faceOutline.setImage(#imageLiteral(resourceName: "outline"), for: UIControl.State())
        faceOutline.isEnabled = false
        faceOutline.center = view.center
        view.addSubview(faceOutline)
        
        let cancelButton = UIButton(frame: CGRect(x: 0.0, y: view.frame.height - 112, width: 106, height: 112))
        cancelButton.setImage(#imageLiteral(resourceName: "back"), for: UIControl.State())
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Camera Permissions
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
          if response {
             print("User granted camera")
          } else {
             print("User has declined camera")
          }
        }
	}
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
	override var prefersStatusBarHidden: Bool {
		return true
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        captureButton.delegate = self
	}
    
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Camera session did start running")
        captureButton.buttonEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Camera session did stop running")
        captureButton.buttonEnabled = false
    }

	func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
		let newVC = PhotoViewController(image: photo)
        newVC.modalPresentationStyle = .fullScreen
		self.present(newVC, animated: true, completion: nil)
	}

	func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
		let newVC = VideoViewController(videoURL: url)
		self.present(newVC, animated: true, completion: nil)
	}

	func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        focusAnimationAt(point)
	}
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

	func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
		print(zoom)
	}

	func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
		print(camera)
	}
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print(error)
    }
}

// UI Animations
extension ViewController {

    fileprivate func focusAnimationAt(_ point: CGPoint) {
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
    
}
