//
//  ViewController.swift
//  PhotoBooth
//
//  Created by Ben D. Jones on 9/12/15.
//  Copyright © 2015 Ben D. Jones. All rights reserved.
//

import UIKit
import MessageUI

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    private var prompting = false
    private var photos = [UIImage]()
    
    private var imageController: UIImagePickerController?
    
    lazy var cameraController: CameraController? = {
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("CameraController") as? CameraController
        
        vc?.view.frame = self.view.frame
        vc?.view.layoutIfNeeded()
        
        return vc
    }()
    
    var photoStrip: PhotoStrip? {
        didSet {
            if let strip = photoStrip {
                self.imageView?.hidden = false
                self.instructionsLabel.hidden = true
                self.titleLabel.hidden = true
                strip.renderResult {
                    let animation = CABasicAnimation()
                    animation.keyPath = "backgroundColor"
                    animation.toValue = UIColor.blackColor()
                    animation.fromValue = UIColor.whiteColor()
                    animation.duration = 0.4
                    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                    self.view.layer.addAnimation(animation, forKey: "BGColorAnimation")
                    
                    self.view.backgroundColor = UIColor.blackColor()
                    self.imageView.image = UIImage.resizeImage($0, newHeight: self.view.bounds.height)
                    self.imageView?.setNeedsLayout()
                    
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                        self.promptForActions()
                    }
                }
            } else {
                let animation = CABasicAnimation()
                animation.keyPath = "backgroundColor"
                animation.toValue = UIColor.whiteColor()
                animation.fromValue = UIColor.blackColor()
                animation.duration = 0.4
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                view.layer.addAnimation(animation, forKey: "BGColorAnimation")
                
                view.backgroundColor = UIColor.whiteColor()
                imageView?.image = nil
                instructionsLabel.hidden = false
                titleLabel.hidden = false
                photos.removeAll(keepCapacity: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func tapGestureTriggered(sender: UITapGestureRecognizer) {
        if let _ = photoStrip {
            promptForActions()
        } else {
            startCaptureSeries()
        }
    }
    
    private func promptForActions() {
        let alert = UIAlertController(title: "Photo Booth", message: "Awesome!", preferredStyle: .ActionSheet)
        let printAction = UIAlertAction(title: "Print", style: .Default) { _ in
            alert.dismissViewControllerAnimated(false, completion: nil)
            
            self.printImageTapped()
        }
        
        let emailAction = UIAlertAction(title: "Email", style: .Default) { _ in
            alert.dismissViewControllerAnimated(false, completion: nil)
            
            self.showEmailDialog()
        }
        
        let restartAction = UIAlertAction(title: "Start Over", style: .Destructive) { _ in
            self.photoStrip = nil
            
            alert.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Nevermind", style: .Cancel) { _ in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alert.addAction(printAction)
        alert.addAction(emailAction)
        alert.addAction(restartAction)
        alert.addAction(cancelAction)
        
        if let popoverPresenter = alert.popoverPresentationController {
            alert.modalPresentationStyle = .Popover
            
            popoverPresenter.sourceView = view
            popoverPresenter.sourceRect = CGRect(x: view.frame.width / 2 - 150, y: view.bounds.height - 625, width: 300, height: 300)
            popoverPresenter.permittedArrowDirections = .Up
        }
        
        if let pvc = presentedViewController {
            pvc.dismissViewControllerAnimated(false) {
                self.presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func startCaptureSeries() {
        if let _ = UIImagePickerController.availableCaptureModesForCameraDevice(.Front) {
            let imageController = UIImagePickerController()
            
            imageController.sourceType = .Camera
            
            imageController.cameraCaptureMode = .Photo
            imageController.cameraDevice = .Front
            imageController.cameraFlashMode = .Off

            imageController.delegate = self
            imageController.edgesForExtendedLayout = .All
            
            if let
                ccVC = cameraController,
                imgControllerOverlayFrame = imageController.cameraOverlayView?.frame
            {
                ccVC.view.frame = imgControllerOverlayFrame
                imageController.cameraOverlayView = ccVC.view
                
                let screenSize = UIScreen.mainScreen().bounds.size
                let cameraAspectRatio: CGFloat = 4.0 / 3.0 //! Note: 4.0 and 4.0 works
                let imageWidth = floorf(Float(screenSize.width * cameraAspectRatio))
                
                let heightByImageWidth = Float(screenSize.height + 120) / imageWidth
                let scale = CGFloat(ceilf((heightByImageWidth * 10.0) / 10.0))
                
                imageController.cameraViewTransform = CGAffineTransformMakeScale(scale, scale)
            }
            
            imageController.modalPresentationStyle = .OverCurrentContext
            imageController.transitioningDelegate = self
            imageController.showsCameraControls = false
            imageController.navigationBarHidden = true
            
            cameraController?.pickerController = imageController
            self.imageController = imageController
            
            prompting = true
            
            presentViewController(imageController, animated: true) {
                cameraController?.startCaptureSeries()
            }
        } else {
            showAlert("Facetime camera not present!")
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Photo Booth", message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Ok", style: .Cancel) { _ in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alert.addAction(okAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }

    private func printImageTapped() {
        let printActionController = UIPrintInteractionController.sharedPrintController()
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .Photo
        printInfo.jobName = "PhotoStrip"
        printInfo.duplex = .None
        printActionController.printInfo = printInfo
        printActionController.showsPageRange = false
        
        let handler: UIPrintInteractionCompletionHandler = { controller, completed, error in
            guard error == nil else {
                if let error = error {
                    controller.dismissAnimated(true)
                    
                    self.showAlert(error.localizedDescription)
                }
                
                
                return
            }
            
            if completed {
                self.promptForActions()
            } else {
                controller.dismissAnimated(false)
                self.showAlert("Printing failed!")
            }
        }
        
        photoStrip?.renderResult {
            printActionController.printingItem = $0
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                printActionController.presentFromRect(self.view.frame, inView: self.view, animated: true, completionHandler: handler)
            } else {
                printActionController.presentAnimated(true, completionHandler: handler)
            }
        }
    }
}

extension ViewController : UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransitionAnimator()
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransitionAnimator()
    }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            photos.append(pickedImage)
            cameraController?.numPhotosTaken = photos.count
            
            if photos.count == 3 {
                self.makeBoothPhotos()
                
                picker.dismissViewControllerAnimated(true, completion: nil)
                imageController = nil
            } else {
                cameraController?.startCaptureSeries()
            }
        }
    }
    
    private func makeBoothPhotos() {
        guard let brandImage = UIImage(named: "BrandImage") else { return }
        
        self.photoStrip = PhotoStrip(photos: self.photos, logo: brandImage)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

struct Formatters {
    static let prettyDateTimeFormatterLocal: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone.defaultTimeZone()
        
        let locale = NSLocale.currentLocale()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.locale = locale
        
        return dateFormatter
    }()
}

extension ViewController {
    func showEmailDialog() {
        if MFMailComposeViewController.canSendMail() {
            let idealSubject = "Photo booth @ Kim and Ben's Wedding took a photo at \(Formatters.prettyDateTimeFormatterLocal.stringFromDate(NSDate()))"
            
            let composeVC = MFMailComposeViewController(nibName: nil, bundle: nil)
            composeVC.mailComposeDelegate = self
            composeVC.setToRecipients(["mobile@socialcodeinc.com"])
            composeVC.setSubject(idealSubject)
            composeVC.setMessageBody("Thanks for coming! We love you!", isHTML: false)
            photoStrip?.renderResult {
                guard let resultData = UIImageJPEGRepresentation($0, 0.84) else { return }
                
                composeVC.addAttachmentData(resultData, mimeType: "image/jpeg", fileName: "PhotoBooth.jpeg")
                
                self.presentViewController(composeVC, animated: true, completion: nil)
            }
        } else {
            showAlert("Shit! Can't send mail.... help find a nerd!")
        }
    }
}


extension ViewController : MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        if let error = error {
            controller.dismissViewControllerAnimated(true) {
                self.showAlert(error.localizedDescription)
            }
        } else {
            controller.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

