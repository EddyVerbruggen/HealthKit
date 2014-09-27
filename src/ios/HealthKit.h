#import <Cordova/CDV.h>
#import <HealthKit/HealthKit.h>

@interface HealthKit :CDVPlugin

@property (nonatomic) HKHealthStore *healthStore;

- (void) available:(CDVInvokedUrlCommand*)command;
- (void) saveWeight:(CDVInvokedUrlCommand*)command;
- (void) readWeight:(CDVInvokedUrlCommand*)command;

@end
