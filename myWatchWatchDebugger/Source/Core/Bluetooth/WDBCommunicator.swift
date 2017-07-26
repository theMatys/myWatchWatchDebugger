//
//  WDBCommunicator.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 04. 11..
//  Copyright © 2017. theMatys. All rights reserved.
//

import CoreBluetooth
import CoreData

/// A class for handling connections to myWatch Bluetooth devices.
///
/// The class you instantiate this class in, must conform to the protocol MWBCommunicatorDelegate.
///
/// The conforming class must implement the callback methods of the protocol.
class WDBCommunicator: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate
{
    //MARK: Instance variables
    
    /// The delegate of this class.
    ///
    /// Used to invoke callback methods in the delegate.
    ///
    /// - See: `WDBCommunicatorDelegate` for more details.
    var delegate: WDBCommunicatorDelegate!
    
    /// The device we are connected to.
    ///
    /// Nil on initialization if we are looking for any compatible devices to connect to.
    ///
    /// Not nil on initialization if we are looking for a specific device to connect to. In this case, we identify the specified device using the `deviceID` property in `MWDevice`.
    var device: WDDevice?
    
    /// The `CBCentralManager` object this class uses to handle central Bluetooth situations.
    private var centralManager: CBCentralManager?
    
    /// The peripheral representing the device we are connected to.
    private var peripheral: CBPeripheral!
    
    /// Holds the characteristic that we send the commands to.
    ///
    /// Given value when Bluetooth found a characteristic matching UUID `uartTxUUID`
    private var uartTxCharacteristic: CBCharacteristic?
    
    /// Holds the characteristic that we read responses to sent commands from.
    ///
    /// Given value when Bluetooth found a characteristic matching UUID `uartRxUUID`
    private var uartRxCharacteristic: CBCharacteristic?
    
    /// Queue of commands that are bound to be sent to the Bluetooth peripheral.
    ///
    /// When the first command from the queue is sent to the device, it gets popped from the array.
    ///
    /// - See: `MWBCommand` for more details on how a command is laid out.
    private var commandQueue: WDQueue<WDBCommand> = WDQueue()
    
    /// The UUID of the service which holds the Tx and Rx characteristics.
    private let uartSericeUUID: CBUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// The UUID of the Tx characteristic.
    private let uartTxUUID: CBUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// The UUID of the Rx characteristic.
    private let uartRxUUID: CBUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    //MARK: Static variables
    
    /// The (shared) singleton instance of the Bluetooth communicator.
    static let shared: WDBCommunicator = WDBCommunicator()
    
    //MARK: - Initializers
    
    /// Basic initializer that is meant to be called once by `myWatch` (the application's main class).
    ///
    /// Do not call this initializer unless you want an own `MWBCommunicator` object.
    ///
    /// If you want to use the app's Bluetooth communicator, use the `shared` singleton instance instead.
    override init()
    {
        super.init()
    }
    
