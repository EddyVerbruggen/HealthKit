#import <HealthKit/HealthKit.h>

@interface WorkoutActivityConversion : NSObject
+ (NSString*) convertHKWorkoutActivityTypeToString:(HKWorkoutActivityType) which;
+ (HKWorkoutActivityType) convertStringToHKWorkoutActivityType:(NSString*) which;
@end