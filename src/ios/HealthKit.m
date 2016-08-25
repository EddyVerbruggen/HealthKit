#import "HealthKit.h"
#import "HKHealthStore+AAPLExtensions.h"
#import "WorkoutActivityConversion.h"
#import "Cordova/CDV.h"

#define HKPLUGIN_DEBUG

#pragma mark Property Type Constants
static NSString *const HKPluginError                = @"HKPluginError";
static NSString *const HKPluginKeyReadTypes         = @"readTypes";
static NSString *const HKPluginKeyWriteTypes        = @"writeTypes";
static NSString *const HKPluginKeyType              = @"type";
static NSString *const HKPluginKeyStartDate         = @"startDate";
static NSString *const HKPluginKeyEndDate           = @"endDate";
static NSString *const HKPluginKeySampleType        = @"sampleType";
static NSString *const HKPluginKeyAggregation       = @"aggregation";
static NSString *const HKPluginKeyUnit              = @"unit";
static NSString *const HKPluginKeyAmount            = @"amount";
static NSString *const HKPluginKeyValue             = @"value";
static NSString *const HKPluginKeyCorrelationType   = @"correlationType";
static NSString *const HKPluginKeyObjects           = @"samples";
static NSString *const HKPluginKeySourceName        = @"sourceName";
static NSString *const HKPluginKeySourceBundleId    = @"sourceBundleId";
static NSString *const HKPluginKeyMetadata          = @"metadata";
static NSString *const HKPluginKeyUUID              = @"UUID";

#pragma mark Categories
// Public Interface extension category
@interface HealthKit ()
- (HKHealthStore *) sharedHealthStore;
@end

// Internal interface
@interface HealthKit (Internal)
- (void)checkAuthStatusWithCallbackId:(NSString *)callbackId
                              forType:(HKObjectType *)type
                        andCompletion:(void (^)(CDVPluginResult *result, NSString *callbackId))completion;
@end

// Internal interface helper methods
@interface HealthKit (InternalHelpers)
- (NSString *)stringFromDate:(NSDate *)date;

- (HKUnit *)getUnit:(NSString *)type :(NSString *)expected;

- (HKObjectType *)getHKObjectType:(NSString *)elem;

- (HKQuantityType *)getHKQuantityType:(NSString *)elem;

- (HKSampleType *)getHKSampleType:(NSString *)elem;

- (HKQuantitySample *)loadHKQuantitySampleFromInputDictionary:(NSDictionary *)inputDictionary error:(NSError **)error;

- (HKCorrelation *)loadHKCorrelationFromInputDictionary:(NSDictionary *)inputDictionary error:(NSError **)error;

- (BOOL)inputDictionary:(NSDictionary *)inputDictionary hasRequiredKey:(NSString *)key error:(NSError **)error;

- (HKQuantitySample *)getHKQuantitySampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate sampleTypeString:(NSString *)sampleTypeString unitTypeString:(NSString *)unitTypeString value:(double)value metadata:(NSDictionary *)metadata error:(NSError **)error;

- (HKCorrelation *)getHKCorrelationWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate correlationTypeString:(NSString *)correlationTypeString objects:(NSSet *)objects metadata:(NSDictionary *)metadata error:(NSError **)error;
@end

/**
 * Implementation of internal interface
 * **************************************************************************************
 */
#pragma mark Internal Interface
@implementation HealthKit (Internal)

- (void) checkAuthStatusWithCallbackId:(NSString *)callbackId forType:(HKObjectType *)type andCompletion:(void (^)(CDVPluginResult *, NSString *))completion {
    
    CDVPluginResult *pluginResult = nil;
    
    if (type == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"type is an invalid value"];
    } else {
        HKAuthorizationStatus status = [[self sharedHealthStore] authorizationStatusForType:type];

        NSString *authorizationResult = nil;
        switch (status) {
            case HKAuthorizationStatusSharingAuthorized:
                authorizationResult = @"authorized";
                break;
            case HKAuthorizationStatusSharingDenied:
                authorizationResult = @"denied";
                break;
            default:
                authorizationResult = @"undetermined";
        }
        
#ifdef HKPLUGIN_DEBUG
        NSLog(@"Health store returned authorization status: %@ for type %@", authorizationResult, [type description]);
#endif
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:authorizationResult];
    }
    
    completion(pluginResult, callbackId);
}

@end

/**
 * Implementation of internal helpers interface
 * **************************************************************************************
 */
#pragma mark Internal Helpers
@implementation HealthKit (InternalHelpers)

- (NSString *)stringFromDate:(NSDate *)date {
    __strong static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    });
    
    return [formatter stringFromDate:date];
}

- (HKUnit *)getUnit:(NSString *)type :(NSString *)expected {
    HKUnit *localUnit;
    @try {
        localUnit = [HKUnit unitFromString:type];
        if ([[[localUnit class] description] isEqualToString:expected]) {
            return localUnit;
        } else {
            return nil;
        }
    }
    @catch (NSException *e) {
        return nil;
    }
}

- (HKObjectType *)getHKObjectType:(NSString *)elem {
    HKObjectType *type = [HKObjectType quantityTypeForIdentifier:elem];
    if (type == nil) {
        type = [HKObjectType characteristicTypeForIdentifier:elem];
    }
    if (type == nil) {
        type = [self getHKSampleType:elem];
    }
    return type;
}

- (HKQuantityType *)getHKQuantityType:(NSString *)elem {
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:elem];
    return type;
}

- (HKSampleType *)getHKSampleType:(NSString *)elem {
    HKSampleType *type = [HKObjectType quantityTypeForIdentifier:elem];
    if (type == nil) {
        type = [HKObjectType categoryTypeForIdentifier:elem];
    }
    if (type == nil) {
        type = [HKObjectType quantityTypeForIdentifier:elem];
    }
    if (type == nil) {
        type = [HKObjectType correlationTypeForIdentifier:elem];
    }
    if (type == nil && [elem isEqualToString:@"workoutType"]) {
        type = [HKObjectType workoutType];
    }
    return type;
}

