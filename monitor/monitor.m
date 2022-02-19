#include <Foundation/Foundation.h>
#import <NetworkStatistics/NetworkStatistics.h>

void(^description_block)(CFDictionaryRef) = ^(CFDictionaryRef cfdict) {
    CFNumberRef pid = CFDictionaryGetValue(cfdict, kNStatSrcKeyPID);
    CFNumberRef txcount = CFDictionaryGetValue(cfdict, kNStatSrcKeyTxBytes);

    CFStringRef pname = CFDictionaryGetValue(cfdict, kNStatSrcKeyProcessName);

    NSLog(@"pid: %@, pname: %@, tx: %@", pid, pname, txcount);
};

void(^callback)(void*, void*) = ^(NStatSourceRef ref, void* arg2) {
    NStatSourceSetDescriptionBlock(ref, description_block);
};

int nctl_monitor(int argc, char** argv) {
    NStatManagerRef ref = NStatManagerCreate(kCFAllocatorDefault, dispatch_get_main_queue(), callback);
    NStatManagerSetFlags(ref, 0);

    NStatManagerAddAllTCPWithFilter(ref, 0, 0);

    dispatch_main();
}
