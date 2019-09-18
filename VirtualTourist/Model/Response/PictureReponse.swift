//
//  PictureReponse.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/13/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import Foundation

// MARK: - PictureReponse
struct PictureReponse: Codable {
    let photos: Photos
    let stat: String
}

// MARK: - Photos
struct Photos: Codable {
    let page, pages, perpage: Int
    let total: String
    let photo: [Photo]
}
