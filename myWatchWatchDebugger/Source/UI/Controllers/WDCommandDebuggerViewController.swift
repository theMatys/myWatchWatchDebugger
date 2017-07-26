//
//  WDCommandDebuggerViewController.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 07. 22..
//  Copyright © 2017. theMatys. All rights reserved.
//

import Cocoa

class WDCommandDebuggerViewController: NSViewController
{
    //MARK: Outlets
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!
    @IBOutlet weak var textFieldCommand: NSTextField!
    @IBOutlet weak var buttonSend: NSButton!
    @IBOutlet var textViewResponseLog: NSTextView!
    
    //MARK: Instance variables
    var device: WDDevice!
    
    //MARK: - Inherited functions from: NSViewController
    override func viewDidLoad()
    {
        //Supercall
        super.viewDidLoad()
        
        //Append the device's ID to the title
        labelTitle.cell?.title.append(device.identifier)
    }
}

