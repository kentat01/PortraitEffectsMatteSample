//
//  ViewController.swift
//  PortraitEffectsMatteSample
//
//  Created by 田中健太 on 2019/08/02.
//  Copyright © 2019 田中健太. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var maskedImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var matteImageView: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private var maskedImage: UIImage?
    private var documentInteractionController:UIDocumentInteractionController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Displayed when the background of the masked image is transparent
        backgroundView.backgroundColor = UIColor.init(patternImage:UIImage(named:"blockcheck")!)
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[.originalImage] as? UIImage,let imageURL = info[.imageURL] as? NSURL else {
            fatalError("Expected a dictionary containing an image and imageURL, but was provided the following: \(info)")
        }
        
        //Get portrait matte with CIImage
        var matteImage:UIImage?
        maskedImage = nil
        
        if var matteCIImage = portraitEffectsMatteCIImageAt(imageURL),let selectedCGImage = selectedImage.cgImage {
            
            //Get selected image with CIImage
            let selectedCIImage = CIImage(cgImage:selectedCGImage)
            
            //Use matteCIImage as a mask image.So make the same size as selectedCIImage
            let transform = CGAffineTransform(scaleX: selectedCIImage.extent.size.width / matteCIImage.extent.size.width,
                                              y: selectedCIImage.extent.size.height / matteCIImage.extent.size.height)
            matteCIImage = matteCIImage.transformed(by:transform)
            
            if  let filter = CIFilter(name: "CIBlendWithMask", parameters:[kCIInputImageKey: selectedCIImage,kCIInputMaskImageKey: matteCIImage]),
                let maskedCIImage = filter.outputImage{
                
                //Get the masked image with UIImage
                maskedImage = UIImage(ciImage: maskedCIImage)
                matteImage = UIImage(ciImage: matteCIImage)
            }
        }
        
        selectedImageView.image = selectedImage
        matteImageView.image = matteImage ?? UIImage(named:"defaultPhoto")
        maskedImageView.image = updateImage(maskedImage) ?? UIImage(named:"defaultPhoto")
        
        //Adjust the size of the background layer
        backgroundView.frame = AVMakeRect(aspectRatio:maskedImageView.image!.size, insideRect:maskedImageView.bounds)
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Actions
    @IBAction func save(_ sender: UIBarButtonItem) {
        if let saveImage = maskedImageView.image , let pngData = saveImage.pngData() {
            let saveImage = UIImage(data:pngData)
            UIImageWriteToSavedPhotosAlbum(saveImage!, self, nil, nil)
        }
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        
        do {
            guard let shareImage = maskedImageView.image,let pngData = shareImage.pngData() else {
                return
            }
            let imageURL = URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent("ShareImage.png"))
            try pngData.write(to: imageURL, options: .atomicWrite)
            self.documentInteractionController = UIDocumentInteractionController(url: imageURL)
            self.documentInteractionController!.presentOpenInMenu(from: sender, animated: true)
        } catch let error {
            print(error)
        }
    }
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        maskedImageView.image = updateImage(maskedImage) ?? UIImage(named:"defaultPhoto")
    }
    
    //MARK: Private Methods
    private func portraitEffectsMatteCIImageAt(_ fileURL: NSURL) -> CIImage? {
        
        // Check that the image at given path contains auxiliary PEM data:
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
            let auxiliaryInfoDict = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypePortraitEffectsMatte) as? [AnyHashable: Any],
            let matteData = try? AVPortraitEffectsMatte(fromDictionaryRepresentation: auxiliaryInfoDict),
            let matteCIImage = CIImage(portaitEffectsMatte: matteData)
            
            else {
                return nil
        }
        return matteCIImage
    }
    
    private func updateImage(_ image: UIImage?) -> UIImage?{
        
        guard let updateImage = image else {
            return nil
        }
        
        let backgroundImage:UIImage?
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            backgroundImage = UIImage.colorImage(color:UIColor.clear,size:updateImage.size)
        case 1:
            backgroundImage = UIImage.colorImage(color:UIColor.white,size:updateImage.size)
        case 2:
            backgroundImage = UIImage.colorImage(color:UIColor.black,size:updateImage.size)
        default:
            fatalError()
        }
        
        return  backgroundImage?.composite(updateImage)
    }
}
