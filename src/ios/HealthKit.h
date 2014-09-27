#import <Cordova/CDV.h>

@interface HealthKit :CDVPlugin

- (void) available:(CDVInvokedUrlCommand*)command;
- (void) saveWeight:(CDVInvokedUrlCommand*)command;
- (void) readWeight:(CDVInvokedUrlCommand*)command;

@end
