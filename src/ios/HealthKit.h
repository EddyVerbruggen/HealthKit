#import <Cordova/CDV.h>
#import <HealthKit/HealthKit.h>

@interface HealthKit :CDVPlugin

@property (nonatomic) HKHealthStore *healthStore;
@property (nonatomic) NSDateFormatter *dateFormatter;

- (void) available:(CDVInvokedUrlCommand*)command;
- (void) checkAuthStatus:(CDVInvokedUrlCommand*)command;
- (void) requestAuthorization:(CDVInvokedUrlCommand*)command;

- (void) readGender:(CDVInvokedUrlCommand*)command;
- (void) readBloodType:(CDVInvokedUrlCommand*)command;
- (void) readDateOfBirth:(CDVInvokedUrlCommand*)command;

- (void) saveWeight:(CDVInvokedUrlCommand*)command;
- (void) readWeight:(CDVInvokedUrlCommand*)command;

- (void) saveHeight:(CDVInvokedUrlCommand*)command;
- (void) readHeight:(CDVInvokedUrlCommand*)command;

- (void) saveWorkout:(CDVInvokedUrlCommand*)command;
- (void) findWorkouts:(CDVInvokedUrlCommand*)command;

- (void) monitorSampleType:(CDVInvokedUrlCommand*)command;
- (void) sumQuantityType:(CDVInvokedUrlCommand*)command;

- (void) querySampleType:(CDVInvokedUrlCommand*)command;
- (void) querySampleTypeAggregated:(CDVInvokedUrlCommand*)command;

- (void) saveQuantitySample:(CDVInvokedUrlCommand*)command;
- (void) saveCorrelation:(CDVInvokedUrlCommand*)command;
- (void) queryCorrelationType:(CDVInvokedUrlCommand*)command;

@end
