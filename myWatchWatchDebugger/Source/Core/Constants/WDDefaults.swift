//
//  WDDefaults.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 05. 09..
//  Copyright © 2017. theMatys. All rights reserved.
//

import Cocoa

/// Holds all the defaults that the application uses.
struct WDDefaults
{
    /// Bluetooth-related defaults.
    struct Bluetooth
    {
        static let defaultDeviceName = "E-Band"
    }
    
    //MARK: -
    
    /// Default gradients.
    struct Gradients
    {
        static let defaultGradient: WDGradient = WDGradient(colors: NSColor.black, NSColor.darkGray)
    }
}
