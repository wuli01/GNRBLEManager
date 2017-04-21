//
//  GNRPeripheral.h
//  BlueToothDemo
//
//  Created by LvYuan on 2017/4/20.
//  Copyright © 2017年 UUPaotui. All rights reserved.
//

/***********
 
 蓝牙外设对象的封装
 
 **********/

#import <CoreBluetooth/CoreBluetooth.h>

@interface GNRCharacteristic : NSObject

@property (nonatomic, copy, readonly)NSString * identifier;
@property (nonatomic, strong)CBCharacteristic * characteristic;
@property (nonatomic, strong)id value;
@property (nonatomic, strong)id descriptor;

@end

@interface GNRService : NSObject

@property (nonatomic, copy, readonly)NSString * identifier;
@property (nonatomic, strong)CBService * service;
@property (nonatomic, strong, readonly)NSMutableArray <GNRCharacteristic *>*characteristics;//该服务下的所有缓存的特征

- (GNRCharacteristic *)addCharacteristic:(CBCharacteristic *)characteristic;
- (void)removeCharacteristic:(CBCharacteristic *)characteristic;
- (GNRCharacteristic *)isExsit:(CBCharacteristic *)chara;

@end

@interface GNRServiceStore : NSObject

@property (nonatomic, strong, readonly)NSMutableArray <GNRService *>*services;//设备的所有服务缓存

- (void)addService:(CBService *)service;
- (void)removeService:(CBService *)service;
- (GNRService *)isExsit:(CBService *)service;

@end

@interface GNRPeripheral : NSObject

@property (nonatomic, copy, readonly)NSString * name;
@property (nonatomic, copy, readonly)NSString * identifier;
@property (nonatomic, strong)CBPeripheral * peripheral;

@property (nonatomic, strong)GNRServiceStore * serviceStore;//服务 的缓存
@property (nonatomic, strong)GNRCharacteristic * notifyChara;//通知的特征

//更新该特征的缓存值
- (GNRCharacteristic *)updateValue:(id)value characteristic:(CBCharacteristic *)characteristic;

@end
