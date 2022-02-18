#include <Foundation/Foundation.h>
#import <NetworkStatistics/NetworkStatistics.h>

void(^callback)(void*, void*) = ^(NStatSourceRef ref, void* arg2) {
    static int ctr = 0;
    printf("HELLO %d\n", ctr);
    ctr++;
};

int nctl_monitor(int argc, char** argv) {
    NStatManagerRef ref = NStatManagerCreate(kCFAllocatorDefault, dispatch_get_main_queue(), callback);
    NStatManagerSetFlags(ref, 0);

    NStatManagerAddAllTCPWithFilter(ref, 0, 0);

    dispatch_main();
}
