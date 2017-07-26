//
//  WDBCommunicatorDelegate.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 04. 12..
//  Copyright © 2017. theMatys. All rights reserved.
//

import CoreBluetooth

/// Protocol for classes which want Bluetooth functionality.
///
/// When conformed, the class has to handle the callback functions declared below.
@objc protocol WDBCommunicatorDelegate
{
    //MARK: Protocol functions

    /// Called by an `MWBCommunicator` when the Bluetooth became either available or unavailable.
    ///
    /// - Parameters:
    ///   - communicator: The communicator providing the update.
    ///   - availability: A boolean indicating the Bluetooth availablility.
    @objc optional func bluetoothCommunicator(_ communicator: WDBCommunicator, didUpdateBluetoothAvailability availability: Bool)
    
    /// Called by an `MWBCommunicator` when the Bluetooth has found an available peripheral which is compatible with the application.
    ///
    /// - Parameters:
    ///   - communicator: The communicator providing the update.
    ///   - device: The device which `communicator` has found.
    @objc optional func bluetoothCommunicator(_ communicator: WDBCommunicator, didFindCompatibleDevice device: WDDevice)
    
    /// Called by an `MWBCommunicator` when the Bluetooth has found the device which `communicator` was specified to connect to.
    ///
    /// - Parameters:
    ///   - communicator: The communicator providing the update.
    ///   - device: The device `communicator` was specified to connect to.
    @objc optional func bluetoothCommunicator(_ communicator: WDBCommunicator, didFindSpecifiedDevice device: WDDevice)
    
    /// Called by an `MWBCommunicator` when the Bluetooth has connected to a device specified explicitly.
    ///
    /// - Parameters:
    ///   - communicator: The communicator providing the update.
    ///   - device: The device `communicator` connected to.
    @objc optional func bluetoothCommunicator(_ communicator: WDBCommunicator, didConnectToDevice device: WDDevice)
    
    /// Called by an `MWBCommunicator` when the Bluetooth has finished preparing the connected device, indicating that the device is ready to use.
    ///
    /// - Parameters:
    ///   - communicator: The communicator providing the update.
    ///   - device: The device which has just become ready to use.
    @objc optional func bluetoothCommunicator(_ communicator: WDBCommunicator, didFinishPreparationsForDevice device: WDDevice)
    
    /// Called by an `MWBCommunicator` when the Bluetooth received a package in response to a previously sent command.
    ///
    /// - Parameters:
    ///   - communicator: The communicator providing the update.
    ///   - response: The parsed response received from the device.
    ///   - device: The device providing the response.
    ///   - command: The command the response is for.
    @objc optional func bluetoothCommunicator(_ communicator: WDBCommunicator, didReceiveResponse response: WDBParsedData, from device: WDDevice, for command: String)
}
