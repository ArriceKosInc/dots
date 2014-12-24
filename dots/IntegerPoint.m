//
//  IntegerPoint.m
//  BAF WITH LTVN
//
//  Created by Kostya on 04.11.14.
//  Copyright (c) 2014 ru.mail@kostyasxd. All rights reserved.
//

#import "IntegerPoint.h"

@implementation IntegerPoint

+ (IntegerPoint *) integerPointWithX:(NSInteger) x andY:(NSInteger) y
{
    IntegerPoint *ip = [IntegerPoint new];
    
    ip.x = x;
    ip.y = y;
    
    return ip;
}


@end
