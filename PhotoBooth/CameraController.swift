//
//  CameraController.swift
//  PhotoBooth
//
//  Created by Ben D. Jones on 9/12/15.
//  Copyright © 2015 Ben D. Jones. All rights reserved.
//

import Foundation
import UIKit

class CameraController: UIViewController {
    @IBOutlet var photoViews: [UIView]!
    
    @IBOutlet weak var countDownLabel: UILabel!
    
    private var displayLink: CADisplayLink?
    private var fastLink: CADisplayLink?
    
    weak var pickerController: UIImagePickerController?
    
    private var justSnapped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoViews.forEach {
            $0.layer.cornerRadius = $0.bounds.size.width / 2
            $0.layer.masksToBounds = true
            $0.backgroundColor = UIColor.clearColor()
            $0.layer.borderColor = UIColor.whiteColor().CGColor
            $0.layer.borderWidth = 1
        }
    }
    
    func startCaptureSeries() {
        fastLink?.invalidate()
        
        let firstDelayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(firstDelayTime, dispatch_get_main_queue()) {
            self.countDownLabel.text = "Start"
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                let displayLink = CADisplayLink(target: self, selector: Selector("displayLinkFired:"))
                displayLink.frameInterval = 120
                
                let fastLink = CADisplayLink(target: self, selector: Selector("fastLinkFired:"))
                fastLink.frameInterval = 10
                fastLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
                self.fastLink = fastLink
        
                displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
                self.displayLink = displayLink
            }
        }
    }
    
    func fastLinkFired(sender: CADisplayLink) {
        if justSnapped {
            justSnapped = false
            view.backgroundColor = UIColor.clearColor()
        }
    }
    
    var numPhotosTaken: Int = 0 {
        didSet {
            let effected = photoViews[photoViews.startIndex..<numPhotosTaken]
            
            effected.forEach {
                $0.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    private func flashView(didSnap: Bool) {
        justSnapped = true
        
        let alphaAmount: CGFloat = didSnap ? 0.45 : 0.2
        view.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(alphaAmount)
    }
    
    func displayLinkFired(sender: CADisplayLink) {
        if countDownLabel?.text == "Start" {
            flashView(false)
            countDownLabel?.text = "1"
            
            return
        }
        
        guard let text = countDownLabel?.text else { return }
        guard let fastLink = fastLink else { return }
        
        if let value = Int(text) where value < 3 {
            flashView(false)
            countDownLabel?.text = String(value + 1)
        } else {
            flashView(true)
            displayLink?.invalidate()
            self.pickerController?.takePicture()
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.fastLinkFired(fastLink)
                
                self.countDownLabel?.text = "Nice!"
            }
        }
    }
}