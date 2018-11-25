//
//  HealthKitClinicalRecords.h
//
//  Created by Ross Martin
//


@interface HealthKitClinicalRecords : NSObject

/**
 * Query a specified clinical sample type
 *
 * @param command *CDVInvokedUrlCommand
 * @param delegate (id<CDVCommandDelegate>)
 */
+ (void)queryClinicalSampleType:(CDVInvokedUrlCommand *)command delegate: (id<CDVCommandDelegate>) delegate;

/**
 * Search for a particular FHIR record
 *
 * @param command *CDVInvokedUrlCommand
 * @param delegate (id<CDVCommandDelegate>)
 */
+ (void)queryForClinicalRecordsFromSource:(CDVInvokedUrlCommand *)command delegate: (id<CDVCommandDelegate>) delegate;

/**
 * Search for a specific FHIR resource type
 *
 * @param command *CDVInvokedUrlCommand
 * @param delegate (id<CDVCommandDelegate>)
 */
+ (void)queryForClinicalRecordsWithFHIRResourceType:(CDVInvokedUrlCommand *)command delegate: (id<CDVCommandDelegate>) delegate;

@end

