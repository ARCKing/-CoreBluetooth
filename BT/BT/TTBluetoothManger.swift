//
//  TTBluetoothManger.swift
//  BT
//
//  Created by macos on 2019/4/16.
//  Copyright © 2019 cqc. All rights reserved.
//

import UIKit
import CoreBluetooth


class PeripheralInfo {
    var serviceUUID: CBUUID?
    var characteristics: [CBCharacteristic]?
}

class TTBluetoothManger:NSObject {

    static var share =  TTBluetoothManger()
    private override init(){}
    
    lazy var centralManager:CBCentralManager = {
        let c =  CBCentralManager.init()
        c.delegate = self
        return c
    }()
    
    var currentPeripheral:CBPeripheral?
    var currentCharacteristic_01_01:CBCharacteristic?
    var currentCharacteristic_02_01:CBCharacteristic?

    ///设备名
    let Cperipheral_name = "DMK28  "
    
    ///服务UUID
    let Cserve_01_uuid = "3868"
    let Cserve_02_uuid = "2687"
    
    ///特征UUID
    let  Ccharacteristic_01_01_uuid = "3378"
    let  Ccharacteristic_02_01_uuid = "2967"

}

extension TTBluetoothManger{

    ///启用蓝牙,搜索链接设备
    ///在控制器中调用即可进行整个流程
    func bluetoohStar() {
        self.centralManager.delegate = self
    }
    
    func printShow(str:String) {
        
        print("=====================================")
        print("|             \(str)                |")
        print("-------------------------------------")
    }
    
    ///App向设备写入数据时调用次方法
    func deviceStartWriteValue(_ characteristic: CBCharacteristic) {
        
        ///这是我自己设备的写入数据
        let data = Data.init(bytes:[
            0x01,0xfe,0x00,0x00,
            0x23,0x33,0x10,0x00,
            0x64,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00])
        currentPeripheral!.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
}

extension TTBluetoothManger:CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .unknown:
            print("CBCentralManager state:", "unknown")
        case .resetting:
            print("CBCentralManager state:", "resetting")
        case .unsupported:
            print("CBCentralManager state:", "unsupported")
        case .unauthorized:
            print("CBCentralManager state:", "unauthorized")
        case .poweredOn:
            print("CBCentralManager state:", "poweredOn")
            ///扫描设备
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber.init(value: false)])
            
        case .poweredOff:
            print("CBCentralManager state:", "poweredOff")
        default:
            print("未知错误")
        }
    }
    
    ///发现设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("---------------------START---------------------")
        print("peripheral.name = \(peripheral.name ?? "搜索失败!")")
        if peripheral.name != nil{
            guard peripheral.name == "DMK28  " else{return}
            print("peripheral.name = \(peripheral.name!)")
            print("central = \(central)")
            print("peripheral = \(peripheral)")
            print("RSSI = \(RSSI)")
            print("advertisementData = \(advertisementData)")
            self.currentPeripheral = peripheral
            
            ///连接设备
            if let _ = self.currentPeripheral{
                central.stopScan()
                central.connect(self.currentPeripheral!, options: nil)
            }
            
        }
    }
    
    ///连接设备成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        printShow(str: "连接成功")
        self.currentPeripheral = peripheral
        peripheral.delegate = self
        //开始寻找Services。传入nil是寻找所有Services
        peripheral.discoverServices(nil)
    }
    
    ///连接设备失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    
        printShow(str: "连接失败:\(error.debugDescription)")
    }

    ///断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        printShow(str: "断开连接")
        
        ///可重新扫描
    }
    
    
}

extension TTBluetoothManger:CBPeripheralDelegate{
    
