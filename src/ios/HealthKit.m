#import "HealthKit.h"
#import "HKHealthStore+AAPLExtensions.h"
#import <Cordova/CDV.h>

@implementation HealthKit

- (CDVPlugin*) initWithWebView:(UIWebView*)theWebView {
  self = (HealthKit*)[super initWithWebView:theWebView];
  if (self) {
    _healthStore = [HKHealthStore new];
  }
  return self;
}

- (void) available:(CDVInvokedUrlCommand*)command {
  CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[HKHealthStore isHealthDataAvailable]];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) requestAuthorization:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];
  
  // read types
  NSArray *readTypes = [args objectForKey:@"readTypes"];
  NSSet *readDataTypes = [[NSSet alloc] init];
  for (int i=0; i<[readTypes count]; i++) {
    NSString *elem = [readTypes objectAtIndex:i];
    HKObjectType *type = [self getHKObjectType:elem];
    if (type == nil) {
      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"readTypes contains an invalid value"];
      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      // not returning deliberately to be future proof; other permissions are still asked
    } else {
      readDataTypes = [readDataTypes setByAddingObject:type];
    }
  }

  // write types
  NSArray *writeTypes = [args objectForKey:@"writeTypes"];
  NSSet *writeDataTypes = [[NSSet alloc] init];
  for (int i=0; i<[writeTypes count]; i++) {
    NSString *elem = [writeTypes objectAtIndex:i];
    HKObjectType *type = [self getHKObjectType:elem];
    if (type == nil) {
      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"writeTypes contains an invalid value"];
      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      // not returning deliberately to be future proof; other permissions are still asked
    } else {
      writeDataTypes = [writeDataTypes setByAddingObject:type];
    }
  }

  [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
    if (success) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
          [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    }
  }];
}

- (void) checkAuthStatus:(CDVInvokedUrlCommand*)command {
  // TODO method to check this: HKAuthorizationStatus status = [self.healthStore authorizationStatusForType:<the type>];
  // if status = denied, prompt user to go to settings
}

- (void) saveWorkout:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];

  NSString *activityType = [args objectForKey:@"activityType"];
  NSString *quantityType = [args objectForKey:@"quantityType"]; // TODO verify this value
  
  // TODO check validity of this enum
  //  HKWorkoutActivityType activityTypeEnum = HKWorkoutActivityTypeCycling;
  HKWorkoutActivityType activityTypeEnum = (HKWorkoutActivityType) activityType;
  

  // optional energy
  NSNumber *energy = [args objectForKey:@"energy"];
  NSString *energyUnit = [args objectForKey:@"energyUnit"];
  HKQuantity *nrOfEnergyUnits = nil;
  if (energy != nil) {
    HKUnit *preferredEnergyUnit = [self getUnit:energyUnit:@"HKEnergyUnit"];
    if (preferredEnergyUnit == nil) {
      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid energyUnit was passed"];
      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      return;
    }
    nrOfEnergyUnits = [HKQuantity quantityWithUnit:preferredEnergyUnit doubleValue:energy.doubleValue];
  }
  
  // optional distance
  NSNumber *distance = [args objectForKey:@"distance"];
  NSString *distanceUnit = [args objectForKey:@"distanceUnit"];
  HKQuantity *nrOfDistanceUnits = nil;
  if (distance != nil) {
    HKUnit *preferredDistanceUnit = [self getUnit:distanceUnit:@"HKLengthUnit"];
    if (preferredDistanceUnit == nil) {
      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid distanceUnit was passed"];
      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      return;
    }
    nrOfDistanceUnits = [HKQuantity quantityWithUnit:preferredDistanceUnit doubleValue:distance.doubleValue];
  }

  int duration = 0;
  NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[[args objectForKey:@"startDate"] doubleValue]];


  NSDate *endDate;
  if ([args objectForKey:@"duration"]) {
    duration = [[args objectForKey:@"duration"] intValue];
    endDate = [NSDate dateWithTimeIntervalSince1970:startDate.timeIntervalSince1970 + duration];
  } else if ([args objectForKey:@"endDate"]) {
    endDate = [NSDate dateWithTimeIntervalSince1970:[[args objectForKey:@"endDate"] doubleValue]];
  } else {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no duration or endDate was set"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }


  NSSet *types = [NSSet setWithObjects:[HKWorkoutType workoutType], [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned], [HKQuantityType quantityTypeForIdentifier:quantityType], nil];
  [self.healthStore requestAuthorizationToShareTypes:types readTypes:nil completion:^(BOOL success, NSError *error) {
    if (!success) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
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
      [self.healthStore saveObject:workout withCompletion:^(BOOL success, NSError *innerError) {
        if (success) {
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
            NSArray *samples = [NSArray arrayWithObjects:sampleActivity, sampleCalories, nil];
          
            [self.healthStore addSamples:samples toWorkout:workout completion:^(BOOL success, NSError *mostInnerError) {
              if (success) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                  CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                });
              } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                  CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR  messageAsString:mostInnerError.localizedDescription];
                  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                });
              }
            }];
          }
        } else {
          dispatch_sync(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:innerError.localizedDescription];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        }
      }];
    }
  }];
}

