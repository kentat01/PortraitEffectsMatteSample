//
//  UIImage+Extension.swift
//  BackgroundImageEditor
//
//  Created by 田中健太 on 2019/08/02.
//  Copyright © 2019 田中健太. All rights reserved.
//

import UIKit

extension UIImage {
    class func colorImage(color: UIColor, size: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContext(size)
        let rect = CGRect(origin: CGPoint.zero, size: size)
        
        var image:UIImage?
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
            
        return image
    }
    
    func composite(_ image: UIImage) -> UIImage? {
        
        UIGraphicsBeginImageContext(self.size)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        image.draw(in:CGRect(x:0, y:0, width: image.size.width, height: image.size.height))
        
        let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return compositeImage
    }

}