//Helper to parse out a quantity sample from a dictionary and perform error checking
- (HKQuantitySample *)loadHKQuantitySampleFromInputDictionary:(NSDictionary *)inputDictionary error:(NSError **)error {
    //Load quantity sample from args to command
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeyStartDate error:error]) {
        return nil;
    }
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[inputDictionary[HKPluginKeyStartDate] longValue]];
    
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeyEndDate error:error]) {
        return nil;
    }
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[inputDictionary[HKPluginKeyEndDate] longValue]];
    
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeySampleType error:error]) {
        return nil;
    }
    NSString *sampleTypeString = inputDictionary[HKPluginKeySampleType];
    
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeyUnit error:error]) {
        return nil;
    }
    NSString *unitString = inputDictionary[HKPluginKeyUnit];
    
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeyAmount error:error]) {
        return nil;
    }
    
    //Load optional metadata key
    NSDictionary *metadata = inputDictionary[HKPluginKeyMetadata];
    if (metadata == nil)
        metadata = @{};
    
    return [self getHKQuantitySampleWithStartDate:startDate
                                          endDate:endDate
                                 sampleTypeString:sampleTypeString
                                   unitTypeString:unitString
                                            value:[inputDictionary[HKPluginKeyAmount] doubleValue]
                                         metadata:metadata error:error];
}

//Helper to parse out a correlation from a dictionary and perform error checking
- (HKCorrelation *)loadHKCorrelationFromInputDictionary:(NSDictionary *)inputDictionary error:(NSError **)error {
    //Load correlation from args to command
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeyStartDate error:error]) return nil;
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[inputDictionary[HKPluginKeyStartDate] longValue]];
    
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeyEndDate error:error]) return nil;
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[inputDictionary[HKPluginKeyEndDate] longValue]];
    
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeyCorrelationType error:error]) {
        return nil;
    }
    NSString *correlationTypeString = inputDictionary[HKPluginKeyCorrelationType];
    
    if (![self inputDictionary:inputDictionary hasRequiredKey:HKPluginKeyObjects error:error]) {
        return nil;
    }
    NSArray *objectDictionaries = inputDictionary[HKPluginKeyObjects];
    
    NSMutableSet *objects = [NSMutableSet set];
    for (NSDictionary *objectDictionary in objectDictionaries) {
        HKQuantitySample *sample = [self loadHKQuantitySampleFromInputDictionary:objectDictionary error:error];
        if (sample == nil)
            return nil;
        [objects addObject:sample];
    }
    NSDictionary *metadata = inputDictionary[HKPluginKeyMetadata];
    if (metadata == nil)
        metadata = @{};
    return [self getHKCorrelationWithStartDate:startDate
                                       endDate:endDate
                         correlationTypeString:correlationTypeString
                                       objects:objects
                                      metadata:metadata
                                         error:error];
}

//Helper to isolate error checking on inputs for plugin
- (BOOL)inputDictionary:(NSDictionary *)inputDictionary hasRequiredKey:(NSString *)key error:(NSError **)error {
    if (inputDictionary[key] == nil) {
        // it is possible to pass a null reference here
        if (error != nil) {
            *error = [NSError errorWithDomain:HKPluginError code:0 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"required value -%@- was missing from dictionary %@", key, [inputDictionary description]]}];
        }
        
        return false;
    }
    return true;
}

// Helper to handle the functionality with HealthKit to get a quantity sample
- (HKQuantitySample *)getHKQuantitySampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate sampleTypeString:(NSString *)sampleTypeString unitTypeString:(NSString *)unitTypeString value:(double)value metadata:(NSDictionary *)metadata error:(NSError **)error {
    HKQuantityType *type = [self getHKQuantityType:sampleTypeString];
    if (type == nil) {
        *error = [NSError errorWithDomain:HKPluginError code:0 userInfo:@{NSLocalizedDescriptionKey: @"quantity type string was invalid"}];
        return nil;
    }
    HKUnit *unit;
    @try {
        unit = unitTypeString != nil ? [HKUnit unitFromString:unitTypeString] : nil;
        if (unit == nil) {
            *error = [NSError errorWithDomain:HKPluginError code:0 userInfo:@{NSLocalizedDescriptionKey: @"unit was invalid"}];
            return nil;
        }
    }
    @catch (NSException *e) {
        *error = [NSError errorWithDomain:HKPluginError code:0 userInfo:@{NSLocalizedDescriptionKey: @"unit was invalid"}];
        return nil;
    }
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:value];
    if (![quantity isCompatibleWithUnit:unit]) {
        *error = [NSError errorWithDomain:HKPluginError code:0 userInfo:@{NSLocalizedDescriptionKey: @"unit was not compatible with quantity"}];
        return nil;
    }
    
    return [HKQuantitySample quantitySampleWithType:type quantity:quantity startDate:startDate endDate:endDate metadata:metadata];
}

- (HKCorrelation *)getHKCorrelationWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate correlationTypeString:(NSString *)correlationTypeString objects:(NSSet *)objects metadata:(NSDictionary *)metadata error:(NSError **)error {
    NSLog(@"correlation type is %@", correlationTypeString);
    HKCorrelationType *correlationType = [HKCorrelationType correlationTypeForIdentifier:correlationTypeString];
    // possible null reference
    if (correlationType == nil) {
        if (error != nil) {
            *error = [NSError errorWithDomain:HKPluginError code:0 userInfo:@{NSLocalizedDescriptionKey: @"correlation type string was invalid"}];
        }
        
        return nil;
    }
    return [HKCorrelation correlationWithType:correlationType startDate:startDate endDate:endDate objects:objects metadata:metadata];
}

@end


/**
 * Implementation of public interface
 * **************************************************************************************
 */
#pragma mark Public Interface
@implementation HealthKit

/**
 * Get shared health store
 */
- (HKHealthStore *) sharedHealthStore {
    __strong static HKHealthStore *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[HKHealthStore alloc] init];
    });
    
    return store;
}

/**
 * Tell delegate whether or not health data is available
 */
- (void)available:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[HKHealthStore isHealthDataAvailable]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

/**
 * Request authorization for read and/or write permissions
 */
