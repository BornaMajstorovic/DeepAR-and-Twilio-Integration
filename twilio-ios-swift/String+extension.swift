//
//  String+extension.swift
//  twilio-ios-swift
//
//  Created by Borna on 23/07/2020.
//  Copyright © 2020 hr.fer.majstorovic.borna. All rights reserved.
//

import Foundation
extension String {
    var path: String? {
        return Bundle.main.path(forResource: self, ofType: nil)
    }
}
