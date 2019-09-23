//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/14/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    var photo: Photo!
    @IBOutlet weak var imageOverlay: UIView!
    
    /// Set up the cell's imageView by downloading or reusing photos that have already been downloaded.
//    func setUpPhotoCell() {
////        activityIndicator.startAnimating()
//        
//        // Populate cell imageview
//        if let data = photo.photoImage {
//            // Photo data already exists in photo object. But has not yet been converted to a UIImage
////            let image = UIImage(data: data)
////            photoImageView.image = image
////            activityIndicator.stopAnimating()
//        } else {
//            // No photo currently downloaded. Request image from flickr
////            activityIndicator.startAnimating()
//            
//            flickrClient.downloadImage(fromUrl: photo.url!) { [unowned self] (imageData, error) in
//                guard let imageData = imageData else { preconditionFailure("Unable to download image: \(error.debugDescription)") }
//                
//                self.photo.imageData = imageData.jpegData(compressionQuality: 1)
//                self.imageView.image = imageData
//                self.activityIndicator.stopAnimating()
//            }
//        }
//    }
    
}

extension UIColor {
    static func customColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }
}