- (void)requestAuthorization:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];

    // read types
    NSArray *readTypes = args[HKPluginKeyReadTypes];
    
    NSMutableSet *readDataTypes = [[NSMutableSet alloc] init];
    for (NSUInteger i = 0; i < [readTypes count]; i++) {

        NSString *elem = readTypes[i];
#ifdef HKPLUGIN_DEBUG
        NSLog(@"Requesting read permissions for %@", elem);
#endif

        HKObjectType *type = nil;

        if ([elem isEqual:@"HKWorkoutTypeIdentifier"]) {
            type = [HKObjectType workoutType];
        } else {
            type = [self getHKObjectType:elem];
        }

        if (type == nil) {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"readTypes contains an invalid value"];
            [result setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            // not returning deliberately to be future proof; other permissions are still asked
        } else {
            [readDataTypes addObject:type];
        }
    }

    // write types
    NSArray *writeTypes = args[HKPluginKeyWriteTypes];
    NSMutableSet *writeDataTypes = [[NSMutableSet alloc] init];
    for (NSUInteger i = 0; i < [writeTypes count]; i++) {
        NSString *elem = writeTypes[i];
#ifdef HKPLUGIN_DEBUG
        NSLog(@"Requesting write permission for %@", elem);
#endif
        HKObjectType *type = nil;

        if ([elem isEqual:@"HKWorkoutTypeIdentifier"]) {
            type = [HKObjectType workoutType];
        } else {
            type = [self getHKObjectType:elem];
        }

        if (type == nil) {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"writeTypes contains an invalid value"];
            [result setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            // not returning deliberately to be future proof; other permissions are still asked
        } else {
            [writeDataTypes addObject:type];
        }
    }

    [[self sharedHealthStore] requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
        if (success) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                
#ifdef HKPLUGIN_DEBUG
                NSLog(@"%@", @"DEBUG ENABLED");
#endif
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];
}

/**
 * Check the authorization status for a specified permission
 */
- (void)checkAuthStatus:(CDVInvokedUrlCommand *)command {
    // If status = denied, prompt user to go to settings or the Health app
    // Note that read access is not reflected. We're not allowed to know
    // if a user grants/denies read access, *only* write access.
    NSMutableDictionary *args = command.arguments[0];
    NSString *checkType = args[HKPluginKeyType];
    HKObjectType *type = [self getHKObjectType:checkType];
    
    __block HealthKit *bSelf = self;
    [self checkAuthStatusWithCallbackId:command.callbackId forType:type andCompletion:^(CDVPluginResult *result, NSString *callbackId) {
        [bSelf.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

/**
 * Save workout datum
 */
- (void)saveWorkout:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];

    NSString *activityType = args[@"activityType"];
    NSString *quantityType = args[@"quantityType"]; // TODO verify this value

    HKWorkoutActivityType activityTypeEnum = [WorkoutActivityConversion convertStringToHKWorkoutActivityType:activityType];

    BOOL requestReadPermission = (args[@"requestReadPermission"] == nil || [args[@"requestReadPermission"] boolValue]);

    // optional energy
    NSNumber *energy = args[@"energy"];
    NSString *energyUnit = args[@"energyUnit"];
    HKQuantity *nrOfEnergyUnits = nil;
    if (energy != nil && energy != (id) [NSNull null]) { // better safe than sorry
        HKUnit *preferredEnergyUnit = [self getUnit:energyUnit :@"HKEnergyUnit"];
        if (preferredEnergyUnit == nil) {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid energyUnit was passed"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        }
        nrOfEnergyUnits = [HKQuantity quantityWithUnit:preferredEnergyUnit doubleValue:energy.doubleValue];
    }

    // optional distance
    NSNumber *distance = args[@"distance"];
    NSString *distanceUnit = args[@"distanceUnit"];
    HKQuantity *nrOfDistanceUnits = nil;
    if (distance != nil && distance != (id) [NSNull null]) { // better safe than sorry
        HKUnit *preferredDistanceUnit = [self getUnit:distanceUnit :@"HKLengthUnit"];
        if (preferredDistanceUnit == nil) {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid distanceUnit was passed"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        }
        nrOfDistanceUnits = [HKQuantity quantityWithUnit:preferredDistanceUnit doubleValue:distance.doubleValue];
    }

    int duration = 0;
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyStartDate] doubleValue]];


    NSDate *endDate;
    if (args[@"duration"]) {
        duration = [args[@"duration"] intValue];
        endDate = [NSDate dateWithTimeIntervalSince1970:startDate.timeIntervalSince1970 + duration];
    } else if (args[HKPluginKeyEndDate]) {
        endDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyEndDate] doubleValue]];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no duration or endDate was set"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    NSSet *types = [NSSet setWithObjects:
                    [HKWorkoutType workoutType],
                    [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned],
                    [HKQuantityType quantityTypeForIdentifier:quantityType],
                    nil];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:types readTypes:requestReadPermission ? types : nil completion:^(BOOL success_requestAuth, NSError *error) {
        if (!success_requestAuth) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        } else {
            HKWorkout *workout = [HKWorkout workoutWithActivityType:activityTypeEnum
                                                          startDate:startDate
                                                            endDate:endDate
                                                           duration:0 // the diff between start and end is used
                                                  totalEnergyBurned:nrOfEnergyUnits
                                                      totalDistance:nrOfDistanceUnits
                                                           metadata:nil]; // TODO find out if needed
            [[self sharedHealthStore] saveObject:workout withCompletion:^(BOOL success_save, NSError *innerError) {
                if (success_save) {
                    // now store the samples, so it shows up in the health app as well (pass this in as an option?)
                    if (energy != nil) {
                        HKQuantitySample *sampleActivity = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:
                                        quantityType]
                                                                                           quantity:nrOfDistanceUnits
                                                                                          startDate:startDate
                                                                                            endDate:endDate];
                        HKQuantitySample *sampleCalories = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:
                                        HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                                           quantity:nrOfEnergyUnits
                                                                                          startDate:startDate
                                                                                            endDate:endDate];
                        NSArray *samples = @[sampleActivity, sampleCalories];

                        __block HealthKit *bSelf = self;
                        [[self sharedHealthStore] addSamples:samples toWorkout:workout completion:^(BOOL success_addSamples, NSError *mostInnerError) {
                            if (success_addSamples) {
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                                    [bSelf.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                                });
                            } else {
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:mostInnerError.localizedDescription];
                                    [bSelf.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                                });
                            }
                        }];
                    }
                } else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:innerError.localizedDescription];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                }
            }];
        }
    }];
}

/**
 * Find workout data
 */
