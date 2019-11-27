import UIKit
import CoreData
import NotificationCenter

class PhotoViewController: UIViewController {

	private var backgroundImage: UIImage
    
    var appDelegate = UIApplication.shared.delegate as? AppDelegate

	init(image: UIImage) {
		self.backgroundImage = image
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
        
		self.view.backgroundColor = UIColor.black
        
		let backgroundImageView = UIImageView(frame: view.frame)
		backgroundImageView.contentMode = UIView.ContentMode.scaleAspectFit
		backgroundImageView.image = backgroundImage
		view.addSubview(backgroundImageView)
        
        let cancelButton = UIButton(frame: CGRect(x: 0, y: view.frame.height - 112, width: 106, height: 112))
		cancelButton.setImage(#imageLiteral(resourceName: "cancel"), for: UIControl.State())
		cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
		view.addSubview(cancelButton)
        
        let downloadButton = UIButton(frame: CGRect(x: view.frame.width - 140, y: view.frame.height - 112, width: 148, height: 112))
        downloadButton.setImage(#imageLiteral(resourceName: "accept"), for: UIControl.State())
        downloadButton.addTarget(self, action: #selector(accept), for: .touchUpInside)
        view.addSubview(downloadButton)
	}

	@objc func cancel() {
		dismiss(animated: true, completion: nil)
	}
    
    @objc func accept() {
        ModelController().saveImageObject(image: backgroundImage)

        if (!MainMenuController().isKeyPresentInUserDefaults(key:"dayCounter")) {
            MainMenuController().setDayCounter(day: 0)
        }

        MainMenuController().setDayCounter(day: (MainMenuController().getDayCounter() + 1))
        MainMenuController().setLastPhotoDate(date: Date())
        
        // schedule next day notification
        self.appDelegate?.scheduleNotification(title: "Track your growth", body: "Let's capture that new fuzz", hours: 16)
        
        if (MainMenuController().getDayCounter() == 5) {
            self.appDelegate?.scheduleNotification(title: "Save your first timelapse", body: "Let's capture that new fuzz", hours: 1)
        }
        
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
}
