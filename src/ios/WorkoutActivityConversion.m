#import "WorkoutActivityConversion.h"

// Note that code in here requires maintenance but I can't find a better way
@implementation WorkoutActivityConversion

+ (NSString*) convertHKWorkoutActivityTypeToString:(HKWorkoutActivityType) which {
  switch(which) {
    case HKWorkoutActivityTypeAmericanFootball:
      return @"HKWorkoutActivityTypeAmericanFootball";
    case HKWorkoutActivityTypeArchery:
      return @"HKWorkoutActivityTypeArchery";
    case HKWorkoutActivityTypeAustralianFootball:
      return @"HKWorkoutActivityTypeAustralianFootball";
    case HKWorkoutActivityTypeBadminton:
      return @"HKWorkoutActivityTypeBadminton";
    case HKWorkoutActivityTypeBaseball:
      return @"HKWorkoutActivityTypeBaseball";
    case HKWorkoutActivityTypeBasketball:
      return @"HKWorkoutActivityTypeBasketball";
    case HKWorkoutActivityTypeBowling:
      return @"HKWorkoutActivityTypeBowling";
    case HKWorkoutActivityTypeBoxing:
      return @"HKWorkoutActivityTypeBoxing";
    case HKWorkoutActivityTypeClimbing:
      return @"HKWorkoutActivityTypeClimbing";
    case HKWorkoutActivityTypeCricket:
      return @"HKWorkoutActivityTypeCricket";
    case HKWorkoutActivityTypeCrossTraining:
      return @"HKWorkoutActivityTypeCrossTraining";
    case HKWorkoutActivityTypeCurling:
      return @"HKWorkoutActivityTypeCurling";
    case HKWorkoutActivityTypeCycling:
      return @"HKWorkoutActivityTypeCycling";
    case HKWorkoutActivityTypeDance:
      return @"HKWorkoutActivityTypeDance";
    case HKWorkoutActivityTypeDanceInspiredTraining:
      return @"HKWorkoutActivityTypeDanceInspiredTraining";
    case HKWorkoutActivityTypeElliptical:
      return @"HKWorkoutActivityTypeElliptical";
    case HKWorkoutActivityTypeEquestrianSports:
      return @"HKWorkoutActivityTypeEquestrianSports";
    case HKWorkoutActivityTypeFencing:
      return @"HKWorkoutActivityTypeFencing";
    case HKWorkoutActivityTypeFishing:
      return @"HKWorkoutActivityTypeFishing";
    case HKWorkoutActivityTypeFunctionalStrengthTraining:
      return @"HKWorkoutActivityTypeFunctionalStrengthTraining";
    case HKWorkoutActivityTypeGolf:
      return @"HKWorkoutActivityTypeGolf";
    case HKWorkoutActivityTypeGymnastics:
      return @"HKWorkoutActivityTypeGymnastics";
    case HKWorkoutActivityTypeHandball:
      return @"HKWorkoutActivityTypeHandball";
    case HKWorkoutActivityTypeHiking:
      return @"HKWorkoutActivityTypeHiking";
    case HKWorkoutActivityTypeHockey:
      return @"HKWorkoutActivityTypeHockey";
    case HKWorkoutActivityTypeHunting:
      return @"HKWorkoutActivityTypeHunting";
    case HKWorkoutActivityTypeLacrosse:
      return @"HKWorkoutActivityTypeLacrosse";
    case HKWorkoutActivityTypeMartialArts:
      return @"HKWorkoutActivityTypeMartialArts";
    case HKWorkoutActivityTypeMindAndBody:
      return @"HKWorkoutActivityTypeMindAndBody";
    case HKWorkoutActivityTypeMixedMetabolicCardioTraining:
      return @"HKWorkoutActivityTypeMixedMetabolicCardioTraining";
    case HKWorkoutActivityTypePaddleSports:
      return @"HKWorkoutActivityTypePaddleSports";
    case HKWorkoutActivityTypePlay:
      return @"HKWorkoutActivityTypePlay";
    case HKWorkoutActivityTypePreparationAndRecovery:
      return @"HKWorkoutActivityTypePreparationAndRecovery";
    case HKWorkoutActivityTypeRacquetball:
      return @"HKWorkoutActivityTypeRacquetball";
    case HKWorkoutActivityTypeRowing:
      return @"HKWorkoutActivityTypeRowing";
    case HKWorkoutActivityTypeRugby:
      return @"HKWorkoutActivityTypeRugby";
    case HKWorkoutActivityTypeRunning:
      return @"HKWorkoutActivityTypeRunning";
    case HKWorkoutActivityTypeSailing:
      return @"HKWorkoutActivityTypeSailing";
    case HKWorkoutActivityTypeSkatingSports:
      return @"HKWorkoutActivityTypeSkatingSports";
    case HKWorkoutActivityTypeSnowSports:
      return @"HKWorkoutActivityTypeSnowSports";
    case HKWorkoutActivityTypeSoccer:
      return @"HKWorkoutActivityTypeSoccer";
    case HKWorkoutActivityTypeSoftball:
      return @"HKWorkoutActivityTypeSoftball";
    case HKWorkoutActivityTypeSquash:
      return @"HKWorkoutActivityTypeSquash";
    case HKWorkoutActivityTypeStairClimbing:
      return @"HKWorkoutActivityTypeStairClimbing";
    case HKWorkoutActivityTypeSurfingSports:
      return @"HKWorkoutActivityTypeSurfingSports";
    case HKWorkoutActivityTypeSwimming:
      return @"HKWorkoutActivityTypeSwimming";
    case HKWorkoutActivityTypeTableTennis:
      return @"HKWorkoutActivityTypeTableTennis";
    case HKWorkoutActivityTypeTennis:
      return @"HKWorkoutActivityTypeTennis";
    case HKWorkoutActivityTypeTrackAndField:
      return @"HKWorkoutActivityTypeTrackAndField";
    case HKWorkoutActivityTypeTraditionalStrengthTraining:
      return @"HKWorkoutActivityTypeTraditionalStrengthTraining";
    case HKWorkoutActivityTypeVolleyball:
      return @"HKWorkoutActivityTypeVolleyball";
    case HKWorkoutActivityTypeWalking:
      return @"HKWorkoutActivityTypeWalking";
    case HKWorkoutActivityTypeWaterFitness:
      return @"HKWorkoutActivityTypeWaterFitness";
    case HKWorkoutActivityTypeWaterPolo:
      return @"HKWorkoutActivityTypeWaterPolo";
    case HKWorkoutActivityTypeWaterSports:
      return @"HKWorkoutActivityTypeWaterSports";
    case HKWorkoutActivityTypeWrestling:
      return @"HKWorkoutActivityTypeWrestling";
    case HKWorkoutActivityTypeYoga:
      return @"HKWorkoutActivityTypeYoga";
    default:
      return @"unknown";
  }
}

