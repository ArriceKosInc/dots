//
//  Bonus.m
//  dots
//
//  Created by Admin on 27.12.14.
//  Copyright (c) 2014 Admin. All rights reserved.
//

#import "Bonus.h"

@implementation Bonus

- (id) init
{
    self = [super init];
    if (self)
    {
        self.position = [IntegerPoint integerPointWithX:0 andY:0];
        self.bonusType = BonusTypeScoreModifier;
        self.effectDuration = DEFAULT_BONUS_EFFECT_DURATION;
        self.lifeTime = DEFAULT_BONUS_LIFETIME;
    }
    return self;
}

- (BOOL) isEqualToBonus:(Bonus *) bonus
{
    if ([self.position isEqualToPoint:bonus.position] && self.bonusType == bonus.bonusType &&
        self.effectDuration == bonus.effectDuration && self.lifeTime == bonus.lifeTime) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *) toString
{
    NSString *string = [NSString stringWithFormat:@"%d %d %d %d %d", self.position.x,
                   self.position.y, self.bonusType, self.effectDuration, self.lifeTime];
    return string;
}
+ (Bonus *) bonusFromString:(NSString *) string
{
    NSArray *components = [string componentsSeparatedByString:@" "];
    NSString *s_x = [components objectAtIndex:0];
    int x = [s_x intValue];
    NSString *s_y = [components objectAtIndex:1];
    int y = [s_y intValue];
    NSString *s_type = [components objectAtIndex:2];
    int type = [s_type intValue];
    NSString *s_effectDuration = [components objectAtIndex:3];
    int effectDuration = [s_effectDuration intValue];
    NSString *s_lifeTime = [components objectAtIndex:4];
    int lifeTime = [s_lifeTime intValue];
    Bonus *bonus = [[Bonus alloc] init];
    bonus.position = [IntegerPoint integerPointWithX:x andY:y];
    bonus.bonusType = type;
    bonus.effectDuration = effectDuration;
    bonus.lifeTime = lifeTime;
    return bonus;
}

@end
