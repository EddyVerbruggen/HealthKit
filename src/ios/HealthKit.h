#import "Cordova/CDV.h"
#import <HealthKit/HealthKit.h>

#pragma mark Property Type Constants
static NSString *const HKPluginError = @"HKPluginError";
static NSString *const HKPluginKeyReadTypes = @"readTypes";
static NSString *const HKPluginKeyWriteTypes = @"writeTypes";
static NSString *const HKPluginKeyType = @"type";
static NSString *const HKPluginKeyStartDate = @"startDate";
static NSString *const HKPluginKeyEndDate = @"endDate";
static NSString *const HKPluginKeySampleType = @"sampleType";
static NSString *const HKPluginKeyAggregation = @"aggregation";
static NSString *const HKPluginKeyUnit = @"unit";
static NSString *const HKPluginKeyAmount = @"amount";
static NSString *const HKPluginKeyValue = @"value";
static NSString *const HKPluginKeyCorrelationType = @"correlationType";
static NSString *const HKPluginKeyObjects = @"samples";
static NSString *const HKPluginKeySourceName = @"sourceName";
static NSString *const HKPluginKeySourceBundleId = @"sourceBundleId";
static NSString *const HKPluginKeyMetadata = @"metadata";
static NSString *const HKPluginKeyUUID = @"UUID";

@interface HealthKit :CDVPlugin

/**
 * Tell delegate whether or not health data is available
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) available:(CDVInvokedUrlCommand*)command;

/**
 * Check the authorization status for a specified permission
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) checkAuthStatus:(CDVInvokedUrlCommand*)command;

/**
 * Request authorization for read and/or write permissions
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) requestAuthorization:(CDVInvokedUrlCommand*)command;

/**
 * Read gender data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) readGender:(CDVInvokedUrlCommand*)command;

/**
 * Read blood type data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) readBloodType:(CDVInvokedUrlCommand*)command;

/**
 * Read date of birth data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) readDateOfBirth:(CDVInvokedUrlCommand*)command;

/**
 * Read Fitzpatrick Skin Type Data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) readFitzpatrickSkinType:(CDVInvokedUrlCommand*)command;

/**
 * Save weight data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) saveWeight:(CDVInvokedUrlCommand*)command;

/**
 * Read weight data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) readWeight:(CDVInvokedUrlCommand*)command;

/**
 * Save height data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) saveHeight:(CDVInvokedUrlCommand*)command;

/**
 * Read height data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) readHeight:(CDVInvokedUrlCommand*)command;

/**
 * Save workout data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) saveWorkout:(CDVInvokedUrlCommand*)command;

/**
 * Find workout data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) findWorkouts:(CDVInvokedUrlCommand*)command;

/**
 * Monitor a specified sample type
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) monitorSampleType:(CDVInvokedUrlCommand*)command;

/**
 * Get the sum of a specified quantity type
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) sumQuantityType:(CDVInvokedUrlCommand*)command;

/**
 * Query a specified sample type
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) querySampleType:(CDVInvokedUrlCommand*)command;

/**
 * Query a specified sample type using an aggregation
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) querySampleTypeAggregated:(CDVInvokedUrlCommand*)command;

/**
 * Query a specified clinical sample type
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) queryClinicalSampleType:(CDVInvokedUrlCommand *)command;

/**
 * Search for a particular FHIR record
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) queryForClinicalRecordsFromSource:(CDVInvokedUrlCommand *)command;

/**
 * Search for a specific FHIR resource type
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) queryForClinicalRecordsWithFHIRResourceType:(CDVInvokedUrlCommand *)command;

/**
 * Save quantity sample data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) saveQuantitySample:(CDVInvokedUrlCommand*)command;

/**
 * Save correlation data
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) saveCorrelation:(CDVInvokedUrlCommand*)command;

/**
 * Query a specified correlation type
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) queryCorrelationType:(CDVInvokedUrlCommand*)command;

/**
 * Delete matching samples from the HealthKit store
 *
 * @param command *CDVInvokedUrlCommand
 */
- (void) deleteSamples:(CDVInvokedUrlCommand*)command;

@end

// Public Interface extension category
@interface HealthKit ()
+ (HKHealthStore *)sharedHealthStore;
@end

// Internal interface
@interface HealthKit (Internal)
- (void)checkAuthStatusWithCallbackId:(NSString *)callbackId
                              forType:(HKObjectType *)type
                        andCompletion:(void (^)(CDVPluginResult *result, NSString *innerCallbackId))completion;
@end


// Internal interface helper methods
@interface HealthKit (InternalHelpers)
+ (NSString *)stringFromDate:(NSDate *)date;

+ (HKUnit *)getUnit:(NSString *)type expected:(NSString *)expected;

+ (HKObjectType *)getHKObjectType:(NSString *)elem;

+ (HKQuantityType *)getHKQuantityType:(NSString *)elem;

+ (HKSampleType *)getHKSampleType:(NSString *)elem;

- (HKQuantitySample *)loadHKQuantitySampleFromInputDictionary:(NSDictionary *)inputDictionary error:(NSError **)error;

- (HKCorrelation *)loadHKCorrelationFromInputDictionary:(NSDictionary *)inputDictionary error:(NSError **)error;

+ (HKQuantitySample *)getHKQuantitySampleWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate sampleTypeString:(NSString *)sampleTypeString unitTypeString:(NSString *)unitTypeString value:(double)value metadata:(NSDictionary *)metadata error:(NSError **)error;

- (HKCorrelation *)getHKCorrelationWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate correlationTypeString:(NSString *)correlationTypeString objects:(NSSet *)objects metadata:(NSDictionary *)metadata error:(NSError **)error;

+ (void)triggerErrorCallbackWithMessage: (NSString *) message command: (CDVInvokedUrlCommand *) command delegate: (id<CDVCommandDelegate>) delegate;
@end

// NSDictionary check if there is a value for a required key and populate an error if not present
@interface NSDictionary (RequiredKey)
- (BOOL)hasAllRequiredKeys:(NSArray<NSString *> *)keys error:(NSError **)error;
@end