- (void)findWorkouts:(CDVInvokedUrlCommand *)command {
    NSPredicate *workoutPredicate = nil;
    // TODO if a specific workouttype was passed, use that
    //  if (false) {
    //    workoutPredicate = [HKQuery predicateForWorkoutsWithWorkoutActivityType:HKWorkoutActivityTypeCycling];
    //  }

    NSSet *types = [NSSet setWithObjects:[HKWorkoutType workoutType], nil];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:nil readTypes:types completion:^(BOOL success, NSError *error) {
        if (!success) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        } else {


            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:[HKWorkoutType workoutType] predicate:workoutPredicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery *sampleQuery, NSArray *results, NSError *innerError) {
                if (innerError) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:innerError.localizedDescription];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                } else {
                    NSMutableArray *finalResults = [[NSMutableArray alloc] initWithCapacity:results.count];

                    for (HKWorkout *workout in results) {
                        NSString *workoutActivity = [WorkoutActivityConversion convertHKWorkoutActivityTypeToString:workout.workoutActivityType];

                        // iOS 9 moves the source property to a collection of revisions
                        HKSource *source = nil;
                        if ([workout respondsToSelector:@selector(sourceRevision)]) {
                            source = [[workout valueForKey:@"sourceRevision"] valueForKey:@"source"];
                        } else {
                            //@TODO Update deprecated API call
                            source = workout.source;
                        }

                        // TODO: use a float value, or switch to metric
                        double miles = [workout.totalDistance doubleValueForUnit:[HKUnit mileUnit]];
                        NSString *milesString = [NSString stringWithFormat:@"%ld", (long) miles];

                        NSEnergyFormatter *energyFormatter = [NSEnergyFormatter new];
                        energyFormatter.forFoodEnergyUse = NO;
                        double joules = [workout.totalEnergyBurned doubleValueForUnit:[HKUnit jouleUnit]];
                        NSString *calories = [energyFormatter stringFromJoules:joules];

                        NSMutableDictionary *entry = [
                            @{
                                @"duration": @(workout.duration),
                                HKPluginKeyStartDate: [self stringFromDate:workout.startDate],
                                HKPluginKeyEndDate: [self stringFromDate:workout.endDate],
                                @"miles": milesString,
                                @"calories": calories,
                                HKPluginKeySourceBundleId: source.bundleIdentifier,
                                HKPluginKeySourceName: source.name,
                                @"activityType": workoutActivity,
                                @"UUID": [workout.UUID UUIDString]
                            } mutableCopy];

                        [finalResults addObject:entry];
                    }

                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                }
            }];
            [[self sharedHealthStore] executeQuery:query];
        }
    }];
}

/**
 * Save weight datum
 */
- (void)saveWeight:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSString *unit = args[HKPluginKeyUnit];
    NSNumber *amount = args[HKPluginKeyAmount];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[args[@"date"] doubleValue]];
    BOOL requestReadPermission = args[@"requestReadPermission"] == nil || [args[@"requestReadPermission"] boolValue];

    if (amount == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no amount was set"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    HKUnit *preferredUnit = [self getUnit:unit :@"HKMassUnit"];
    if (preferredUnit == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid unit was passed"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    NSSet *requestTypes = [NSSet setWithObjects:weightType, nil];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:requestTypes readTypes:requestReadPermission ? requestTypes : nil completion:^(BOOL success, NSError *error) {
        if (success) {
            HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:preferredUnit doubleValue:[amount doubleValue]];
            HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:date endDate:date];
            [[self sharedHealthStore] saveObject:weightSample withCompletion:^(BOOL success_save, NSError *errorInner) {
                if (success_save) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                } else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInner.localizedDescription];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                }
            }];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];
}

/**
 * Read weight datum
 * @TODO do we get back a date? Yes, see aapl_mostRecentQuantitySampleOfType
 */
- (void)readWeight:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSString *unit = args[HKPluginKeyUnit];
    BOOL requestWritePermission = args[@"requestWritePermission"] == nil || [args[@"requestWritePermission"] boolValue];

    HKUnit *preferredUnit = [self getUnit:unit :@"HKMassUnit"];
    if (preferredUnit == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid unit was passed"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    // Query to get the user's latest weight, if it exists.
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    NSSet *requestTypes = [NSSet setWithObjects:weightType, nil];
    // always ask for read and write permission if the app uses both, because granting read will remove write for the same type :(
    [[self sharedHealthStore] requestAuthorizationToShareTypes:requestWritePermission ? requestTypes : nil readTypes:requestTypes completion:^(BOOL success, NSError *error) {
        if (success) {
            [[self sharedHealthStore] aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSDate *mostRecentDate, NSError *errorInner) {
                if (mostRecentQuantity) {
                    double usersWeight = [mostRecentQuantity doubleValueForUnit:preferredUnit];
                    NSMutableDictionary *entry = [
                        @{
                            HKPluginKeyValue: @(usersWeight),
                            HKPluginKeyUnit: unit,
                            @"date": [self stringFromDate:mostRecentDate]
                        } mutableCopy];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:entry];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *errorDescritption = errorInner.localizedDescription == nil ? @"no data" : errorInner.localizedDescription;
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorDescritption];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                }
            }];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];
}

/**
 * Save height datum
 */
- (void)saveHeight:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSString *unit = args[HKPluginKeyUnit];
    NSNumber *amount = args[HKPluginKeyAmount];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[args[@"date"] doubleValue]];
    BOOL requestReadPermission = args[@"requestReadPermission"] == nil || [args[@"requestReadPermission"] boolValue];

    if (amount == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no amount was set"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    HKUnit *preferredUnit = [self getUnit:unit :@"HKLengthUnit"];
    if (preferredUnit == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid unit was passed"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    NSSet *requestTypes = [NSSet setWithObjects:heightType, nil];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:requestTypes readTypes:requestReadPermission ? requestTypes : nil completion:^(BOOL success_requestAuth, NSError *error) {
        if (success_requestAuth) {
            HKQuantity *heightQuantity = [HKQuantity quantityWithUnit:preferredUnit doubleValue:[amount doubleValue]];
            HKQuantitySample *heightSample = [HKQuantitySample quantitySampleWithType:heightType quantity:heightQuantity startDate:date endDate:date];
            [[self sharedHealthStore] saveObject:heightSample withCompletion:^(BOOL success_save, NSError *innerError) {
                if (success_save) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                } else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:innerError.localizedDescription];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                }
            }];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];
}

/**
 * Read height datum
 */
