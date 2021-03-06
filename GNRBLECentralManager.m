//
//  GNRBlueToothManager.m
//  BlueToothDemo
//
//  Created by LvYuan on 2017/4/19.
//  Copyright © 2017年 UUPaotui. All rights reserved.
//
/**
 1. 建立中心角色
 2. 扫描外设（discover）
 3. 连接外设(connect)
 4. 扫描外设中的服务和特征(discover)
 - 4.1 获取外设的services
 - 4.2 获取外设的Characteristics,获取Characteristics的值，获取Characteristics的Descriptor和Descriptor的值
 5. 与外设做数据交互(explore and interact)
 6. 订阅Characteristic的通知
 7. 断开连接(disconnect)
 */

#import "GNRBLECentralManager.h"

@interface GNRBLECentralManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>



@end

@implementation GNRBLECentralManager

+ (instancetype)manager{
    static GNRBLECentralManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
    }
    return self;
}

//getter
- (NSMutableArray *)peripherals{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (void)setup{
    _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
}

//扫描
- (instancetype)starScanPeripheralForServices:(NSArray <NSString *>*)services
                                       succee:(GNRBLEScanSucceeBlock)block
                                        error:(GNRBLEScanErrorBlock)errorBlock{
    _scanBlock = nil;
    _scanBlock = [block copy];
    _errorBlock = nil;
    _errorBlock = [errorBlock copy];
    _serivices = [NSMutableArray array];
    [services enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj length]) {
            CBUUID* UUID = [CBUUID UUIDWithString:obj];
            [_serivices addObject:UUID];
        }
    }];
    [self setup];
    return self;
}

- (BOOL)isExsitForServiceUUID:(NSString *)UUID{
    for (CBUUID * uu in self.serivices) {
        if ([UUID isEqualToString:uu.UUIDString]) {
            return YES;
        }
    }
    return NO;
}

//链接该设备
- (instancetype)connectForPeripheral:(GNRPeripheral *)peripheral
                   connectCompletion:(GNRBLEConnectBlock)connectBlock
                disconnectCompletion:(GNRBLEDisConnectBlock)disconnectBlock{
    _connectBlock = nil;
    _connectBlock = [connectBlock copy];
    _disConnectBlock = nil;
    _disConnectBlock = [disconnectBlock copy];
    if (peripheral.peripheral) {
        [self.centralManager connectPeripheral:peripheral.peripheral options:nil];
    }
    return self;
}

/**
 读取特征值
 */
- (instancetype)readValueForPeripheral:(GNRPeripheral *)peripheral
                    completion:(GNRBLEReadCharacteristicCompletion)completion;{
    if (!(peripheral.checkServiceUUID&&peripheral.checkServiceUUID)) {
        if (completion) {
            NSError * error = [NSError errorWithDomain:@"未设置特征UUID及所属服务的UUID" code:200 userInfo:nil];
            completion(nil,error);
        }
        return self;
    }
    _readValueCompletion = nil;
    _readValueCompletion = [completion copy];
    GNRCharacteristic * chara = [peripheral.serviceStore characteristicForServiceUUID:peripheral.checkServiceUUID characteristicUUID:peripheral.checkCharaUUID];
    if (chara) {
        [peripheral.peripheral readValueForCharacteristic:chara.characteristic];//读取特征值
    }
    
    return self;
}

//扫描设备
- (void)scanForPeripherals{
    //扫描有指定服务的设备
    [self.centralManager scanForPeripheralsWithServices:_serivices?:nil options:nil];
}

//扫描特征
- (void)discoverCharacteristicsForPeripheral:(GNRPeripheral *)peripheral service:(CBService *)service{
    if (peripheral.peripheral && service) {
        [peripheral.peripheral discoverCharacteristics:nil forService:service];
    }
}

//订阅该设备的通知
- (instancetype)notifyPeripheral:(GNRPeripheral *)per
                      completion:(GNRBLENotifyCompletion)notifyCompletion{
    _notifyCompletion = nil;
    _notifyCompletion = [notifyCompletion copy];
    [self setNotifyValue:YES peripheral:per];
    return self;
}

- (void)setNotifyValue:(BOOL)value peripheral:(GNRPeripheral *)per{
    if (per.notifyCharacteristic.characteristic) {
        [per.peripheral setNotifyValue:value forCharacteristic:per.notifyCharacteristic.characteristic];
    }else{
        if (_notifyCompletion) {
            NSError * error = [NSError errorWithDomain:@"未获取到该特征" code:200 userInfo:nil];
            _notifyCompletion(per,error);
        }
    }
}

+ (NSData *)newData{
    return [NSData data];
}

- (GNRPeripheral *)getPerModelForPeripheral:(CBPeripheral *)peripheral{
    for (GNRPeripheral * per in self.peripherals) {
        if ([per.identifier isEqualToString: peripheral.identifier.UUIDString]) {
            return per;
        }
    }
    return nil;
}

//MARK: - 向设备的特征中写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    CBCharacteristicProperties properties = characteristic.properties;
    NSLog(@"该特征字段权限 %lu", (unsigned long)properties);//特征字段权限
    if(properties & CBCharacteristicPropertyWrite){//可写
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];//有响应
    }else{
        NSLog(@"该字段不可写！");
    }
}

