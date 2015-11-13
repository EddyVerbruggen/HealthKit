#import <Cordova/CDV.h>
#import <HealthKit/HealthKit.h>

@interface HealthKit :CDVPlugin

@property (nonatomic) HKHealthStore *healthStore;

- (void) available:(CDVInvokedUrlCommand*)command;
// - (void) checkAuthStatus:(CDVInvokedUrlCommand*)command; // This is really only useful for writing
- (void) requestAuthorization:(CDVInvokedUrlCommand*)command;

#pragma mark - Testables
-(void)requestAuthorizationUsingReadTypes:(NSSet*)readDataTypes withCallbackId:(NSString*)callbackId andCompletion:(void(^)(CDVPluginResult* result, NSString *callbackId ))completion;
-(void)checkAuthStatusWithCallbackId:(NSString*)callbackId forType:(HKObjectType*)type
                       andCompletion:(void(^)(CDVPluginResult* result, NSString *callbackId ))completion;
-(void)findWorkoutsWithCallbackId:(NSString*)callbackId
                     forPredicate:(NSPredicate*)workoutPredicate
                    andCompletion:(void(^)(CDVPluginResult* result, NSString *callbackId ))completion;
#pragma mark -

- (void) readGender:(CDVInvokedUrlCommand*)command;
- (void) readBloodType:(CDVInvokedUrlCommand*)command;
- (void) readDateOfBirth:(CDVInvokedUrlCommand*)command;

- (void) readWeight:(CDVInvokedUrlCommand*)command;

- (void) readHeight:(CDVInvokedUrlCommand*)command;

- (void) findWorkouts:(CDVInvokedUrlCommand*)command;

- (void) monitorSampleType:(CDVInvokedUrlCommand*)command;
- (void) sumQuantityType:(CDVInvokedUrlCommand*)command;
- (void) querySampleType:(CDVInvokedUrlCommand*)command;

- (void) queryCorrelationType:(CDVInvokedUrlCommand*)command;

@end
