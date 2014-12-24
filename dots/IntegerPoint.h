//
//  IntegerPoint.h
//  BAF WITH LTVN
//
//  Created by Kostya on 04.11.14.
//  Copyright (c) 2014 ru.mail@kostyasxd. All rights reserved.
//

@interface IntegerPoint : NSObject

@property (nonatomic, readwrite) NSInteger x;
@property (nonatomic, readwrite) NSInteger y;

+ (IntegerPoint *) integerPointWithX:(NSInteger) x andY:(NSInteger) y;



@end
