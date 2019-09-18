//
//  LocationD+Extensions.swift
//  VirtualTourist
//
//  Created by Julio Cesar Whatley on 9/14/19.
//  Copyright © 2019 Capi. All rights reserved.
//

import Foundation
import CoreData

extension LocationD {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