+ (HKWorkoutActivityType) convertStringToHKWorkoutActivityType:(NSString*) which {
  if ([which isEqualToString:@"HKWorkoutActivityTypeAmericanFootball"]) {
    return HKWorkoutActivityTypeAmericanFootball;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeArchery"]) {
    return HKWorkoutActivityTypeArchery;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeAustralianFootball"]) {
    return HKWorkoutActivityTypeAustralianFootball;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeBadminton"]) {
    return HKWorkoutActivityTypeBadminton;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeBaseball"]) {
    return HKWorkoutActivityTypeBaseball;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeBasketball"]) {
    return HKWorkoutActivityTypeBasketball;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeBowling"]) {
    return HKWorkoutActivityTypeBowling;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeBoxing"]) {
    return HKWorkoutActivityTypeBoxing;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeClimbing"]) {
    return HKWorkoutActivityTypeClimbing;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeCricket"]) {
    return HKWorkoutActivityTypeCricket;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeCrossTraining"]) {
    return HKWorkoutActivityTypeCrossTraining;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeCurling"]) {
    return HKWorkoutActivityTypeCurling;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeCycling"]) {
    return HKWorkoutActivityTypeCycling;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeDance"]) {
    return HKWorkoutActivityTypeDance;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeDanceInspiredTraining"]) {
    return HKWorkoutActivityTypeDanceInspiredTraining;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeElliptical"]) {
    return HKWorkoutActivityTypeElliptical;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeEquestrianSports"]) {
    return HKWorkoutActivityTypeEquestrianSports;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeFencing"]) {
    return HKWorkoutActivityTypeFencing;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeFishing"]) {
    return HKWorkoutActivityTypeFishing;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeFunctionalStrengthTraining"]) {
    return HKWorkoutActivityTypeFunctionalStrengthTraining;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeGolf"]) {
    return HKWorkoutActivityTypeGolf;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeGymnastics"]) {
    return HKWorkoutActivityTypeGymnastics;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeHandball"]) {
    return HKWorkoutActivityTypeHandball;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeHiking"]) {
    return HKWorkoutActivityTypeHiking;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeHockey"]) {
    return HKWorkoutActivityTypeHockey;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeHunting"]) {
    return HKWorkoutActivityTypeHunting;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeLacrosse"]) {
    return HKWorkoutActivityTypeLacrosse;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeMartialArts"]) {
    return HKWorkoutActivityTypeMartialArts;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeMindAndBody"]) {
    return HKWorkoutActivityTypeMindAndBody;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeMixedMetabolicCardioTraining"]) {
    return HKWorkoutActivityTypeMixedMetabolicCardioTraining;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypePaddleSports"]) {
    return HKWorkoutActivityTypePaddleSports;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypePlay"]) {
    return HKWorkoutActivityTypePlay;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypePreparationAndRecovery"]) {
    return HKWorkoutActivityTypePreparationAndRecovery;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeRacquetball"]) {
    return HKWorkoutActivityTypeRacquetball;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeRowing"]) {
    return HKWorkoutActivityTypeRowing;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeRugby"]) {
    return HKWorkoutActivityTypeRugby;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeRunning"]) {
    return HKWorkoutActivityTypeRunning;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeSailing"]) {
    return HKWorkoutActivityTypeSailing;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeSkatingSports"]) {
    return HKWorkoutActivityTypeSkatingSports;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeSnowSports"]) {
    return HKWorkoutActivityTypeSnowSports;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeSoccer"]) {
    return HKWorkoutActivityTypeSoccer;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeSoftball"]) {
    return HKWorkoutActivityTypeSoftball;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeSquash"]) {
    return HKWorkoutActivityTypeSquash;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeStairClimbing"]) {
    return HKWorkoutActivityTypeStairClimbing;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeSurfingSports"]) {
    return HKWorkoutActivityTypeSurfingSports;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeSwimming"]) {
    return HKWorkoutActivityTypeSwimming;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeTableTennis"]) {
    return HKWorkoutActivityTypeTableTennis;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeTennis"]) {
    return HKWorkoutActivityTypeTennis;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeTrackAndField"]) {
    return HKWorkoutActivityTypeTrackAndField;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeTraditionalStrengthTraining"]) {
    return HKWorkoutActivityTypeTraditionalStrengthTraining;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeVolleyball"]) {
    return HKWorkoutActivityTypeVolleyball;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeWalking"]) {
    return HKWorkoutActivityTypeWalking;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeWaterFitness"]) {
    return HKWorkoutActivityTypeWaterFitness;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeWaterPolo"]) {
    return HKWorkoutActivityTypeWaterPolo;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeWaterSports"]) {
    return HKWorkoutActivityTypeWaterSports;
  } else if ([which isEqualToString:@"HKWorkoutActivityTypeWrestling"]) {
    return HKWorkoutActivityTypeWrestling;
  } else {
    return HKWorkoutActivityTypeYoga;
  }
}

@end