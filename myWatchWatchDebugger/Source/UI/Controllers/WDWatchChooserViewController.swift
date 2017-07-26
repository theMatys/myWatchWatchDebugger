//
//  WDWatchChooserViewController.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 07. 22..
//  Copyright © 2017. theMatys. All rights reserved.
//

import Cocoa

class WDWatchChooserViewController: NSViewController, WDBCommunicatorDelegate
{
    //MARK: Outlets
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!
    @IBOutlet weak var stackViewWatchChooser: WDWatchChooserStackView!
    @IBOutlet weak var labelBluetoothIndicator: NSTextField!
    
    //MARK: Instance variables
    private let communicator: WDBCommunicator = WDBCommunicator.shared
    private var selectedDevice: WDDevice?
    
    //MARK: - Inherited functions from: NSViewController
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewDidAppear()
    {
        //Supercall
        super.viewDidAppear()
        
        //Initialize the Bluetooth
        communicator.initializeBluetooth(with: self)
    }
    
    func bluetoothCommunicator(_ communicator: WDBCommunicator, didUpdateBluetoothAvailability availability: Bool)
    {
        if(availability)
        {
            labelBluetoothIndicator.cell?.title = "Bluetooth: ON"
            labelBluetoothIndicator.textColor = NSColor.green
            
            communicator.lookForDevices()
        }
        else
        {
            labelBluetoothIndicator.cell?.title = "Bluetooth: OFF"
            labelBluetoothIndicator.textColor = NSColor.red
        }
    }
    
    func bluetoothCommunicator(_ communicator: WDBCommunicator, didFindCompatibleDevice device: WDDevice)
    {
        stackViewWatchChooser.addDevice(device)
    }
    
    func bluetoothCommunicator(_ communicator: WDBCommunicator, didConnectToDevice device: WDDevice)
    {
        //No-operations
    }
    
    func bluetoothCommunicator(_ communicator: WDBCommunicator, didFinishPreparationsForDevice device: WDDevice)
    {
        selectedDevice = device
        self.performSegue(withIdentifier: WDIdentifiers.SegueIdentifiers.watchChooserToCommandDebugger, sender: self)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if(identifier == WDIdentifiers.SegueIdentifiers.watchChooserToCommandDebugger)
        {
            return selectedDevice != nil
        }
        
        return true
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?)
    {
        if(segue.identifier == WDIdentifiers.SegueIdentifiers.watchChooserToCommandDebugger)
        {
            guard let destination = segue.destinationController as? WDCommandDebuggerViewController else
            {
                fatalError("The destination view controller in segue \"\(segue.identifier!)\" must be an instance of \"\(WDCommandDebuggerViewController.self)\"")
            }
            
            destination.device = selectedDevice!
        }
    }
}

//MARK: -
class WDWatchChooserStackView: NSStackView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    func addDevice(_ device: WDDevice)
    {
        let view: WDWatchChooserDeviceView = WDWatchChooserDeviceView(frame: NSRect.zero, device: device)
        view.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0)
        view.heightAnchor.constraint(equalToConstant: 35.0).isActive = true
        
        view.layout()
        
        self.addArrangedSubview(view)
    }
}

class WDWatchChooserDeviceView: NSView
{
    private var communicator: WDBCommunicator = WDBCommunicator.shared
    
    private var device: WDDevice!
    
    private var imageView: WDImageView!
    private var label: NSTextField!
    private var button: NSButton!
    
    init(frame frameRect: NSRect, device: WDDevice)
    {
        super.init(frame: frameRect)
        
        //Store the device
        self.device = device
        
        //Prepare the backround
        self.wantsLayer = true
        
        self.layer?.backgroundColor = NSColor.windowBackgroundColor.substracting(0.1).cgColor
        self.layer?.cornerRadius = 5.0
        
        //Create the image view
        imageView = WDImageView()
        
        imageView.silently().tintingColor = NSColor.black
        imageView.image = Bundle.main.image(forResource: "WDAssetGeneralWatch")
        
        let aspectRatio: CGFloat = imageView.image!.size.width / imageView.image!.size.height
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspectRatio).isActive = true
        
        let imageViewX: NSLayoutConstraint = imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12.0)
        let imageViewY: NSLayoutConstraint = imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        
        self.addSubview(imageView)
        self.addConstraints([imageViewX, imageViewY])
        
        //Create the label with the device ID
        label = NSTextField()
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        
        label.font = NSFont.systemFont(ofSize: 14.0)
        label.cell?.title = "Device: " + device.identifier
        label.sizeToFit()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let labelX: NSLayoutConstraint = label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8.0)
        let labelY: NSLayoutConstraint = label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        
        self.addSubview(label)
        self.addConstraints([labelX, labelY])
        
        //Create the button
        button = NSButton(title: "Connect", target: self, action: #selector(connect(_:)))
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonX: NSLayoutConstraint = button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12.0)
        let buttonY: NSLayoutConstraint = button.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        
        self.addSubview(button)
        self.addConstraints([buttonX, buttonY])
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        
        WDLError("A \"WDWatchChooserDeviceView\" object was attempted to be created using initializer \"\(#function)\". This initializer was not meant to be used. Creating an empty view...")
        self.frame = CGRect.zero
    }
    
    @objc private func connect(_ sender: NSButton)
    {
        let progressIndicator: NSProgressIndicator = NSProgressIndicator()
        progressIndicator.style = .spinningStyle
        progressIndicator.isIndeterminate = true
        
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.widthAnchor.constraint(equalToConstant: 20.0).isActive = true
        progressIndicator.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        
        let progressIndicatorX: NSLayoutConstraint = progressIndicator.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12.0)
        let progressIndicatorY: NSLayoutConstraint = progressIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        
        sender.removeFromSuperview()
        
        self.addSubview(progressIndicator)
        self.addConstraints([progressIndicatorX, progressIndicatorY])
        communicator.attemptToConnect(to: device)
        
        progressIndicator.startAnimation(self)
    }
}
