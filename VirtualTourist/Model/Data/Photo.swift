//
//  Photo.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/13/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Photo
struct Photo: Codable {
    var photoImage: UIImage?
    let id, owner, secret, server: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
    let urlM: String
//    let heightM, widthM: String
    
    enum CodingKeys: String, CodingKey {
        case id, owner, secret, server, farm, title, ispublic, isfriend, isfamily
        case urlM = "url_m"
//        case heightM = "height_m"
//        case widthM = "width_m"
    }
}
