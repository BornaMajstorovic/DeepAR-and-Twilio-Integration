//
//  Mode.swift
//  twilio-ios-swift
//
//  Created by Borna on 23/07/2020.
//  Copyright © 2020 hr.fer.majstorovic.borna. All rights reserved.
//


import Foundation

enum Mode: String {
    case masks
    case effects
    case filters
}

enum Masks: String, CaseIterable {
    case none
    case aviators
    case bigmouth
    case dalmatian
    case fatify
    case flowers
    case grumpycat
    case kanye
    case koala
    case lion
    case mudMask
    case obama
    case pug
    case slash
    case sleepingmask
    case smallface
    case teddycigar
    case tripleface
    case twistedFace
}

enum Effects: String, CaseIterable {
    case none
    case fire
    case heart
    case blizzard
    case rain
}

enum Filters: String, CaseIterable {
    case none
    case tv80
    case drawingmanga
    case sepia
    case bleachbypass
    case realvhs
    case filmcolorperfection
}


