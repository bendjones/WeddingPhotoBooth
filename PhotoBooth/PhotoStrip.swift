//
//  PhotoStrip.swift
//  PhotoBooth
//
//  Created by Ben D. Jones on 9/12/15.
//  Copyright © 2015 Ben D. Jones. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

struct PhotoStrip {
    let photos: [UIImage]
    let brandImage: UIImage
    
    init(photos: [UIImage], logo: UIImage) {
        self.photos = photos.reverse().map { $0.fixOrientation() }
        
        brandImage = logo
    }
    
    func renderResult(completionHandler: (UIImage -> Void)) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            let maxWidth: CGFloat = self.photos.reduce(CGFloat(0)) { return max($0.0, $0.1.size.width) }
            let totalHeight: CGFloat = self.photos.reduce(CGFloat(10)) { return $0.0 + $0.1.size.height + 10 }
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: maxWidth, height: totalHeight), false, UIScreen.mainScreen().scale)
            let context = UIGraphicsGetCurrentContext()
            
            var currentOrigin = CGPoint(x: 0, y: 10)
            self.photos.forEach {
                let rect = CGRect(origin: currentOrigin, size: $0.size)
                CGContextDrawImage(context, rect, $0.CGImage)
                currentOrigin = CGPoint(x: 0, y: currentOrigin.y + $0.size.height + 10)
            }
            
            // NOTE: Draw the logo on the final image
            let brandOrigin = CGPoint(x: maxWidth - self.brandImage.size.width, y: 10)
            let brandRect = CGRect(origin: brandOrigin, size: self.brandImage.size)
            CGContextDrawImage(context, brandRect, self.brandImage.CGImage)
            
            
            let upsidedownImage = UIGraphicsGetImageFromCurrentImageContext()
            let image = UIImage(CGImage: upsidedownImage.CGImage!, scale: UIScreen.mainScreen().scale, orientation: .DownMirrored)
            
            UIGraphicsEndImageContext()
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(image)
            }
        }
    }
}

extension UIImage {
    private func fixOrientation() -> UIImage {
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = CGAffineTransformIdentity
        
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        switch imageOrientation {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform,  CGFloat(-M_PI_2))
        case .Up:
            return self
        default:
            debugPrint("No op")
        }
        
        // Second pass
        switch imageOrientation {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        default:
            debugPrint("No op")
        }
        
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), CGImageGetBitsPerComponent(CGImage), 0, CGImageGetColorSpace(CGImage), CGImageGetBitmapInfo(CGImage).rawValue)
        CGContextConcatCTM(ctx, transform)
        
        
        switch imageOrientation {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            let rect = CGRect(x: 0, y: 0, width: size.height, height: size.width)
            CGContextDrawImage(ctx, rect, CGImage)
        default:
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            CGContextDrawImage(ctx, rect, CGImage)
        }
        
        
        // And now we just create a new UIImage from the drawing context
        let cgimg: CGImageRef = CGBitmapContextCreateImage(ctx)!
        let imgEnd:UIImage = UIImage(CGImage: cgimg)
        
        return imgEnd
    }
    
    class func resizeImage(image: UIImage, newHeight: CGFloat) -> UIImage {
        
        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
