//
//  Bonus.h
//  dots
//
//  Created by Admin on 27.12.14.
//  Copyright (c) 2014 Admin. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef enum {
    BonusTypeIgnoreBarriers = 0,
    BonusTypeScoreModifier,
    //BonusTypeAdditionalPoint,
    BonusTypeDotLimit,
    BonusTypeLowerSpeed,
    numBonusTypes
} BonusType;

@interface Bonus : NSObject

@property (nonatomic, readwrite) IntegerPoint *position;
@property (nonatomic, readwrite) BonusType bonusType;
@property (nonatomic, readwrite) int effectDuration;
@property (nonatomic, readwrite) int lifeTime;
@property (nonatomic, readwrite) int bonusId;

+ (int) bonusCount;
+ (void) setBonusCount:(int)val;

- (BOOL) isEqualToBonus:(Bonus *) bonus;
- (NSString *) toString;
+ (Bonus *) bonusFromString:(NSString *) string;

@end
