import UIKit
import Foundation

class MainMenuController: UIViewController {
    
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var progressButton: UIButton!
    @IBOutlet weak var cooldownLabel: UILabel!
    
    @IBAction func captureButton(_ sender: Any) {
        performSegue(withIdentifier: "mainToCamera", sender: self)
    }
    
    @IBAction func progressButton(_ sender: Any) {
        performSegue(withIdentifier: "mainToProgress", sender: self)
    }
    
    @IBAction func clear(_ sender: Any) {
        let alert = UIAlertController(title: "Clear data", message: "Are you sure you want to delete all your progress pictures?", preferredStyle: .alert)
        
        let clearAction = UIAlertAction(title: "Yes", style: .destructive) { (alert: UIAlertAction!) -> Void in
            if let appDomain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: appDomain)
            }

            ModelController().deleteAllImageObjects()
            
            exit(-1)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (alert: UIAlertAction!) -> Void in }
            
        alert.addAction(cancelAction)
        alert.addAction(clearAction)

        present(alert, animated: true, completion:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        disable(label: cooldownLabel)
        enable(button: captureButton)
        disable(button: progressButton)
        
        if (isKeyPresentInUserDefaults(key:"dayCounter")) {
            // user has taken a picture before
            if (getDayCounter() > 0) {
                enable(button: progressButton)
                
                if (isKeyPresentInUserDefaults(key:"lastPhotoDate")) {
                    // but user already took a photo today
                    if (!(getLastPhotoDate().daysSinceNow.day! > 0)) {
                        enable(label: cooldownLabel)
                        disable(button: captureButton)
                    }
                }
            }
        }
    }

    func getDayCounter() -> Int {
        return UserDefaults.standard.integer(forKey: "dayCounter")
    }
    
    func setDayCounter(day: Int) {
        UserDefaults.standard.set(day, forKey: "dayCounter")
    }
    
    func getLastPhotoDate() -> Date {
        return UserDefaults.standard.string(forKey: "lastPhotoDate")!.asDate
    }
    
    func setLastPhotoDate(date: Date) {
        UserDefaults.standard.set(stringFromDate(date), forKey: "lastPhotoDate")
    }

    func enable(button: UIButton) {
       button.alpha = 1
       button.isEnabled = true
    }

    func disable(button: UIButton) {
       button.alpha = 0.2
       button.isEnabled = false
    }

    func enable(label: UILabel) {
        label.alpha = 0.6
    }

    func disable(label: UILabel) {
       label.alpha = 0
    }
       
    func stringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: date)
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}

extension String {
    /// Returns a date from a string in MMMM dd, yyyy. Will return today's date if input is invalid.
    var asDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.date(from: self) ?? Date()
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var daysSinceNow: DateComponents {
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MMMM dd, yyyy"
        return Calendar.current.dateComponents([.day], from: self, to: now)
    }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}
