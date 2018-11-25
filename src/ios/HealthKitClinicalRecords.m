//
//  HealthKitClinicalRecords.m
//
//  Created by Ross Martin
//

#import "HealthKit.h"
#import "HealthKitClinicalRecords.h"


@implementation HealthKitClinicalRecords

/**
 * Query a specified clinical sample type
 *
 * @param command *CDVInvokedUrlCommand
 * @param delegate (id<CDVCommandDelegate>)
 */
+ (void)queryClinicalSampleType:(CDVInvokedUrlCommand *)command delegate: (id<CDVCommandDelegate>) delegate {
  if (@available(iOS 12.0, *)) {
    NSDictionary *args = command.arguments[0];
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyStartDate] longValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[args[HKPluginKeyEndDate] longValue]];
    NSString *sampleTypeString = args[HKPluginKeySampleType];
    NSUInteger limit = ((args[@"limit"] != nil) ? [args[@"limit"] unsignedIntegerValue] : 100);
    BOOL ascending = (args[@"ascending"] != nil && [args[@"ascending"] boolValue]);
    
    HKSampleType *type = [HKObjectType clinicalTypeForIdentifier:sampleTypeString];
    if (type == nil) {
      [HealthKit triggerErrorCallbackWithMessage:@"sampleType was invalid" command:command delegate:delegate];
      return;
    }
    // TODO check that unit is compatible with sampleType if sample type of HKQuantityType
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    NSSet *requestTypes = [NSSet setWithObjects:type, nil];
    [[HealthKit sharedHealthStore] requestAuthorizationToShareTypes:nil readTypes:requestTypes completion:^(BOOL success, NSError *error) {
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
                                              if (innerError != nil) {
                                                dispatch_sync(dispatch_get_main_queue(), ^{
                                                  [HealthKit triggerErrorCallbackWithMessage:innerError.localizedDescription command:command delegate:delegate];
                                                });
                                              } else {
                                                dispatch_sync(dispatch_get_main_queue(), ^{
                                                  [self returnClinicalResultsFromQuery:results command:command delegate:delegate];
                                                });
                                              }
                                           }];
        
        [[HealthKit sharedHealthStore] executeQuery:query];
      } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
          [HealthKit triggerErrorCallbackWithMessage:error.localizedDescription command:command delegate:delegate];
        });
      }
    }];
  } else {
    [HealthKit triggerErrorCallbackWithMessage:@"queryClinicalSampleType requires ios 12 or higher" command:command delegate:delegate];
  }
}

/**
 * Search for a particular FHIR record
 *
 * @param command *CDVInvokedUrlCommand
 * @param delegate (id<CDVCommandDelegate>)
 */
