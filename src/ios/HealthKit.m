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
  [self writeJavascript:[result toSuccessCallbackString:command.callbackId]];
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
          [self writeJavascript:[result toSuccessCallbackString:callbackId]];
        });
      } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
          CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
          [self writeJavascript:[result toErrorCallbackString:callbackId]];
        });
      }
    }];
  } else {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"healthkit not available"];
    [self writeJavascript:[result toSuccessCallbackString:callbackId]];
  }
}
*/

// TODO method to check this: HKAuthorizationStatus status = [self.healthStore authorizationStatusForType:<the type>];
// if status = denied, prompt user to go to setting

- (void) saveWeight:(CDVInvokedUrlCommand*)command {
  NSString *callbackId = command.callbackId;
  double weight = 80500; // 80,5 kg
  
  HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
  NSSet *requestTypes = [NSSet setWithObjects: weightType, nil];
  [self.healthStore requestAuthorizationToShareTypes:requestTypes readTypes:requestTypes completion:^(BOOL success, NSError *error) {
    if (success) {
      HKUnit *localUnit = [HKUnit gramUnit]; // TODO pass in type: gram, pound, stone
      HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:localUnit doubleValue:weight];
      NSDate *now = [NSDate date]; // TODO pass in
      HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:now endDate:now];
      [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError* errorInner) {
        if (success) {
          dispatch_sync(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self writeJavascript:[result toSuccessCallbackString:callbackId]];
          });
        } else {
          dispatch_sync(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInner.localizedDescription];
            [self writeJavascript:[result toErrorCallbackString:callbackId]];
          });
        }
      }];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self writeJavascript:[result toErrorCallbackString:callbackId]];
      });
    }
  }];
}

- (void) readWeight:(CDVInvokedUrlCommand*)command {
  NSString *callbackId = command.callbackId;

  // Query to get the user's latest weight, if it exists.
  HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
  NSSet *requestTypes = [NSSet setWithObjects: weightType, nil];
  // always ask for read and write permission if the app uses both, because granting read will remove write for the same type :(
  [self.healthStore requestAuthorizationToShareTypes:requestTypes readTypes:requestTypes completion:^(BOOL success, NSError *error) {
    if (success) {
      [self.healthStore aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *errorInner) {
        if (mostRecentQuantity) {
          // TODO pass in type of unit to convert to: gram, pound, stone
          HKUnit *weightUnit = [HKUnit gramUnit];
          double usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit];
          dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:usersWeight];
            [self writeJavascript:[result toSuccessCallbackString:callbackId]];
          });
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInner.localizedDescription];
            [self writeJavascript:[result toErrorCallbackString:callbackId]];
          });
        }
      }];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self writeJavascript:[result toErrorCallbackString:callbackId]];
      });
    }
  }];
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