- (void)readHeight:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSString *unit = args[HKPluginKeyUnit];
    BOOL requestWritePermission = args[@"requestWritePermission"] == nil || [args[@"requestWritePermission"] boolValue];

    HKUnit *preferredUnit = [self getUnit:unit :@"HKLengthUnit"];
    if (preferredUnit == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid unit was passed"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    // Query to get the user's latest height, if it exists.
    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    NSSet *requestTypes = [NSSet setWithObjects:heightType, nil];
    // always ask for read and write permission if the app uses both, because granting read will remove write for the same type :(
    [[self sharedHealthStore] requestAuthorizationToShareTypes:requestWritePermission ? requestTypes : nil readTypes:requestTypes completion:^(BOOL success, NSError *error) {
        if (success) {
            [[self sharedHealthStore] aapl_mostRecentQuantitySampleOfType:heightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSDate *mostRecentDate, NSError *errorInner) { // TODO use
                if (mostRecentQuantity) {
                    double usersHeight = [mostRecentQuantity doubleValueForUnit:preferredUnit];
                    NSMutableDictionary *entry = [
                        @{
                            HKPluginKeyValue: @(usersHeight),
                            HKPluginKeyUnit: unit,
                            @"date": [self stringFromDate:mostRecentDate]
                        } mutableCopy];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:entry];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *errorDescritption = errorInner.localizedDescription == nil ? @"no data" : errorInner.localizedDescription;
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorDescritption];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                }
            }];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];
}

/**
 * Read gender datum
 */
- (void)readGender:(CDVInvokedUrlCommand *)command {
    HKCharacteristicType *genderType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:genderType, nil] completion:^(BOOL success, NSError *error) {
        if (success) {
            HKBiologicalSexObject *sex = [[self sharedHealthStore] biologicalSexWithError:&error];
            if (sex) {
                NSString *gender = @"unknown";
                if (sex.biologicalSex == HKBiologicalSexMale) {
                    gender = @"male";
                } else if (sex.biologicalSex == HKBiologicalSexFemale) {
                    gender = @"female";
                } else if (sex.biologicalSex == HKBiologicalSexOther) {
                    gender = @"other";
                }
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:gender];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
    }];
}

/**
 * Read Fitzpatrick Skin Type Datum
 */
- (void)readFitzpatrickSkinType:(CDVInvokedUrlCommand *)command {
    // fp skintype is available since iOS 9, so we need to check it
    if (![[self sharedHealthStore] respondsToSelector:@selector(fitzpatrickSkinTypeWithError:)]) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"not available on this device"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    HKCharacteristicType *type = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierFitzpatrickSkinType];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:type, nil] completion:^(BOOL success, NSError *error) {
        if (success) {
            HKFitzpatrickSkinTypeObject *skinType = [[self sharedHealthStore] fitzpatrickSkinTypeWithError:&error];
            if (skinType) {
                NSString *skin = @"unknown";
                if (skinType.skinType == HKFitzpatrickSkinTypeI) {
                    skin = @"I";
                } else if (skinType.skinType == HKFitzpatrickSkinTypeII) {
                    skin = @"II";
                } else if (skinType.skinType == HKFitzpatrickSkinTypeIII) {
                    skin = @"III";
                } else if (skinType.skinType == HKFitzpatrickSkinTypeIV) {
                    skin = @"IV";
                } else if (skinType.skinType == HKFitzpatrickSkinTypeV) {
                    skin = @"V";
                } else if (skinType.skinType == HKFitzpatrickSkinTypeVI) {
                    skin = @"VI";
                }
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:skin];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
    }];
}

/**
 * Read blood type datum
 */
- (void)readBloodType:(CDVInvokedUrlCommand *)command {
    HKCharacteristicType *bloodType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:bloodType, nil] completion:^(BOOL success, NSError *error) {
        if (success) {
            HKBloodTypeObject *innerBloodType = [[self sharedHealthStore] bloodTypeWithError:&error];
            if (innerBloodType) {
                NSString *bt = @"unknown";
                if (innerBloodType.bloodType == HKBloodTypeAPositive) {
                    bt = @"A+";
                } else if (innerBloodType.bloodType == HKBloodTypeANegative) {
                    bt = @"A-";
                } else if (innerBloodType.bloodType == HKBloodTypeBPositive) {
                    bt = @"B+";
                } else if (innerBloodType.bloodType == HKBloodTypeBNegative) {
                    bt = @"B-";
                } else if (innerBloodType.bloodType == HKBloodTypeABPositive) {
                    bt = @"AB+";
                } else if (innerBloodType.bloodType == HKBloodTypeABNegative) {
                    bt = @"AB-";
                } else if (innerBloodType.bloodType == HKBloodTypeOPositive) {
                    bt = @"O+";
                } else if (innerBloodType.bloodType == HKBloodTypeONegative) {
                    bt = @"O-";
                }
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:bt];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
    }];
}

/**
 * Read DOB datum
 */
- (void)readDateOfBirth:(CDVInvokedUrlCommand *)command {
    HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:birthdayType, nil] completion:^(BOOL success, NSError *error) {
        if (success) {
            NSDate *dateOfBirth = [[self sharedHealthStore] dateOfBirthWithError:&error];
            if (dateOfBirth) {
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self stringFromDate:dateOfBirth]];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
    }];
}

/**
 * Monitor a specified sample type
 */
- (void)monitorSampleType:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSString *sampleTypeString = args[HKPluginKeySampleType];
    HKSampleType *type = [self getHKSampleType:sampleTypeString];
    HKUpdateFrequency updateFrequency = HKUpdateFrequencyImmediate;
    if (type == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"sampleType was invalid"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    // TODO use this an an anchor for an achored query
    //__block int *anchor = 0;
    NSLog(@"Setting up ObserverQuery");

    HKObserverQuery *query;
    query = [[HKObserverQuery alloc] initWithSampleType:type
                                              predicate:nil
                                          updateHandler:^(HKObserverQuery *observerQuery,
                                                  HKObserverQueryCompletionHandler handler,
                                                  NSError *error) {
                                              if (error) {
                                                  handler();
                                                  dispatch_sync(dispatch_get_main_queue(), ^{
                                                      CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                                                      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                                                  });
                                              } else {
                                                  handler();
                                                  NSLog(@"HealthKit plugin received a monitorSampleType, passing it to JS.");
                                                  // TODO using a anchored qery to return the new and updated values.
                                                  // Until then use querySampleType({limit=1, ascending="T", endDate=new Date()}) to return the last result

                                                  // Issue #47: commented this block since it resulted in callbacks not being delivered while the app was in the background
                                                  //dispatch_sync(dispatch_get_main_queue(), ^{
                                                  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:sampleTypeString];
                                                  [result setKeepCallbackAsBool:YES];
                                                  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                                                  //});
                                              }
                                          }];

    // Make sure we get the updated immediately
    [[self sharedHealthStore] enableBackgroundDeliveryForType:type frequency:updateFrequency withCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"Background devliery enabled %@", sampleTypeString);
        } else {
            NSLog(@"Background delivery not enabled for %@ because of %@", sampleTypeString, error);
        }
        NSLog(@"Executing ObserverQuery");
        [[self sharedHealthStore] executeQuery:query];
        // TODO provide some kind of callback to stop monitoring this value, store the query in some kind of WeakHashSet equilavent?
    }];
};