+ (void)queryForClinicalRecordsFromSource:(CDVInvokedUrlCommand *) command delegate: (id<CDVCommandDelegate>) delegate {
  if (@available(iOS 12.0, *)) {
    NSDictionary *args = command.arguments[0];
    
    NSString *sampleTypeString = args[HKPluginKeySampleType];
    HKSampleType *sampleType = [HKObjectType clinicalTypeForIdentifier:sampleTypeString];
    NSString *fhirResourceTypeString = args[@"fhirResourceType"];
    HKFHIRResourceType fhirResourceType = [self getFHIRResourceType:fhirResourceTypeString];
    NSString *sourceName = [args valueForKeyPath:@"source.name"];
    NSString *bundleIdentifier = [args valueForKeyPath:@"source.bundleIdentifier"];
    NSString *identifier = args[@"identifier"];
    
    if (sampleType == nil) {
      [HealthKit triggerErrorCallbackWithMessage:@"sampleType was invalid" command:command delegate:delegate];
      return;
    }
    
    if (fhirResourceType == nil) {
      [HealthKit triggerErrorCallbackWithMessage:@"fhirResourceType was invalid" command:command delegate:delegate];
    }
    
    HKSourceQuery *sourceQuery = [[HKSourceQuery alloc] initWithSampleType:sampleType
                                               samplePredicate:nil
                                               completionHandler:^(HKSourceQuery * _Nonnull query, NSSet<HKSource *> * _Nullable sources, NSError * _Nullable error) {
                                                 if (error) {
                                                   [HealthKit triggerErrorCallbackWithMessage:error.localizedDescription command:command delegate:delegate];
                                                   return;
                                                 }
                                                 
                                                 HKSource *fromSource = nil;
                                                 
                                                 for (HKSource *source in sources) {
                                                   if ([source.name isEqualToString:sourceName] && [source.bundleIdentifier isEqualToString:bundleIdentifier]) {
                                                     fromSource = source;
                                                     break;
                                                   }
                                                 }
                                                 
                                                 if (fromSource == nil) {
                                                   [HealthKit triggerErrorCallbackWithMessage:@"Unable to obtain source by name and bundleIdentifier" command:command delegate:delegate];
                                                   return;
                                                 }
                                                 
                                                 NSPredicate *predicate = [HKQuery predicateForClinicalRecordsFromSource:fromSource FHIRResourceType:fhirResourceType identifier:identifier];
                                                 
                                                 HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                    predicate:predicate
                                                    limit:HKObjectQueryNoLimit
                                                    sortDescriptors:nil
                                                    resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                                                     if (error != nil) {
                                                       dispatch_sync(dispatch_get_main_queue(), ^{
                                                         [HealthKit triggerErrorCallbackWithMessage:error.localizedDescription command:command delegate:delegate];
                                                       });
                                                     } else {
                                                       dispatch_sync(dispatch_get_main_queue(), ^{
                                                         [self returnClinicalResultsFromQuery:results command:command delegate:delegate];
                                                       });
                                                     }
                                                 }];
                                                 
                                                 [[HealthKit sharedHealthStore] executeQuery:sampleQuery];
                                               }];
    
    [[HealthKit sharedHealthStore] executeQuery:sourceQuery];
  } else {
    [HealthKit triggerErrorCallbackWithMessage:@"queryForClinicalRecordsFromSource requires ios 12 or higher" command:command delegate:delegate];
  }
}

/**
 * Search for a specific FHIR resource type
 *
 * @param command *CDVInvokedUrlCommand
 * @param delegate (id<CDVCommandDelegate>)
 */
+ (void)queryForClinicalRecordsWithFHIRResourceType:(CDVInvokedUrlCommand *)command delegate: (id<CDVCommandDelegate>) delegate {
  if (@available(iOS 12.0, *)) {
    NSDictionary *args = command.arguments[0];
    
    NSString *sampleTypeString = args[HKPluginKeySampleType];
    HKSampleType *sampleType = [HKObjectType clinicalTypeForIdentifier:sampleTypeString];
    NSString *fhirResourceTypeString = args[@"fhirResourceType"];
    HKFHIRResourceType fhirResourceType = [self getFHIRResourceType:fhirResourceTypeString];
    
    if (sampleType == nil) {
      [HealthKit triggerErrorCallbackWithMessage:@"sampleType was invalid" command:command delegate:delegate];
      return;
    }
    
    if (fhirResourceType == nil) {
      [HealthKit triggerErrorCallbackWithMessage:@"fhirResourceType was invalid" command:command delegate:delegate];
    }
    
    NSPredicate *predicate = [HKQuery predicateForClinicalRecordsWithFHIRResourceType:fhirResourceType];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                       predicate:predicate
                                       limit:HKObjectQueryNoLimit
                                       sortDescriptors:nil
                                       resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                                          if (error != nil) {
                                            dispatch_sync(dispatch_get_main_queue(), ^{
                                              [HealthKit triggerErrorCallbackWithMessage:error.localizedDescription command:command delegate:delegate];
                                            });
                                          } else {
                                            dispatch_sync(dispatch_get_main_queue(), ^{
                                              [self returnClinicalResultsFromQuery:results command:command delegate:delegate];
                                            });
                                          }
                                        }];

    [[HealthKit sharedHealthStore] executeQuery:query];
  } else {
    [HealthKit triggerErrorCallbackWithMessage:@"queryForClinicalRecordsWithFHIRResourceType requires ios 12 or higher" command:command delegate:delegate];
  }
}