    ///寻找服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        printShow(str: "搜索服务")
        if error != nil{  print("服务异常:",error.debugDescription);return}
        guard let pservices = peripheral.services else {return}
        for ser in pservices {
            print("[服务的UUID] \(ser.uuid)")
            //在感兴趣的服务中寻找感兴趣的特征
            if ser.uuid.uuidString == Cserve_01_uuid || ser.uuid.uuidString == Cserve_02_uuid{
                self.currentPeripheral?.discoverCharacteristics(nil, for: ser)
            }
            
        }
    }

    /// 从感兴趣的服务中，确认 我们所发现感兴趣的特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        printShow(str: "确认特征")

        if error != nil{  print("特征异常:",error.debugDescription);return}
        guard let serviceCharacters = service.characteristics else {return}
        for characteristic in serviceCharacters {
            let characteristic_uuid = characteristic.uuid
            print("<特征UUID>",characteristic_uuid)

            // 订阅关于感兴趣特征的持续通知；
            // “当你启用特征值的通知时，外围设备调用……
            if characteristic_uuid.uuidString == Ccharacteristic_01_01_uuid{
                self.currentCharacteristic_01_01 = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic_uuid.uuidString == Ccharacteristic_02_01_uuid{
                self.currentCharacteristic_02_01 = characteristic
                peripheral.readValue(for: characteristic)

            }
        }
    }
    
    //MARK: - 检测向外设写数据是否成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            printShow(str: "写数据失败!!!")
        }else{printShow(str: "🌺写入数据成功🌺")}
        
    }
    
    // 接收外设发来的数据 每当一个特征值定期更新或者发布一次时，我们都会收到通知；
    // 阅读并解译我们订阅的特征值
    // MARK: - 获取外设发来的数据
    // 注意，所有的，不管是 read , notify 的特征的值都是在这里读取
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        printShow(str: "接收数据")
        if (characteristic.value != nil) {
            let data = characteristic.value
            
            let mod = Model()
            mod.read_analyzeData(fromData: data!)
        }
    }
    
    //接收characteristic信息    //MARK: - 特征的订阅状体发生变化
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("========特征的订阅状体变化========")
        printShow(str: characteristic.uuid.uuidString)
        
    }
    
}


class Model: NSObject {
    
    var waterArr = [Double]()
    var oilArr = [Double]()
    var lastwaterArr = [Double]()
    var lastoilArr = [Double]()
    
    var min:UInt8 = 0
    var sec:UInt8 = 0
    var waterValue:UInt8 = 0
    var oilValue:UInt8 = 0
    var countdownFlag:UInt8 = 0
    var workStatus:UInt8 = 0
    var surplus:UInt8 = 0
    var timeString:String = "00:00"
    var isPush = false
    
    var waterValue_100: Int = 0
    var oilValue_100:Int = 0
    
    func read_analyzeData(fromData data:Data) -> Void {
        
        let byteArr = data.bytes
        print(byteArr);
        if byteArr.count > 0{
            let hour = byteArr[7];
            let min = byteArr[8];
            let sec = byteArr[9];
            
            let waterValue = byteArr[10];
            let oilValue = byteArr[11];
            
            let countdownFlag = byteArr[12];
            let workStatus = byteArr[13];
            ///剩余使用次数
            let surplus = byteArr[14];
            
            
            print("[","时 = ",hour);
            print("分 = ",min);
            print("秒 = ",sec);
            print("水分 = ",waterValue);
            print("油分 = ",oilValue);
            print("倒计时标志 = ",countdownFlag);
            print("工作状态 = ",workStatus);
            print("剩余次数 = ",surplus,"]");
            
            var minString = "\(min)"
            var secString = "\(sec)"
            
            if min < 10 {
                minString = "0" + minString;
            }
            
            if sec < 10 {
                secString = "0" + secString;
            }
            
            let timeString = minString + ":" + secString;
            
            self.min = min;
            self.sec = sec;
            self.waterValue = waterValue;
            self.oilValue = oilValue;
            self.countdownFlag = countdownFlag;
            self.workStatus = workStatus;
            self.surplus = surplus;
            self.timeString = timeString;
            
            
            let temp_water = Int(waterValue)
            self.waterValue_100 = temp_water
            
            let temp_oil = Int(oilValue)
            self.oilValue_100 = temp_oil;
        }
    }
}










extension Data {
    /// Data -> Array, Dictionary
    ///
    /// - Returns: Array
    func toArray() -> [Any]? {
        
        return toArrayOrDictionary() as? [Any]
    }
    
    /// Data -> Array, Dictionary
    ///
    /// - Returns: Array
    func toDictionary() -> [String:Any]? {
        
        return toArrayOrDictionary() as? [String:Any]
    }
    
    /// Data -> Array, Dictionary
    ///
    /// - Returns: Any
    fileprivate func toArrayOrDictionary() -> Any? {
        
        do {
            
            let data = try JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions.allowFragments)
            
            return data
        } catch let _ {
            return nil
        }
    }
    
    public var bytes: Array<UInt8> {
        return Array(self)
    }
}

extension String {
    
    //16进制的转换
    //16进制类型的字符串[A-F,0-9]和Data之间的转换可以使用下面的方法。如果是包含=之类的可以直接用字符串转换Data即可

    ///16进制字符串转Data
    func hexData() -> Data? {
        var data = Data(capacity: count / 2)
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        guard data.count > 0 else { return nil }
        return data
    }
    
    func utf8Data()-> Data? {
        return self.data(using: .utf8)
    }
    
}

extension Data {
    ///Data转16进制字符串
    func hexString() -> String {
        return map { String(format: "%02x", $0) }.joined(separator: "").uppercased()
    }
}
