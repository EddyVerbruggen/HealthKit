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

/*
- (void) requestPermission:(CDVInvokedUrlCommand*)command {
  NSString *callbackId = command.callbackId;
  
  if ([HKHealthStore isHealthDataAvailable]) {
    NSSet *writeDataTypes = [self dataTypesToWrite];
    NSSet *readDataTypes = [self dataTypesToRead];
  
    // TODO this should be an internal method, or allow passing in stuff for advanced users
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
  } else {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"healthkit not available"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
  }
}
*/

- (void) checkAuthStatus:(CDVInvokedUrlCommand*)command {
  // TODO method to check this: HKAuthorizationStatus status = [self.healthStore authorizationStatusForType:<the type>];
  // if status = denied, prompt user to go to settings
}

- (void) saveWorkout:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];
  NSString *activityType = [args objectForKey:@"activityType"];

  HKWorkoutActivityType activityTypeEnum = (HKWorkoutActivityType) activityType;
  // TODO check validity of enum
  
  int duration = 0;

  NSNumber* startTime  = [args objectForKey:@"startTime"];
  NSTimeInterval _startInterval = [startTime doubleValue] / 1000; // strip millis
  NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:_startInterval];

  NSDate *endDate;
  if ([args objectForKey:@"duration"]) {
    duration = [[args objectForKey:@"duration"] intValue];
    endDate = [NSDate dateWithTimeIntervalSince1970:_startInterval + duration];
  } else if ([args objectForKey:@"endTime"]) {
    NSNumber* endTime = [args objectForKey:@"endTime"];
    NSTimeInterval _endInterval = [endTime doubleValue] / 1000; // strip millis
    endDate = [NSDate dateWithTimeIntervalSince1970:_endInterval];
  } else {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no duration or endDate was set"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }
  
//  HKUnit *joulesUnit = [HKUnit unitFromString:@"J"];
//  HKQuantity *nrOfJoules = [HKQuantity quantityWithUnit:joulesUnit doubleValue:101.5];
  HKUnit *energyUnit = [HKUnit calorieUnit];
  HKQuantity *nrOfEnergyUnits = [HKQuantity quantityWithUnit:energyUnit doubleValue:4500];

  HKUnit *metersUnit = [HKUnit unitFromString:@"m"];
  HKQuantity *nrOfMeters = [HKQuantity quantityWithUnit:metersUnit doubleValue:1500.0];

  NSSet *types = [NSSet setWithObjects:[HKWorkoutType workoutType], [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned], nil];
  [self.healthStore requestAuthorizationToShareTypes:types readTypes:nil completion:^(BOOL success, NSError *error) {
    if (success) {
      HKWorkout *workout = [HKWorkout workoutWithActivityType:activityTypeEnum
                                                    startDate:startDate
                                                      endDate:endDate
                                                     duration:duration
                                            totalEnergyBurned:nrOfEnergyUnits // TODO set if passed
                                                totalDistance:nrOfMeters // TODO set if passed
                                                     metadata:nil]; // TODO find out if needed
      [self.healthStore saveObject:workout withCompletion:^(BOOL success, NSError *innerError) {
        if (success) {
          // now store the samples, so it shows up in the health app as well (pass this in as an option?)
          HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                     quantity:nrOfEnergyUnits
                                                                    startDate:startDate
                                                                      endDate:endDate];
          NSArray *samples = [NSArray arrayWithObject:sample];
          
          [self.healthStore addSamples:samples toWorkout:workout completion:^(BOOL success, NSError *mostInnerError) {
            if (success) {
              dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
              });
            } else {
              dispatch_sync(dispatch_get_main_queue(), ^{
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:mostInnerError.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
              });
            }
          }];
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
      NSDate *now = [NSDate date]; // TODO pass in
      HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:now endDate:now];
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
      [self.healthStore aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *errorInner) {
        if (mostRecentQuantity) {
          double usersWeight = [mostRecentQuantity doubleValueForUnit:preferredUnit];
          dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:usersWeight];
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

// TODO, copy-paste from birthdate
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


/*
#pragma mark - HealthKit Permissions

// Returns the types of data that this app wishes to write to HealthKit.
- (NSSet *)dataTypesToWrite {
  HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
  HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
  HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
  HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
  
  return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, nil];
}

// Returns the types of data that this app wishes to read from HealthKit.
- (NSSet *)dataTypesToRead {
  HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
  HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
  HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
  HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
  HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
  HKCharacteristicType *biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
  
  return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalSexType, nil];
}
*/

@end