/**
 * Get a FHIR Resource Type constant by name
 *
 * @param elem  *NSString
 * @return      *HKFHIRResourceType
 */
+ (HKFHIRResourceType)getFHIRResourceType:(NSString *)elem  API_AVAILABLE(ios(12.0)) {
  if (@available(iOS 12.0, *)) {
    HKFHIRResourceType type = nil;
    NSDictionary *fhirResourceTypeMap = @{
                                      @"HKFHIRResourceTypeAllergyIntolerance": HKFHIRResourceTypeAllergyIntolerance,
                                      @"HKFHIRResourceTypeCondition": HKFHIRResourceTypeCondition,
                                      @"HKFHIRResourceTypeImmunization": HKFHIRResourceTypeImmunization,
                                      @"HKFHIRResourceTypeMedicationDispense": HKFHIRResourceTypeMedicationDispense,
                                      @"HKFHIRResourceTypeMedicationOrder": HKFHIRResourceTypeMedicationOrder,
                                      @"HKFHIRResourceTypeMedicationStatement": HKFHIRResourceTypeMedicationStatement,
                                      @"HKFHIRResourceTypeObservation": HKFHIRResourceTypeObservation,
                                      @"HKFHIRResourceTypeProcedure": HKFHIRResourceTypeProcedure
                                    };
    
    type = fhirResourceTypeMap[elem];
    
    return type;
  }
  
  return nil;
}

/**
 * Generic output for clinical results
 *
 * @param message   *NSString
 * @param command   *CDVInvokedUrlCommand
 * @param delegate  id<CDVCommandDelegate>
 */

+ (void)returnClinicalResultsFromQuery: (NSArray *)results  command: (CDVInvokedUrlCommand *) command delegate: (id<CDVCommandDelegate>) delegate {
  @autoreleasepool {
    if (@available(iOS 12.0, *)) {
      NSMutableArray *finalResults = [[NSMutableArray alloc] initWithCapacity:results.count];
      
      for (HKSample *sample in results) {
        
        NSDate *startSample = sample.startDate;
        NSDate *endSample = sample.endDate;
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        
        // common indices
        entry[HKPluginKeyStartDate] =[HealthKit stringFromDate:startSample];
        entry[HKPluginKeyEndDate] = [HealthKit stringFromDate:endSample];
        entry[HKPluginKeyUUID] = sample.UUID.UUIDString;
        
        entry[HKPluginKeySourceName] = sample.sourceRevision.source.name;
        entry[HKPluginKeySourceBundleId] = sample.sourceRevision.source.bundleIdentifier;
        
        if (sample.metadata == nil || ![NSJSONSerialization isValidJSONObject:sample.metadata]) {
          entry[HKPluginKeyMetadata] = @{};
        } else {
          entry[HKPluginKeyMetadata] = sample.metadata;
        }
        
        if ([sample isKindOfClass:[HKClinicalRecord class]]) {
          HKClinicalRecord *clinicalRecord = (HKClinicalRecord *) sample;
          NSError *err = nil;
          NSDictionary *fhirData = [NSJSONSerialization JSONObjectWithData:clinicalRecord.FHIRResource.data options:NSJSONReadingMutableContainers error:&err];
          
          if (err != nil) {
            [HealthKit triggerErrorCallbackWithMessage:err.localizedDescription command:command delegate:delegate];
            return;
          } else {
            NSDictionary *fhirResource = @{
                                       @"identifier": clinicalRecord.FHIRResource.identifier,
                                       @"sourceURL": clinicalRecord.FHIRResource.sourceURL.absoluteString,
                                       @"displayName": clinicalRecord.displayName,
                                       @"data": fhirData
                                     };
            entry[@"FHIRResource"] = fhirResource;
          }
        }
        
        [finalResults addObject:entry];
      }
      
      CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
      [delegate sendPluginResult:result callbackId:command.callbackId];
    }
  }
}
  
@end
