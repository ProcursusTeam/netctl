#pragma once

#import <Foundation/Foundation.h>

@interface NCDataInfo : NSObject
@property(nonatomic) NSNumber* tx;
@property(nonatomic) NSNumber* txPackets;
@property(nonatomic) NSNumber* txWiFi;
@property(nonatomic) NSNumber* txCellular;
@property(nonatomic) NSNumber* rx;
@property(nonatomic) NSNumber* rxPackets;
@property(nonatomic) NSNumber* rxWiFi;
@property(nonatomic) NSNumber* rxCellular;
- (instancetype)initWithDict:(NSDictionary*)dict;
@end