- (void) findWorkouts:(CDVInvokedUrlCommand*)command {
  NSPredicate *workoutPredicate = nil;
  // TODO if a specific workouttype was passed, use that
  if (false) {
    workoutPredicate = [HKQuery predicateForWorkoutsWithWorkoutActivityType:HKWorkoutActivityTypeCycling];
  }
  HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:[HKWorkoutType workoutType] predicate:workoutPredicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
    if (error) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    } else {
      NSDateFormatter *df = [[NSDateFormatter alloc] init];
      [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

      NSMutableArray *finalResults = [[NSMutableArray alloc] initWithCapacity:results.count];

      for (HKWorkout *workout in results) {
        NSMutableDictionary *entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      [NSNumber numberWithDouble:workout.duration], @"duration",
                                      [df stringFromDate:workout.startDate], @"startDate",
                                      [df stringFromDate:workout.endDate], @"endDate",
                                      nil];

        [finalResults addObject:entry];
      }
      
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    }
  }];
  [self.healthStore executeQuery:query];
}

/*
- (void) addSamplesToWorkout:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];

  NSDate *start = [NSDate date]; // TODO pass in
  NSDate *end = [NSDate date]; // TODO pass in
  
  // TODO pass in workoutactivity
  HKWorkout *workout = [HKWorkout workoutWithActivityType:HKWorkoutActivityTypeRunning
                                                startDate:start
                                                  endDate:end];
  NSArray *samples = [NSArray init];
  
  [self.healthStore addSamples:samples toWorkout:workout completion:^(BOOL success, NSError *error) {
    if (success) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    }
  }];
}
 */

- (void) saveWeight:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];
  NSString *unit = [args objectForKey:@"unit"];
  NSNumber *amount = [args objectForKey:@"amount"];
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[args objectForKey:@"date"] doubleValue]];


  if (amount == nil) {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no amount was set"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }
  
  HKUnit *preferredUnit = [self getUnit:unit:@"HKMassUnit"];
  if (preferredUnit == nil) {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid unit was passed"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }

  HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
  NSSet *requestTypes = [NSSet setWithObjects: weightType, nil];
  [self.healthStore requestAuthorizationToShareTypes:requestTypes readTypes:requestTypes completion:^(BOOL success, NSError *error) {
    if (success) {
      HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:preferredUnit doubleValue:[amount doubleValue]];
      HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:date endDate:date];
      [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError* errorInner) {
        if (success) {
          dispatch_sync(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        } else {
          dispatch_sync(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInner.localizedDescription];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        }
      }];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    }
  }];
}

// TODO do we get back a date? Yes, see aapl_mostRecentQuantitySampleOfType
- (void) readWeight:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];
  NSString *unit = [args objectForKey:@"unit"];
  
  HKUnit *preferredUnit = [self getUnit:unit:@"HKMassUnit"];
  if (preferredUnit == nil) {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid unit was passed"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }

  // Query to get the user's latest weight, if it exists.
  HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
  NSSet *requestTypes = [NSSet setWithObjects: weightType, nil];
  // always ask for read and write permission if the app uses both, because granting read will remove write for the same type :(
  [self.healthStore requestAuthorizationToShareTypes:requestTypes readTypes:requestTypes completion:^(BOOL success, NSError *error) {
    if (success) {
      [self.healthStore aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSDate *mostRecentDate, NSError *errorInner) {
        if (mostRecentQuantity) {
          double usersWeight = [mostRecentQuantity doubleValueForUnit:preferredUnit];
          NSDateFormatter *df = [[NSDateFormatter alloc] init];
          [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
          NSMutableDictionary *entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        [NSNumber numberWithDouble:usersWeight], @"value",
                                        unit, @"unit",
                                        [df stringFromDate:mostRecentDate], @"date",
                                        nil];
          dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:entry];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInner.localizedDescription];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        }
      }];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    }
  }];
}


