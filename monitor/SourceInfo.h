#pragma once

#import <Foundation/Foundation.h>

#include "DataInfo.h"

@interface NCSourceInfo : NSObject
@property(nonatomic) NSString* timeStamp;
@property(nonatomic) NSString* processName;
@property(nonatomic) NSString* protocol;
@property(nonatomic) NSString* TCPState;
@property(nonatomic) const struct sockaddr* localAddress;
@property(nonatomic) const struct sockaddr* remoteAddress;
@property(nonatomic) NSNumber* PID;
@property(nonatomic) NCDataInfo* dataProcessed;
- (instancetype)initWithDict:(NSDictionary*)dictionary;
@end