#pragma mark - 蓝牙状态更新回调
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSString * domain = nil;
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            domain = @"CBCentralManagerStateUnknown";
            break;
        case CBCentralManagerStateResetting:
            domain = @"CBCentralManagerStateResetting";
            break;
        case CBCentralManagerStateUnsupported:
            domain = @"CBCentralManagerStateResetting";
            break;
        case CBCentralManagerStateUnauthorized:
            domain = @"CBCentralManagerStateUnauthorized";
            break;
        case CBCentralManagerStatePoweredOff:
            domain = @"CBCentralManagerStatePoweredOff";
            break;
        case CBCentralManagerStatePoweredOn:
            break;
        default:
            break;
    }
    if (central.state==CBCentralManagerStatePoweredOn) {
        NSLog(@">>>CBCentralManagerStatePoweredOn");
        [self scanForPeripherals];
    }else{
        if (_errorBlock) {
            NSError * error = [NSError errorWithDomain:domain code:central.state userInfo:nil];
            _errorBlock(error);
        }
    }
}

- (BOOL)containsPerModel:(CBPeripheral *)per{
    __block BOOL isExsit = NO;
    if (per) {
        [self.peripherals enumerateObjectsUsingBlock:^(GNRPeripheral * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.peripheral.identifier.UUIDString isEqualToString:per.identifier.UUIDString]) {
                isExsit = YES;
            }
        }];
    }
    return isExsit;
}

//扫描该设备下的所有服务
- (void)scanServicesForPeripheral:(GNRPeripheral *)per{
    if (per.peripheral) {
        [per.peripheral setDelegate:self];
        [per.peripheral discoverServices:_serivices?:nil];//搜索服务
    }
}

#pragma mark - 扫描设备回调
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI{
    if ([peripheral.name hasPrefix:NamePrefix_Peripheral]&&//名字有指定的前缀
        ![self containsPerModel:peripheral]&&//缓存中不存在
        peripheral) {//peripheral 不为nil
        GNRPeripheral * perModel = [GNRBLEHelper getNewMyPeripheral:peripheral];
        [self.peripherals addObject:perModel];
        if (_scanBlock) {
            _scanBlock(self.peripherals);
        }
    }
}

#pragma mark - 设备连接回调
//连接到Peripheral-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //连接到改设备
    GNRPeripheral * per = [self getPerModelForPeripheral:peripheral];
    if (_connectBlock&&per) {
        _connectBlock(per,nil);
    }
    [self scanServicesForPeripheral:per];
}

//连接到Peripheral-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //连接失败
    GNRPeripheral * per = [self getPerModelForPeripheral:peripheral];
    if (_connectBlock&&per) {
        _connectBlock(per,error);
    }
}

//断开连接Peripheral
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    GNRPeripheral * perModel = [self getPerModelForPeripheral:peripheral];
    //删除这个perModel
    [self clearDisConnectPer:perModel];
    if (_disConnectBlock) {
        _disConnectBlock(perModel,error);
    }
}

- (void)clearDisConnectPer:(GNRPeripheral *)per{
    if (per) {//删除无效的设备
        [self setNotifyValue:NO peripheral:per];
        per.peripheral.delegate = nil;
        per.peripheral = nil;
        [_peripherals removeObject:per];
    }
}


#pragma mark - 扫描服务回调
//扫描到服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    GNRPeripheral * perModel = [self getPerModelForPeripheral:peripheral];
    if (error){
        if (_discoverServiceCompletion&&perModel) {
            _discoverServiceCompletion(perModel,nil,error);
        }
        return;
    }
    for (CBService *service in peripheral.services) {
        if ([self isExsitForServiceUUID:service.UUID.UUIDString]) {
            GNRService * serModel = [perModel.serviceStore addService:service];//增加到缓存
            if (_discoverServiceCompletion&&perModel) {
                _discoverServiceCompletion(perModel,serModel,nil);
            }
            [self discoverCharacteristicsForPeripheral:perModel service:service];
        }
    }
}

#pragma mark - 扫描特征回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    GNRPeripheral * perModel = [self getPerModelForPeripheral:peripheral];
    if (error){
        if (_characteristicCompletion&&perModel) {
            _characteristicCompletion(perModel,nil,error);
        }
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics){
        GNRService * serModel = [perModel.serviceStore isExsit:service];
        GNRCharacteristic * chara = [serModel addCharacteristic:characteristic];
        if (_characteristicCompletion&&perModel) {
            _characteristicCompletion(perModel,chara,nil);
        }
    }
}

//读取到特征值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    GNRPeripheral * perModel = [self getPerModelForPeripheral:peripheral];
    if (error){
        if (_readValueCompletion&&perModel) {
            _readValueCompletion(nil,error);
        }
        return;
    }
    if ([characteristic.UUID.UUIDString isEqualToString:perModel.checkCharaUUID]) {
        GNRCharacteristic * chara = [perModel updateValue:characteristic.value characteristic:characteristic];//更新值
        if (_readValueCompletion) {
            _readValueCompletion(chara.value,nil);
        }
    }
    //通知
    if ([perModel isNotifyCharacteristic:characteristic.UUID.UUIDString]) {
        [perModel updateValue:characteristic.value characteristic:characteristic];//更新值
        if (_notifyCompletion) {
            _notifyCompletion(perModel,nil);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    NSLog(@"didUpdateNotificationStateForCharacteristic");
    
}

#pragma mark - 以下暂时不用以后可以扩展
/*
//搜索到Characteristic的Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"characteristic uuid:%@",characteristic.UUID);
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",d.UUID);
    }
}

//获取到Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}
*/
@end