    //MARK: Inherited functions from: CBCentralManagerDelegate
    internal func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        //Check the state
        //If powered on, handle.
        if(central.state == .poweredOn)
        {
            //Log information message
            WDLInfo("Bluetooth has been turned on.", module: .moduleBluetooth)
            
            device ??! {
                //If yes, we know we must look for the devices and connect to the specified one.
                self.lookForDevices()
            } >< {
                //If not, check whether the function we need to call now is implemented in the delegate - if yes, inform the delegate about the change
                self.delegate.bluetoothCommunicator(_:didUpdateBluetoothAvailability:) ??! {
                    self.delegate.bluetoothCommunicator!(self, didUpdateBluetoothAvailability: true)
                    } >< {
                        WDLInfo("WARNING: Bluetooth is available, but function \"bluetoothCommunicator(_:didUpdateBluetoothAvailability:)\" is not implemented in the current delegate.", module: .moduleBluetooth)
                }
            }
        }
        //If anything else, handle.
        else
        {
            //Log information message
            WDLInfo("Bluetooth is not available at the moment. The central manager's current state is: \"\(central.state.rawValue)\"", module: .moduleBluetooth)
            
            //Check whether the function we need to call now is implemented in the delegate - if yes, inform the delegate about the change
            self.delegate.bluetoothCommunicator(_:didUpdateBluetoothAvailability:) ??! {
                self.delegate.bluetoothCommunicator!(self, didUpdateBluetoothAvailability: false)
            } >< {
                WDLInfo("WARNING: Bluetooth is not available, but function \"bluetoothCommunicator(_:didUpdateBluetoothAvailability:)\" is not implemented in the current delegate.", module: .moduleBluetooth)
            }
        }
    }
    
    internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        //Check if we have found a compatible device
        if(peripheral.name == WDDefaults.Bluetooth.defaultDeviceName)
        {
            //Get the device ID
            let raw: Any? = advertisementData["kCBAdvDataManufacturerData"]
            
            raw ?! {
                let unparsed: String = String(describing: raw!)
                let parsed: String = parseDeviceID(unparsed)
                
                //From the parsed device ID, construct a device.
                let device: WDDevice = WDDevice(identifier: parsed, peripheral: peripheral)
                
                //Check if there was a device specified
                self.device ??! {
                    //If yes, check whether the two IDs match (specified and found)
                    if(self.device!.identifier == device.identifier)
                    {
                        //If yes, check whether the function we need to call now is implemented in the delegate - if yes, inform the delegate about the change, set the device as our current peripheral and connect to the device.
                        self.delegate.bluetoothCommunicator(_:didFindSpecifiedDevice:) ??! {
                            self.delegate.bluetoothCommunicator!(self, didFindSpecifiedDevice: self.device!)
                            self.device!.peripheral = peripheral
                            
                            self.attemptToConnect(to: self.device!)
                            } >< {
                                WDLInfo("WARNING: Found device matching the device ID of the MWDevice specified in the initializer, but function \"bluetoothCommunicator(_:didFindSpecifiedDevice:)\" is not implemented in the current delegate.", module: .moduleBluetooth)
                        }
                    }
                    } >< {
                        
                        self.delegate.bluetoothCommunicator(_:didFindCompatibleDevice:) ??! {
                            self.delegate.bluetoothCommunicator!(self, didFindCompatibleDevice: device)
                            } >< {
                                WDLInfo("WARNING: Found device matching the myWatch device requirements, but function \"bluetoothCommunicator(_:didFindCompatibleDevice:)\" is not implemented in the current delegate.", module: .moduleBluetooth)
                        }
                }
            }
        }
    }
    
    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {        
        //Log information message
        WDLInfo("Successfully connected to peripheral: \"\(peripheral.name!)\"", module: .moduleBluetooth)
        
        //Check whether the function we need to call now is implemented in the delegate - if yes, inform the delegate about the connection
        delegate.bluetoothCommunicator(_:didConnectToDevice:) ??! {
            self.delegate.bluetoothCommunicator!(self, didConnectToDevice: device!)
        } >< {
            WDLInfo("WARNING: Function \"bluetoothCommunicator(_:didConnectToDevice:)\" is not implemented in the current delegate.", module: .moduleBluetooth)
        }
        
        //Stop scanning for other devices and discover the peripherals
        self.centralManager!.stopScan()
        peripheral.discoverServices([uartSericeUUID])
    }
    
    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        //Log error message
        WDLError("Was unable to connect to peripheral: \"\(peripheral.name!)\", more details: \(error?.localizedDescription ?? "<no more details>")", module: .moduleBluetooth)
    }
    
    //MARK: Inherited functions from: CBPeripheralDelegate
    
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        //Check whether we have found working services with the applied UUID filter
        peripheral.services ??! {
            //If yes, iterate through and find the uart service
            for service in peripheral.services!
            {
                if(service.uuid == self.uartSericeUUID)
                {
                    //For the uart service, discover the characteristics
                    peripheral.discoverCharacteristics([self.uartTxUUID, self.uartRxUUID], for: service)
                }
            }
        } >< {
            //If not, log an error message
            WDLError("Was unable to discover the Uart service on the connected myWatch device, more details: \(error?.localizedDescription ?? "<no more details>")", module: .moduleBluetooth)

        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        //Check if the service is the uart service we need
        if(service.uuid == uartSericeUUID)
        {
            //Check if whether we have found working characteristics with the applied UUID filter
            service.characteristics ??! {
                //If yes, iterate through and find the Tx and Rx characteristics
                for characteristic in service.characteristics!
                {
                    if(characteristic.uuid == self.uartTxUUID)
                    {
                        //Store the Tx characteristic
                        self.uartTxCharacteristic = characteristic
                    }
                    else if(characteristic.uuid == self.uartRxUUID)
                    {
                        //Store the Rx characteristic and subsribe to its value so that we receive responses to our commands
                        self.uartRxCharacteristic = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    else
                    {
                        WDLError("Found useless characteristic with UUID: \(characteristic.uuid) on the connected myWatch device, ignoring it...", module: .moduleBluetooth)
                    }
                }
            } >< {
                //If not, log an error message
                WDLError("Was unable to discover characteristics on the connected myWatch device, more details: \(error?.localizedDescription ?? "<no more details>")", module: .moduleBluetooth)

            }
        }
        else
        {
            //If not, log an error message
            WDLError("Was unable to discover characteristics on the connected myWatch device, because the service is not the Uart service, more details: \(error?.localizedDescription ?? "<no more details>")", module: .moduleBluetooth)
        }
        
        //If both characteristics were discovered, inform the delegate that the device is ready to use
        uartTxCharacteristic ?! {
            self.uartRxCharacteristic ?! {
                self.delegate.bluetoothCommunicator(_:didFinishPreparationsForDevice:) ??! {
                    WDLInfo("The connected myWatch device is ready to use.", module: .moduleBluetooth)
                    self.delegate.bluetoothCommunicator!(self, didFinishPreparationsForDevice: self.device!)
                } >< {
                    WDLInfo("WARNING: Function \"deviceIsReadyToUse(_:)\" is not implemented in the current delegate.", module: .moduleBluetooth)
                }
            }
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        //Check if the characteristic we received the response from is the Rx characteristic
        if(characteristic.uuid == uartRxUUID)
        {
            //Then, check if there is a proper response value
            characteristic.value ??! {
                //If there is, log information message first
                WDLInfo("Data received from Uart Rx characteristic as a response to command: \(self.commandQueue.peek().command)", module: .moduleBluetooth)
                
                //Then, parse the response
                let response: WDBParsedData = WDBParsedData(unparsed: characteristic.value!)
                
                //And finally, inform the delegate about the response
                self.delegate.bluetoothCommunicator(_:didReceiveResponse:from:for:) ??! {
                    self.delegate.bluetoothCommunicator!(self, didReceiveResponse: response, from: self.device!, for: self.commandQueue.peek().command)
                } >< {
                    WDLInfo("WARNING: Function \"bluetoothCommunicator(_:didReceiveResponse:from:for:)\" is not implemented in the current delegate.", module: .moduleBluetooth)
                }
                
            } >< {
                //If there is no response value, log an error message
                WDLError("Received nil from Uart Rx characeteristic as a response to command: \(self.commandQueue.peek().command)", module: .moduleBluetooth)
            }
        }
        
        //Check whether there's only one command left in the queue
        if(commandQueue.count == 1)
        {
            //If yes, we do not remove it, because we may get more responses from this single command
            //Instead, we set the command to already executed, so whenever we queue another command, it will be removed from the queue immediately.
            commandQueue.peek().executed = true
        }
        else if(commandQueue.count > 1)
        {
            //If no, we remove the command from the queue
            commandQueue.pop()
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        //Check whether the characteristic the value was written to is our Tx characteristic.
        if(characteristic == uartTxCharacteristic && commandQueue.count >= 1)
        {
            //Remove the command which remained as the last command in queue after it has been executed
            if(commandQueue.count > 1 && commandQueue.peek().executed)
            {
                commandQueue.pop()
            }
            
            //Log information message
            WDLInfo("Successfully delivered command: \(commandQueue.peek().command) to the connected myWatch device.", module: .moduleBluetooth)
            
            //If the last command will not produce a response, remove it from the queue
            if(commandQueue.peek().nonResponse)
            {
                commandQueue.pop()
            }
        }
    }
    
    //MARK: Instance functions
    
    /// Used to initialize the Bluetooth with the delegate specified in `delegate`.
    ///
    /// This delegate is used to invoke callback functions defined in protocol `MWBCommunicatorDelegate`.
    ///
    /// Bluetooth function implementations in this class are designed to handle two scenarios:
    /// - Where we look for any compatible devices and connect to the one that the user picks.
    /// - Where we want to connect to the device specified in `device`.
    ///
    /// This function is used for the first scenario.
    ///
    /// - Parameter delegate: The delegate that this class will be using throughout the Bluetooth session.
    func initializeBluetooth(with delegate: WDBCommunicatorDelegate)
    {
        self.delegate = delegate
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    /// Used to initialize the Bluetooth with the delegate and device specified in the parameters.
    ///
    /// This delegate is used to invoke callback functions defined in protocol `MWBCommunicatorDelegate`.
    ///
    /// Bluetooth function implementations in this class are designed to handle two scenarios:
    /// - Where we look for any compatible devices and connect to the one that the user picks.
    /// - Where we want to connect to the device specified in `device`.
    ///
    /// This function is used for the second scenario.
    ///
    /// - Parameters:
    ///   - delegate: The delegate that this class will be using throughout the Bluetooth session.
    ///   - device: The device we look for and connect to (if we have found it).
    func initializeBluetooth(with delegate: WDBCommunicatorDelegate, device: WDDevice)
    {
        self.delegate = delegate
        self.device = device
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    /// Used to start the peripheral-scanning process.
    ///
    /// __This function must only be called after__ `centralManager` __reported that it is powered on.__
    func lookForDevices()
    {
        centralManager!.scanForPeripherals(withServices: nil, options: nil)
    }
    
    /// Used to attempt the connection to the device specified in `device`.
    ///
    /// - Parameter device: The device to connect to.
    func attemptToConnect(to device: WDDevice)
    {
        //Set the device as our current device
        self.device = device
        self.peripheral = device.peripheral
        
        //Set the peripheral's delegate to this class, so we can handle later events
        peripheral!.delegate = self
        
        //Connect to the peripheral
        centralManager!.connect(peripheral!, options: nil)
    }
    
    /// Used to send commands to the peripheral we are currently connected to.
    ///
    /// __This function must only be called after we found the Tx and Rx characteristics on the peripheral.__
    ///
    /// - Parameter command: The command which will be added to the queue and sent to the device.
    func sendCommand(_ command: WDBCommand)
    {
        //Check if the Tx characteristic was discovered
        uartTxCharacteristic ?! {
            //If yes, add the specified command to the command queue
            self.commandQueue.push(command)
            
            //Send the command's data to the peripheral
            self.peripheral!.writeValue(command.commandData, for: self.uartTxCharacteristic!, type: .withResponse)
        }
    }
    
    /// Used to completely reset Bluetooth and disconnect from the current device.
    func deinitializeBluetooth()
    {
        //Unsubscribe and disconnect
        peripheral!.setNotifyValue(false, for: uartRxCharacteristic!)
        centralManager!.cancelPeripheralConnection(peripheral!)
        
        //Reset variables
        centralManager = nil
        peripheral = nil
        device = nil
        uartTxCharacteristic = nil
        commandQueue = WDQueue()
        
        //Log information message
        WDLInfo("Bluetooth has been deinitialized.", module: .moduleBluetooth)
    }
    
    /// Used to parse the device ID gathered from the peripheral's advertisement data.
    ///
    /// - Parameter unparsed: The raw advertisement data.
    /// - Returns: A parsed device ID in `String` format.
    private func parseDeviceID(_ unparsed: String) -> String
    {
        //The raw unparsed data looks something like this:
        //
        //  <00019876 543210eb>   (The device ID in this raw string is reversed in groups of two - note: "EB" instead of "BE", same with the numbers.)
        
        //The very first "1" indicates that the ID is about to begin.
        //This variable is set to true when we read that first "1"
        var reachedIDStart: Bool = false
        
        //The variable which contains one character that we have just read from the raw ID
        var buffer: String = ""
        
        //The final (parsed) device ID
        var parsed: String = ""
        
        //Iterate through each character of the advertisement data.
        for character in unparsed.characters
        {
            //If we reached the "1" indicating that the ID is about to begin, set "reachedIDStart" to true
            if(character == "1" && !reachedIDStart)
            {
                reachedIDStart = true
                continue //Skip the rest of the loop
            }
            
            //The characters we do not need are: " ", "<" and ">"
            //If the read character is neither of these, proceed
            if((character != "<" && character != ">" && character != " ") && reachedIDStart)
            {
                //Because the ID is reversed in groups of two, we need to store each group in a buffer
                if(buffer.characters.count == 0)
                {
                    //If there is nothing in the buffer, create one which contains the first character
                    buffer = String(character)
                }
                else if(buffer.characters.count == 1)
                {
                    //If there is already one character in the buffer, append the current one, then add the whole buffer to the ID
                    buffer.append(character)
                    
                    parsed = buffer + parsed
                    
                    buffer = ""
                }
            }
        }
        
        //At the end of the function, return the parsed device ID with uppercased letters
        return parsed.uppercased()
    }
}

//MARK: -

/// Represents the commands sent to the peripheral.
class WDBCommand
{
    //MARK: Instance variables
    
    /// The command's raw value.
    var command: String
    
    /// The command's data (only this can be sent to the peripheral).
    var commandData: Data
    
    /// Specifes whether the command generates a response from the peripheral.
    ///
    /// - `true` for commands that do not generate response.
    ///
    /// - `false` for commands that generate response.
    var nonResponse: Bool
    
    
    /// Indicates whether the command has already been executed.
    ///
    /// - `true` for commands that have already been executed.
    ///
    /// - `false` for commands that have not yet been executed.
    var executed: Bool = false
    
    //MARK: - Initializers
    
    /// Makes an `MWBCommand` instance out of the given parameters.
    ///
    /// - Parameters:
    ///   - command: The raw value of the command.
    ///   - nonResponse: Optional - false by default. Specifies whether the command generates a response.
    init(command: String, nonResponse: Bool = false)
    {
        self.command = command
        self.nonResponse = nonResponse
        
        self.commandData = command.data(using: .utf8)!
    }
}

//MARK: -

/// Holds two versions of parsed data: a string and a numeric version.
///
/// The receiver of this object can decide which to use.
@objc class WDBParsedData: NSObject
{
    //MARK: Instance variables
    
    /// A parsed string representation of the data.
    var dataString: String!
    
    /// A parsed numeric (integer) representation of the data.
    var dataNumeric: Int!
    
    //MARK: - Initializers
    
    /// Makes an `MWBParsedData` instance out of the given parameters.
    ///
    /// - Parameter data: The raw data that is going to get parsed.
    init(unparsed data: Data)
    {
        //Supercall
        super.init()
        
        //Parse the data as "String" and as "Int"
        self.dataString = String(data: data, encoding: .utf8) ?? "nil"
        self.dataNumeric = Int(exactly: UInt64(bigEndian: data.withUnsafeBytes { $0.pointee })) ?? -1
    }
}