- (void) saveHeight:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];
  NSString *unit = [args objectForKey:@"unit"];
  NSNumber *amount = [args objectForKey:@"amount"];
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[args objectForKey:@"date"] doubleValue]];
  
  
  if (amount == nil) {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no amount was set"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }
  
  HKUnit *preferredUnit = [self getUnit:unit:@"HKLengthUnit"];
  if (preferredUnit == nil) {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid unit was passed"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }
  
  HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
  NSSet *requestTypes = [NSSet setWithObjects: heightType, nil];
  [self.healthStore requestAuthorizationToShareTypes:requestTypes readTypes:requestTypes completion:^(BOOL success, NSError *error) {
    if (success) {
      HKQuantity *heightQuantity = [HKQuantity quantityWithUnit:preferredUnit doubleValue:[amount doubleValue]];
      HKQuantitySample *heightSample = [HKQuantitySample quantitySampleWithType:heightType quantity:heightQuantity startDate:date endDate:date];
      [self.healthStore saveObject:heightSample withCompletion:^(BOOL success, NSError* errorInner) {
        if (success) {
          dispatch_sync(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        } else {
          dispatch_sync(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInner.localizedDescription];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        }
      }];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    }
  }];
}


- (void) readHeight:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];
  NSString *unit = [args objectForKey:@"unit"];
  
  HKUnit *preferredUnit = [self getUnit:unit:@"HKLengthUnit"];
  if (preferredUnit == nil) {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"invalid unit was passed"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }
  
  // Query to get the user's latest height, if it exists.
  HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
  NSSet *requestTypes = [NSSet setWithObjects: heightType, nil];
  // always ask for read and write permission if the app uses both, because granting read will remove write for the same type :(
  [self.healthStore requestAuthorizationToShareTypes:requestTypes readTypes:requestTypes completion:^(BOOL success, NSError *error) {
    if (success) {
      [self.healthStore aapl_mostRecentQuantitySampleOfType:heightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSDate *mostRecentDate, NSError *errorInner) { // TODO use
        if (mostRecentQuantity) {
          double usersHeight = [mostRecentQuantity doubleValueForUnit:preferredUnit];
          NSDateFormatter *df = [[NSDateFormatter alloc] init];
          [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
          NSMutableDictionary *entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        [NSNumber numberWithDouble:usersHeight], @"value",
                                        unit, @"unit",
                                        [df stringFromDate:mostRecentDate], @"date",
                                        nil];
          dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:entry];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInner.localizedDescription];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
          });
        }
      }];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      });
    }
  }];
}

- (void) readGender:(CDVInvokedUrlCommand*)command {
  HKCharacteristicType *genderType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
  [self.healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects: genderType, nil] completion:^(BOOL success, NSError *error) {
    if (success) {
      HKBiologicalSexObject *sex = [self.healthStore biologicalSexWithError:&error];
      if (sex) {
        NSString* gender = @"unknown";
        if (sex.biologicalSex == HKBiologicalSexMale) {
          gender = @"male";
        } else if (sex.biologicalSex == HKBiologicalSexFemale) {
          gender = @"female";
        }
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:gender];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      }
    }
  }];
}

- (void) readDateOfBirth:(CDVInvokedUrlCommand*)command {
  // TODO pass in dateformat?
  NSDateFormatter *df = [[NSDateFormatter alloc] init];
  [df setDateFormat:@"yyyy-MM-dd"];
  HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
  [self.healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects: birthdayType, nil] completion:^(BOOL success, NSError *error) {
    if (success) {
      NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
      if (dateOfBirth) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[df stringFromDate:dateOfBirth]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      }
    }
  }];
}

#pragma mark - helper methods
- (HKUnit*) getUnit:(NSString*) type : (NSString*) expected {
  HKUnit *localUnit;
  @try {
    localUnit = [HKUnit unitFromString:type];
    if ([[[localUnit class] description] isEqualToString:expected]) {
      return localUnit;
    } else {
      return nil;
    }
  }
  @catch(NSException *e) {
    return nil;
  }
}

- (HKObjectType*) getHKObjectType:(NSString*) elem {
  HKObjectType *type = [HKObjectType quantityTypeForIdentifier:elem];
  if (type == nil) {
    type = [HKObjectType characteristicTypeForIdentifier:elem];
  }
  if (type == nil) {
    type = [HKObjectType categoryTypeForIdentifier:elem];
  }
  if (type == nil) {
    type = [HKObjectType categoryTypeForIdentifier:elem];
  }
  if (type == nil) {
    type = [HKObjectType correlationTypeForIdentifier:elem];
  }
  if (type == nil && [elem isEqualToString:@"workoutType"]) {
    type = [HKObjectType workoutType];
  }
  return type;
}

/*
#pragma mark - HealthKit Permissions

// Returns the types of data that this app wishes to write to HealthKit.
- (NSSet *)dataTypesToWrite {
  HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
  HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
 
  return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, nil];
}

// Returns the types of data that this app wishes to read from HealthKit.
- (NSSet *)dataTypesToRead {
  HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
  HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
 
  return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalSexType, nil];
}
*/

@end