/**
 * Get the sum of a specified quantity type
 */
- (void)sumQuantityType:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];

    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyStartDate] longValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyEndDate] longValue]];
    NSString *sampleTypeString = args[HKPluginKeySampleType];
    NSString *unitString = args[HKPluginKeyUnit];
    HKQuantityType *type = [HKObjectType quantityTypeForIdentifier:sampleTypeString];


    if (type == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"sampleType was invalid"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    HKStatisticsOptions sumOptions = HKStatisticsOptionCumulativeSum;
    HKStatisticsQuery *query;
    HKUnit *unit = unitString != nil ? [HKUnit unitFromString:unitString] : [HKUnit countUnit];
    query = [[HKStatisticsQuery alloc] initWithQuantityType:type
                                    quantitySamplePredicate:predicate
                                                    options:sumOptions
                                          completionHandler:^(HKStatisticsQuery *statisticsQuery,
                                                  HKStatistics *result,
                                                  NSError *error) {
                                              HKQuantity *sum = [result sumQuantity];
                                              CDVPluginResult *response = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:[sum doubleValueForUnit:unit]];
                                              [self.commandDelegate sendPluginResult:response callbackId:command.callbackId];
                                          }];

    [[self sharedHealthStore] executeQuery:query];
}

/**
 * Query a specified sample type
 */
- (void)querySampleType:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyStartDate] longValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyEndDate] longValue]];
    NSString *sampleTypeString = args[HKPluginKeySampleType];
    NSString *unitString = args[HKPluginKeyUnit];
    NSUInteger limit = args[@"limit"] != nil ? [args[@"limit"] unsignedIntegerValue] : 100;
    BOOL ascending = args[@"ascending"] != nil && [args[@"ascending"] boolValue];

    HKSampleType *type = [self getHKSampleType:sampleTypeString];
    if (type == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"sampleType was invalid"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    HKUnit *unit = nil;
    if (unitString != nil) {
        // issue 51
        // @see https://github.com/Telerik-Verified-Plugins/HealthKit/issues/51
        if ([unitString isEqualToString:@"percent"]) {
            unitString = @"%";
        }
        unit = [HKUnit unitFromString:unitString];
    }
    // TODO check that unit is compatible with sampleType if sample type of HKQuantityType
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];

    NSSet *requestTypes = [NSSet setWithObjects:type, nil];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:nil readTypes:requestTypes completion:^(BOOL success, NSError *error) {
        if (success) {

            NSString *endKey = HKSampleSortIdentifierEndDate;
            NSSortDescriptor *endDateSort = [NSSortDescriptor sortDescriptorWithKey:endKey ascending:ascending];
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:type
                                                                   predicate:predicate
                                                                       limit:limit
                                                             sortDescriptors:@[endDateSort]
                                                              resultsHandler:^(HKSampleQuery *sampleQuery,
                                                                      NSArray *results,
                                                                      NSError *innerError) {
                                                                  if (innerError) {
                                                                      dispatch_sync(dispatch_get_main_queue(), ^{
                                                                          CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:innerError.localizedDescription];
                                                                          [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                                                                      });
                                                                  } else {
                                                                      NSMutableArray *finalResults = [[NSMutableArray alloc] initWithCapacity:results.count];

                                                                      for (HKSample *sample in results) {

                                                                          NSDate *startSample = sample.startDate;
                                                                          NSDate *endSample = sample.endDate;

                                                                          NSMutableDictionary *entry = [
                                                                              @{
                                                                                  HKPluginKeyStartDate: [self stringFromDate:startSample],
                                                                                  HKPluginKeyEndDate: [self stringFromDate:endSample]
                                                                              } mutableCopy];

                                                                          if ([sample isKindOfClass:[HKCategorySample class]]) {
                                                                              HKCategorySample *csample = (HKCategorySample *) sample;
                                                                              [entry setValue:@(csample.value) forKey:HKPluginKeyValue];
                                                                              [entry setValue:csample.categoryType.identifier forKey:@"categoryType.identifier"];
                                                                              [entry setValue:csample.categoryType.description forKey:@"categoryType.description"];
                                                                              [entry setValue:csample.UUID.UUIDString forKey:HKPluginKeyUUID];

                                                                              //@TODO Update deprecated API calls
                                                                              [entry setValue:csample.source.name forKey:HKPluginKeySourceName];
                                                                              [entry setValue:csample.source.bundleIdentifier forKey:HKPluginKeySourceBundleId];

                                                                              [entry setValue:[self stringFromDate:csample.startDate] forKey:HKPluginKeyStartDate];
                                                                              [entry setValue:[self stringFromDate:csample.endDate] forKey:HKPluginKeyEndDate];
                                                                              if (csample.metadata == nil || ![NSJSONSerialization isValidJSONObject:csample.metadata]) {
                                                                                  [entry setValue:@{} forKey:HKPluginKeyMetadata];
                                                                              } else {
                                                                                  [entry setValue:csample.metadata forKey:HKPluginKeyMetadata];
                                                                              }
                                                                          } else if ([sample isKindOfClass:[HKCorrelationType class]]) {
                                                                              HKCorrelation *correlation = (HKCorrelation *) sample;
                                                                              [entry setValue:correlation.correlationType.identifier forKey:HKPluginKeyCorrelationType];
                                                                              if (correlation.metadata == nil || ![NSJSONSerialization isValidJSONObject:correlation.metadata]) {
                                                                                  [entry setValue:@{} forKey:HKPluginKeyMetadata];
                                                                              } else {
                                                                                  [entry setValue:correlation.metadata forKey:HKPluginKeyMetadata];
                                                                              }
                                                                              [entry setValue:correlation.UUID.UUIDString forKey:HKPluginKeyUUID];

                                                                              //@TODO Update deprecated API calls
                                                                              [entry setValue:correlation.source.name forKey:HKPluginKeySourceName];
                                                                              [entry setValue:correlation.source.bundleIdentifier forKey:HKPluginKeySourceBundleId];


                                                                              [entry setValue:[self stringFromDate:correlation.startDate] forKey:HKPluginKeyStartDate];
                                                                              [entry setValue:[self stringFromDate:correlation.endDate] forKey:HKPluginKeyEndDate];
                                                                          } else if ([sample isKindOfClass:[HKQuantitySample class]]) {
                                                                              HKQuantitySample *qsample = (HKQuantitySample *) sample;
                                                                              [entry setValue:@([qsample.quantity doubleValueForUnit:unit]) forKey:@"quantity"];
                                                                              [entry setValue:qsample.UUID.UUIDString forKey:HKPluginKeyUUID];

                                                                              //@TODO Update deprecated API calls
                                                                              [entry setValue:qsample.source.name forKey:HKPluginKeySourceName];
                                                                              [entry setValue:qsample.source.bundleIdentifier forKey:HKPluginKeySourceBundleId];

                                                                              [entry setValue:[self stringFromDate:qsample.startDate] forKey:HKPluginKeyStartDate];
                                                                              [entry setValue:[self stringFromDate:qsample.endDate] forKey:HKPluginKeyEndDate];
                                                                              if (qsample.metadata == nil || ![NSJSONSerialization isValidJSONObject:qsample.metadata]) {
                                                                                  [entry setValue:@{} forKey:HKPluginKeyMetadata];
                                                                              } else {
                                                                                  [entry setValue:qsample.metadata forKey:HKPluginKeyMetadata];
                                                                              }
                                                                          } else if ([sample isKindOfClass:[HKWorkout class]]) {
                                                                              HKWorkout *wsample = (HKWorkout *) sample;
                                                                              [entry setValue:wsample.UUID.UUIDString forKey:HKPluginKeyUUID];

                                                                              //@TODO Update deprecated API calls
                                                                              [entry setValue:wsample.source.name forKey:HKPluginKeySourceName];
                                                                              [entry setValue:wsample.source.bundleIdentifier forKey:HKPluginKeySourceBundleId];

                                                                              [entry setValue:[self stringFromDate:wsample.startDate] forKey:HKPluginKeyStartDate];
                                                                              [entry setValue:[self stringFromDate:wsample.endDate] forKey:HKPluginKeyEndDate];
                                                                              [entry setValue:@(wsample.duration) forKey:@"duration"];
                                                                              if (wsample.metadata == nil || ![NSJSONSerialization isValidJSONObject:wsample.metadata]) {
                                                                                  [entry setValue:@{} forKey:HKPluginKeyMetadata];
                                                                              } else {
                                                                                  [entry setValue:wsample.metadata forKey:HKPluginKeyMetadata];
                                                                              }
                                                                          }

                                                                          [finalResults addObject:entry];
                                                                      }

                                                                      dispatch_sync(dispatch_get_main_queue(), ^{
                                                                          CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
                                                                          [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                                                                      });
                                                                  }
                                                              }];

            [[self sharedHealthStore] executeQuery:query];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];
}

