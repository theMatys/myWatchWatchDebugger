//
//  WatchDebugger.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 07. 22.
//  Copyright © 2017. theMatys. All rights reserved.
//

import Cocoa

class WatchDebugger
{
    //MARK: Static variables
    static var shared: WatchDebugger = WatchDebugger()

    //MARK: - Initializers
    private init() {}
}

@NSApplicationMain
class WDApplicationDelegate: NSObject, NSApplicationDelegate
{
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }
}

