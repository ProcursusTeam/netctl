#import <Foundation/Foundation.h>
#import "output.h"
#import <Foundation/Foundation.h>

@interface NCOutput (Private)
+(void)printArray:(NSArray*)array level:(int)level;
+(NSArray*)jsonifiedArrayFromArray:(NSArray*)array;
@end

@implementation NCOutput

+(NSArray*)jsonifiedArrayFromArray:(NSArray*)array {
	NSMutableArray* ret = [NSMutableArray array];
	NSMutableDictionary* concatDicts = [NSMutableDictionary dictionary];

	for (id object in array) {
		if ([object isKindOfClass:[NSDictionary class]]) {
			id key = [object allKeys][0];
			if ([object[key] isKindOfClass:[NSArray class]]) {
				NSDictionary* newDictionary = @{ 
					key : [self jsonifiedArrayFromArray:object[key]]
				};

		 		[concatDicts addEntriesFromDictionary:newDictionary];
			}

			else {
				[concatDicts addEntriesFromDictionary:object];
			}
		}

		else if ([object isKindOfClass:[NSArray class]]) {
			 [ret addObject:[self jsonifiedArrayFromArray:object]];
		}

		else if ([object isKindOfClass:[NCNewline class]]) {
			// Skip NCNewlines since we use them to represent a newline
			continue;
		}

		else {
			[ret addObject:object];
		}
	}

	[ret addObject:concatDicts];

	return ret;
}

+(void)printArray:(NSArray*)array withJSON:(BOOL)useJSON {
	if (useJSON) {
		NSArray* jsonArray = [self jsonifiedArrayFromArray:array];
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray options:NSJSONWritingPrettyPrinted error:nil];
		printf("%s\n", jsonData.bytes);
	}

	else {
		[self printArray:array level:0];
	}
}

+(void)printArray:(NSArray*)array level:(int)level {
  	for (id object in array) {
		for (int i = 0; i < level; i++) {
			putc('\t', stdout); 
		}

		if ([object isKindOfClass:[NSString class]]) {
			printf("%s\n", [object UTF8String]);
		}

		else if ([object isKindOfClass:[NCNewline class]]) {
			putc('\n', stdout);
		}

		else if ([object isKindOfClass:[NSNumber class]]) {
			printf("%lld\n", [object longLongValue]);
		}

		else if ([object isKindOfClass:[NSDictionary class]]) {
			NSArray* allKeys = [object allKeys];
			id value = object[allKeys[0]];

			if ([value isKindOfClass:[NSArray class]]) {
				printf("%s: \n", [[allKeys[0] description] UTF8String]);
				[self printArray:value level:level+1];
			}

			else {
				printf("%s: %s\n", [[allKeys[0] description] UTF8String], [[value description] UTF8String]);
			}
		}
	}
}

@end

@implementation NCNewline
@end
