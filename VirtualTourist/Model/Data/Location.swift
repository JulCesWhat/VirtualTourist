//
//  Location.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/14/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import Foundation

// MARK: - Photo
struct Location: Codable {
    let latitude, longitude: Double
    let title, subtitle: String
    
    enum CodingKeys: String, CodingKey {
        case title, subtitle, latitude, longitude
    }
}
