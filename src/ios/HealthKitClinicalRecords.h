//
//  HealthKitClinicalRecords.h
//
//  Created by Ross Martin
//

#ifndef HealthKitClinicalRecords_h
#define HealthKitClinicalRecords_h

#endif /* HealthKitClinicalRecords_h */


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

