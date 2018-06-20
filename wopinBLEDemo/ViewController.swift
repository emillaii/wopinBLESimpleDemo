//
//  ViewController.swift
//  wopinBLEDemo
//
//  Created by Lai kwok tai on 19/6/2018.
//  Copyright © 2018 Lai kwok tai. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BLEManagerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var deviceTableView: UITableView!
    @IBOutlet weak var connectionStateLabel: UILabel!
    
    @IBOutlet weak var hydroMinutes: UITextField!
    @IBOutlet weak var hydroSeconds: UITextField!
    @IBOutlet weak var redTextField: UITextField!
    @IBOutlet weak var greenTextField: UITextField!
    @IBOutlet weak var blueTextField: UITextField!
    
    var discoveredDeviceMap = [String : String]()  // UUID : Device Name
    var discoveredDeviceList = [""]
    var bleManager : BLEManager?
    var connectedDevice : CBPeripheral?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDeviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        let selectedUUID = discoveredDeviceList[indexPath.row]
        let deviceName = discoveredDeviceMap[selectedUUID]
        cell.textLabel?.text = deviceName
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        hydroMinutes.delegate = self
        hydroSeconds.delegate = self
        redTextField.delegate = self
        greenTextField.delegate = self
        blueTextField.delegate = self
        if (bleManager == nil)
        {
            print("Initializing BLE Manager")
            bleManager = BLEManager.default()
            bleManager?.delegate = self
            perform(#selector(scanDevice), with: nil, afterDelay: 5)
        }
        print("Initializing BLE Manager Done")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func scanDevice() {
        if (connectedDevice == nil)
        {
            print("scanning device....")
            self.bleManager?.scanDeviceTime(5)
        }
        perform(#selector(scanDevice), with: nil, afterDelay: 10)
    }
    
//Button Control
    func sendCommandToConnectedDevice(_ command: String)
    {
        if (bleManager != nil && connectedDevice != nil) {
            bleManager?.sendData(toDevice1: command, device: connectedDevice)
        }
    }
    
    @IBAction func ledTurnOn(_ sender: Any) {
       sendCommandToConnectedDevice(WopinCommand.COLOR_LED_ON)
    }
    
    @IBAction func ledTurnOff(_ sender: Any) {
        sendCommandToConnectedDevice(WopinCommand.COLOR_LED_OFF)
    }

    @IBAction func hydroOn(_ sender: Any) {
        sendCommandToConnectedDevice(WopinCommand.HYDRO_GEN_ON)
    }
    
    @IBAction func hydroOff(_ sender: Any) {
        sendCommandToConnectedDevice(WopinCommand.HYDRO_GEN_OFF)
    }
    
    @IBAction func CleanON(_ sender: Any) {
        sendCommandToConnectedDevice(WopinCommand.CLEAN_ON)
    }
    
    @IBAction func CleanOFF(_ sender: Any) {
        sendCommandToConnectedDevice(WopinCommand.CLEAN_OFF)
    }
    
    @IBAction func hydroOnTimer(_ sender: Any) {
        let min = Int(hydroMinutes.text!)
        let sec = Int(hydroSeconds.text!)
        let minuteStr = String(format:"%02X", min!)
        let secondStr = String(format:"%02X", sec!)
        let command = "AABBCC02" + minuteStr + secondStr + "BBCC"
        sendCommandToConnectedDevice(command)
    }
    
    @IBAction func rgbLEDSet(_ sender: Any) {
        let r = Int(redTextField.text!)
        let g = Int(greenTextField.text!)
        let b = Int(blueTextField.text!)
        let command = wopinLEDCommand(r: r!, g: g!, b: b!)
        sendCommandToConnectedDevice(command)
    }
    
    //Table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        if (indexPath.row > 0)
        {
            let uuid = self.discoveredDeviceList[indexPath.row ]
            print("Selected \(self.discoveredDeviceMap[uuid]!)")
            var peripheral : CBPeripheral?
            peripheral = self.bleManager?.getDeviceByUUID(uuid)
            self.bleManager?.connect(toDevice: peripheral)
        }
    }
    
//pragma mark - BLeManager Delegate
    func centerManagerStateChange(_ state: CBManagerState) {
        print("centerManagerStateChange \(state.rawValue)")
    }
    
    func scanDeviceRefrash(_ array: NSMutableArray!) {
        for info in (array as NSMutableArray as! [DeviceInfo]) {
            if (!discoveredDeviceList.contains(info.uuidString))
            {
                discoveredDeviceList.append(info.uuidString)
                discoveredDeviceMap[info.uuidString] = info.localName
                print(info.uuidString)
                deviceTableView.reloadData()
            }
        }
    }
    
    func connectDeviceSuccess(_ device: CBPeripheral!, error: Error!) {
        if (error != nil)
        {
            print(error.localizedDescription)
        } else {
            print("Device connected ! \(device.name ?? "")")
            connectionStateLabel.text = "Connected"
            connectedDevice = device
        }
    }
    
    func didDisconnectDevice(_ device: CBPeripheral!, error: Error!) {
        if (error != nil)
        {
            print(error.localizedDescription)
        } else {
            print("Device disconnected normally! \(device.name ?? "")")
        }
        connectionStateLabel.text = "Disconnected"
        connectedDevice = nil
    }

    //Some data will be received here....Let process that later...
    func receiveDeviceDataSuccess_1(_ data: Data!, device: CBPeripheral!) {
        let bytes = [UInt8] (data as Data)
        var hexString = ""
        for byte in bytes {
            hexString = hexString.appendingFormat("%02X", UInt(byte))
        }
        print("Received some data: \(hexString)")
    }
    
}