/**
 * Query a specified sample type using an aggregation
 */
- (void)querySampleTypeAggregated:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyStartDate] longValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyEndDate] longValue]];

    NSString *sampleTypeString = args[HKPluginKeySampleType];
    NSString *unitString = args[HKPluginKeyUnit];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *interval = [[NSDateComponents alloc] init];

    NSString *aggregation = args[HKPluginKeyAggregation];
    // TODO would be nice to also have the dev pass in the nr of hours/days/..
    if ([@"hour" isEqualToString:aggregation]) {
        interval.hour = 1;
    } else if ([@"week" isEqualToString:aggregation]) {
        interval.day = 7;
    } else if ([@"month" isEqualToString:aggregation]) {
        interval.month = 1;
    } else if ([@"year" isEqualToString:aggregation]) {
        interval.year = 1;
    } else {
        // default 'day'
        interval.day = 1;
    }

    NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                     fromDate:endDate]; //[NSDate date]];
    anchorComponents.hour = 0; //at 00:00 AM
    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:sampleTypeString];

    // NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    NSPredicate *predicate = nil;

    HKStatisticsOptions statOpt = HKStatisticsOptionNone;


    if (quantityType == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"sampleType was invalid"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    } else if ([sampleTypeString isEqualToString:@"HKQuantityTypeIdentifierHeartRate"]) {
        statOpt = HKStatisticsOptionDiscreteAverage;

    } else { //HKQuantityTypeIdentifierStepCount, etc...
        statOpt = HKStatisticsOptionCumulativeSum;
    }

    HKUnit *unit = nil;
    if (unitString != nil) {
        // issue 51
        if ([unitString isEqualToString:@"percent"]) {
            unitString = @"%";
        }
        unit = [HKUnit unitFromString:unitString];
    }

    HKSampleType *type = [self getHKSampleType:sampleTypeString];
    if (type == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"sampleType was invalid"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    NSSet *requestTypes = [NSSet setWithObjects:type, nil];
    [[self sharedHealthStore] requestAuthorizationToShareTypes:nil readTypes:requestTypes completion:^(BOOL success, NSError *error) {
        if (success) {
            HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                                                                   quantitySamplePredicate:predicate
                                                                                                   options:statOpt
                                                                                                anchorDate:anchorDate
                                                                                        intervalComponents:interval];

            // Set the results handler
            query.initialResultsHandler = ^(HKStatisticsCollectionQuery *statisticsCollectionQuery, HKStatisticsCollection *results, NSError *innerError) {
                if (innerError) {
                    // Perform proper error handling here
                    //                    NSLog(@"*** An error occurred while calculating the statistics: %@ ***",error.localizedDescription);
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:innerError.localizedDescription];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                } else {
                    // Get the daily steps over the past n days
                    //            HKUnit *unit = unitString!=nil ? [HKUnit unitFromString:unitString] : [HKUnit countUnit];
                    NSMutableArray *finalResults = [[NSMutableArray alloc] initWithCapacity:[[results statistics] count]];

                    [results
                            enumerateStatisticsFromDate:startDate
                                                 toDate:endDate
                                              withBlock:^(HKStatistics *result, BOOL *stop) {

                                                  NSDate *valueStartDate = result.startDate;
                                                  NSDate *valueEndDate = result.endDate;

                                                  NSMutableDictionary *entry = [
                                                    @{
                                                        HKPluginKeyStartDate: [self stringFromDate:valueStartDate],
                                                        HKPluginKeyEndDate: [self stringFromDate:valueEndDate]
                                                    } mutableCopy];

                                                  HKQuantity *quantity = nil;
                                                  if (statOpt == HKStatisticsOptionDiscreteAverage) {
                                                      quantity = result.averageQuantity;
                                                  } else if (statOpt == HKStatisticsOptionCumulativeSum) {
                                                      quantity = result.sumQuantity;
                                                  } else {
                                                      quantity = result.maximumQuantity; //don't think is correct. Should never go here
                                                  }
                                                  double value = [quantity doubleValueForUnit:unit];
                                                  [entry setValue:@(value) forKey:@"quantity"];
                                                  [finalResults addObject:entry];
                                              }];

                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    });
                }
            };

            [[self sharedHealthStore] executeQuery:query];


        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];


}

