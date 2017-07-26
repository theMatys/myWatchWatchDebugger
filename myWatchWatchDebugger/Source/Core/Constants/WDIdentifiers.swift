//
//  WDIdentifiers.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 07. 25..
//  Copyright © 2017. theMatys. All rights reserved.
//

import Foundation

//MARK: Prefixes

/// The prefix used for all segue identifiers.
fileprivate let prefixSegue: String = "WDSegue"

/// Holds all the identifiers in the application that are used programatically.
struct WDIdentifiers
{
    //MARK: -
    
    /// The segue identifiers used programatically in the application.
    struct SegueIdentifiers
    {
        static let watchChooserToCommandDebugger: String = prefixSegue + "WatchChooserToCommandDebugger"
    }
}