/**
 * Query a specified correlation type
 */
- (void)queryCorrelationType:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyStartDate] longValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyEndDate] longValue]];
    NSString *correlationTypeString = args[HKPluginKeyCorrelationType];
    NSString *unitString = args[HKPluginKeyUnit];

    HKCorrelationType *type = (HKCorrelationType *) [self getHKSampleType:correlationTypeString];
    if (type == nil) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"sampleType was invalid"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    HKUnit *unit = unitString != nil ? [HKUnit unitFromString:unitString] : nil;
    // TODO check that unit is compatible with sampleType if sample type of HKQuantityType
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];

    HKCorrelationQuery *query = [[HKCorrelationQuery alloc] initWithType:type predicate:predicate samplePredicates:nil completion:^(HKCorrelationQuery *correlationQuery, NSArray *correlations, NSError *error) {
        if (error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        } else {
            NSMutableArray *finalResults = [[NSMutableArray alloc] initWithCapacity:correlations.count];
            for (HKSample *sample in correlations) {
                NSDate *startSample = sample.startDate;
                NSDate *endSample = sample.endDate;
                NSMutableDictionary *entry = [
                    @{
                        HKPluginKeyStartDate: [self stringFromDate:startSample],
                        HKPluginKeyEndDate: [self stringFromDate:endSample]
                    } mutableCopy];

                if ([sample isKindOfClass:[HKCategorySample class]]) {
                    HKCategorySample *csample = (HKCategorySample *) sample;
                    [entry setValue:@(csample.value) forKey:HKPluginKeyValue];
                    [entry setValue:csample.categoryType.identifier forKey:@"categoryType.identifier"];
                    [entry setValue:csample.categoryType.description forKey:@"categoryType.description"];
                } else if ([sample isKindOfClass:[HKCorrelation class]]) {
                    HKCorrelation *correlation = (HKCorrelation *) sample;
                    [entry setValue:correlation.correlationType.identifier forKey:HKPluginKeyCorrelationType];
                    // correlation.metadata may contain crap which can't be parsed to valid JSON data
                    if (correlation.metadata == nil || ![NSJSONSerialization isValidJSONObject:correlation.metadata]) {
                        [entry setValue:@{} forKey:HKPluginKeyMetadata];
                    } else {
                        [entry setValue:correlation.metadata forKey:HKPluginKeyMetadata];
                    }
                    [entry setValue:correlation.UUID.UUIDString forKey:HKPluginKeyUUID];
                    NSMutableArray *samples = [NSMutableArray array];
                    for (HKQuantitySample *quantitySample in correlation.objects) {
                        // if an incompatible unit was passed, the sample is not included
                        if ([quantitySample.quantity isCompatibleWithUnit:unit]) {
                            [samples addObject:@{HKPluginKeyStartDate: [self stringFromDate:quantitySample.startDate],
                                    HKPluginKeyEndDate: [self stringFromDate:quantitySample.endDate],
                                    HKPluginKeySampleType: quantitySample.sampleType.identifier,
                                    HKPluginKeyValue: @([quantitySample.quantity doubleValueForUnit:unit]), //
                                    HKPluginKeyUnit: unit.unitString,
                                    HKPluginKeyMetadata: quantitySample.metadata != nil ? quantitySample.metadata : @{},
                                    HKPluginKeyUUID: quantitySample.UUID.UUIDString}];
                        }
                    }
                    [entry setValue:samples forKey:HKPluginKeyObjects];
                    // TODO
                } else if ([sample isKindOfClass:[HKQuantitySample class]]) {
                    HKQuantitySample *qsample = (HKQuantitySample *) sample;
                    // TODO compare with unit
                    [entry setValue:@([qsample.quantity doubleValueForUnit:unit]) forKey:@"quantity"];

                } else if ([sample isKindOfClass:[HKCorrelationType class]]) {
                    // TODO
                } else if ([sample isKindOfClass:[HKWorkout class]]) {
                    HKWorkout *wsample = (HKWorkout *) sample;
                    [entry setValue:@(wsample.duration) forKey:@"duration"];
                }

                [finalResults addObject:entry];
            }

            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];
    [[self sharedHealthStore] executeQuery:query];
}

/**
 * Save a quantity sample datum
 */
- (void)saveQuantitySample:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];

    //Use helper method to create quantity sample
    NSError *error = nil;
    HKQuantitySample *sample = [self loadHKQuantitySampleFromInputDictionary:args error:&error];

    //If error in creation, return plugin result
    if (error) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    //Otherwise save to health store
    [[self sharedHealthStore] saveObject:sample withCompletion:^(BOOL success, NSError *innerError) {
        if (success) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:innerError.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];

}

/**
 * Save correlation datum
 */
- (void)saveCorrelation:(CDVInvokedUrlCommand *)command {
    NSMutableDictionary *args = command.arguments[0];
    NSError *error = nil;

    //Use helper method to create correlation
    HKCorrelation *correlation = [self loadHKCorrelationFromInputDictionary:args error:&error];

    //If error in creation, return plugin result
    if (error) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    //Otherwise save to health store
    [[self sharedHealthStore] saveObject:correlation withCompletion:^(BOOL success, NSError *saveError) {
        if (success) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:saveError.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            });
        }
    }];
}

/**
 * Delete a specified object from teh HealthKit store
 * @TODO implement me
 */
- (void)deleteObject:(CDVInvokedUrlCommand *)command {
    //NSMutableDictionary *args = command.arguments[0];

    // TODO see the 3 methods at https://developer.apple.com/library/ios/documentation/HealthKit/Reference/HKHealthStore_Class/#//apple_ref/occ/instm/HKHealthStore/deleteObject:withCompletion:

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

@end
