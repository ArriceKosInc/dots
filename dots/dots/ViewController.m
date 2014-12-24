//
//  ViewController.m
//  dots
//
//  Created by Admin on 24.12.14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
NSMutableArray *buttons;
NSMutableArray *allDots;
NSMutableArray *dotsFromCurrentChain;
NSMutableArray *allPointsUsedInCurrentChain;
NSTimer *timer1;

- (void)viewDidLoad
{
    [super viewDidLoad];
    timer1 = [NSTimer scheduledTimerWithTimeInterval:TICK
                                     target:self
                                   selector:@selector(onTick:)
                                   userInfo:nil
                                    repeats:YES];
    buttons = [NSMutableArray new];
    allDots = [NSMutableArray new];
    dotsFromCurrentChain = [NSMutableArray new];
    allPointsUsedInCurrentChain = [NSMutableArray new];
    
    int cellWidth = [[UIScreen mainScreen] bounds].size.height / 17;
    
    CGPoint buttonStartPoint = CGPointMake([[UIScreen mainScreen] bounds].size.width * 5 / 22,
                                           [[UIScreen mainScreen] bounds].size.height * 1 / 17);
    NSLog(@"%d", cellWidth);
    
    for (int i = 0; i < FIELD_SIZE*FIELD_SIZE; i++) {
        buttons[i] = [[UIButton alloc] initWithFrame:CGRectMake(buttonStartPoint.x + i % FIELD_SIZE * cellWidth,
                                                                buttonStartPoint.y + i / FIELD_SIZE * cellWidth,
                                                                cellWidth - 1,
                                                                cellWidth - 1)];
        //[buttons[i] setType:UIButtonTypeCustom];
        [buttons[i] setBackgroundColor:[UIColor redColor]];
        [buttons[i] addTarget:self action:@selector(pressBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:buttons[i]];
    }
    
    for (int i = 0; i < STARTING_DOTS_COUNT; i++) {
        [self addDotToField];
    }
    
    
    
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)onTick:(NSTimer *)timer {
    [self addDotToField];
    if ([allDots count] > 70) {
        [timer1 invalidate];
        NSLog(@"game over");
    }
}

- (IntegerPoint *)getRandomPoint
{
    IntegerPoint *point = [IntegerPoint integerPointWithX:random()%FIELD_SIZE andY:random()%FIELD_SIZE];

    return point;
}

- (void)addDotToField
{
    BOOL match;
    IntegerPoint *ip;
    do {
        match = NO;
        ip =[self getRandomPoint];
        for (int i = 0; i < [allDots count]; i++) {
            IntegerPoint *pointFromArray = [allDots objectAtIndex:i];
            if (pointFromArray.x == ip.x &&
                pointFromArray.y == ip.y) {
                match = YES;
                break;
            }
        }
    } while (match);
    [allDots addObject:ip];
    [buttons[ip.x + ip.y * FIELD_SIZE] setTitle:@"x" forState:UIControlStateNormal];
}

//fixed:
//teper' dobavlyaetsia vsegda korrektnaia tochka
//bug s nevozmojnostiu udalit' edinstvennuiu tochku

//TODO: posle povorota peresechenie s uje vkliuchennoi tochkoi - proverit', no vrode rabotaet
//novaya tochka ne mojet spawnitsia na liniiu!

-(void)pressBtn: (id)sender
{
    int positionOfSender = -1;
    for (int i = 0; i < FIELD_SIZE*FIELD_SIZE; i++) {
        if ([sender isEqual:buttons[i]]) {
            positionOfSender = i;
            break;
        }
    }
    IntegerPoint *clickedPoint = [IntegerPoint integerPointWithX:positionOfSender % FIELD_SIZE andY:positionOfSender / FIELD_SIZE];
    
    BOOL isDotInClickedButton = NO;
    for (int i = 0; i < [allDots count]; i++) {
        IntegerPoint *curPoint = [allDots  objectAtIndex:i];
        if (clickedPoint.x == curPoint.x && clickedPoint.y == curPoint.y) {
            isDotInClickedButton = YES;
        }
    }
    if (!isDotInClickedButton) {
        NSLog(@"No dot in this point");
        return;
    }
    
    if ([dotsFromCurrentChain count] != 0) {
        IntegerPoint *lastPointInList = [dotsFromCurrentChain lastObject];
        IntegerPoint *prelastPointInList = nil;
        if ([dotsFromCurrentChain count] > 1) {
            prelastPointInList = [dotsFromCurrentChain objectAtIndex:[dotsFromCurrentChain count] - 2];
        }
        if (lastPointInList.x == clickedPoint.x && lastPointInList.y == clickedPoint.y) {
            [self removePoint];
            return;
        }
        
        // if same x
        if (lastPointInList.x == clickedPoint.x) {
            if (prelastPointInList == nil) {
                IntegerPoint *nextPointToAdd = nil;
                nextPointToAdd = [self detectNextPointToAddWhenXCoordAreEqual:clickedPoint];
                if (![self addPoint:nextPointToAdd]) {
                    return;
                }
            } else {
                if (lastPointInList.x == prelastPointInList.x) {
                    if (((clickedPoint.y - lastPointInList.y) < 0 && (lastPointInList.y - prelastPointInList.y) < 0) ||
                        ((clickedPoint.y - lastPointInList.y) > 0 && (lastPointInList.y - prelastPointInList.y) > 0)) {
                        IntegerPoint *nextPointToAdd = nil;
                        nextPointToAdd = [self detectNextPointToAddWhenXCoordAreEqual:clickedPoint];
                        if (![self addPoint:nextPointToAdd]) {
                            return;
                        }
                    } else {
                        [self removePoint];
                    }
                }
                if (lastPointInList.y == prelastPointInList.y) {
                    IntegerPoint *nextPointToAdd = nil;
                    nextPointToAdd = [self detectNextPointToAddWhenXCoordAreEqual:clickedPoint];
                    if (![self addPoint:nextPointToAdd]) {
                        return;
                    }
                }
            }
        }
        
        // if same y
        if (lastPointInList.y == clickedPoint.y) {
            if (prelastPointInList == nil) {
                IntegerPoint *nextPointToAdd = nil;
                nextPointToAdd = [self detectNextPointToAddWhenYCoordAreEqual:clickedPoint];
                if (![self addPoint:nextPointToAdd]) {
                    return;
                }
            } else {
                if (lastPointInList.y == prelastPointInList.y) {
                    if (((clickedPoint.x - lastPointInList.x) < 0 && (lastPointInList.x - prelastPointInList.x) < 0) ||
                        ((clickedPoint.x - lastPointInList.x) > 0 && (lastPointInList.x - prelastPointInList.x) > 0)) {
                        IntegerPoint *nextPointToAdd = nil;
                        nextPointToAdd = [self detectNextPointToAddWhenYCoordAreEqual:clickedPoint];
                        if (![self addPoint:nextPointToAdd]) {
                            return;
                        }
                    } else {
                        [self removePoint];
                    }
                }
                if (lastPointInList.x == prelastPointInList.x) {
                    IntegerPoint *nextPointToAdd = nil;
                    nextPointToAdd = [self detectNextPointToAddWhenYCoordAreEqual:clickedPoint];
                    if (![self addPoint:nextPointToAdd]) {
                        return;
                    }
                }
            }
        }
    } else {    //first point
        [allPointsUsedInCurrentChain addObject:clickedPoint];       //poka ostavili chtobi ne narushat' otchetnosti
        [self addPoint:clickedPoint];
    }
   // [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
}

-(void) removePoint
{
    IntegerPoint *lastPointInList = [dotsFromCurrentChain lastObject];
    IntegerPoint *prelastPointInList = nil;
    if ([dotsFromCurrentChain count] > 1) {
        prelastPointInList = [dotsFromCurrentChain objectAtIndex:[dotsFromCurrentChain count] - 2];
    }
    [buttons[lastPointInList.x + lastPointInList.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
    [dotsFromCurrentChain removeLastObject];
    if ([dotsFromCurrentChain count] != 0) {
        if (prelastPointInList.x == lastPointInList.x) {
            int startCoord = (lastPointInList.y < prelastPointInList.y) ? lastPointInList.y : prelastPointInList.y;
            int endCoord = (lastPointInList.y > prelastPointInList.y) ? lastPointInList.y : prelastPointInList.y;
            for (int i = startCoord; i <= endCoord; i++) {
                [allPointsUsedInCurrentChain removeLastObject];
                IntegerPoint *pointToRemove = [IntegerPoint integerPointWithX:lastPointInList.x andY:i];
                [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
            }
        } else
            if (prelastPointInList.y == lastPointInList.y) {
                int startCoord = (lastPointInList.x < prelastPointInList.x) ? lastPointInList.x : prelastPointInList.x;
                int endCoord = (lastPointInList.x > prelastPointInList.x) ? lastPointInList.x : prelastPointInList.x;
                for (int i = startCoord; i <= endCoord; i++) {
                    [allPointsUsedInCurrentChain removeLastObject];
                    IntegerPoint *pointToRemove = [IntegerPoint integerPointWithX:lastPointInList.x andY:i];
                    [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
                }
            }
    } else {
        [allPointsUsedInCurrentChain removeLastObject];
    }
}

-(BOOL) addPoint: (IntegerPoint*) nextPoint
{
    IntegerPoint *lastPointInList = [dotsFromCurrentChain lastObject];
    IntegerPoint *prelastPointInList = nil;
    
    if ([dotsFromCurrentChain count] > 1) {
        prelastPointInList = [dotsFromCurrentChain objectAtIndex:[dotsFromCurrentChain count] - 2];
    }
    if (!nextPoint) {
        return false;
    } else {
        [dotsFromCurrentChain addObject:nextPoint];    //add points affected by line
        
        if (nextPoint.x == lastPointInList.x) {
            int startCoord = (lastPointInList.y < nextPoint.y) ? lastPointInList.y : nextPoint.y;
            int endCoord = (lastPointInList.y > nextPoint.y) ? lastPointInList.y : nextPoint.y;
            for (int i = startCoord; i <= endCoord; i++) {
                IntegerPoint *pointToAdd = [IntegerPoint integerPointWithX:nextPoint.x andY:i];
                [allPointsUsedInCurrentChain addObject:pointToAdd];
                [buttons[pointToAdd.x + pointToAdd.y * FIELD_SIZE] setBackgroundColor:[UIColor yellowColor]];
            }
        } else
            if (nextPoint.y == lastPointInList.y) {
                int startCoord = (lastPointInList.x < nextPoint.x) ? lastPointInList.x : nextPoint.x;
                int endCoord = (lastPointInList.x > nextPoint.x) ? lastPointInList.x : nextPoint.x;
                for (int i = startCoord; i <= endCoord; i++) {
                    IntegerPoint *pointToAdd = [IntegerPoint integerPointWithX:i andY:nextPoint.y];
                    [allPointsUsedInCurrentChain addObject:pointToAdd];
                    [buttons[pointToAdd.x + pointToAdd.y * FIELD_SIZE] setBackgroundColor:[UIColor yellowColor]];
                }
            }
        
        NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
        [buttons[nextPoint.x + nextPoint.y * FIELD_SIZE] setBackgroundColor:[UIColor greenColor]];
        return true;
    }
}

-(IntegerPoint *) detectNextPointToAddWhenXCoordAreEqual: (IntegerPoint *) point
{
    IntegerPoint *ip = point;
    IntegerPoint *lastPointInList = [dotsFromCurrentChain lastObject];
    int startCoord = (lastPointInList.y < ip.y) ? lastPointInList.y : ip.y;
    int endCoord = (lastPointInList.y > ip.y) ? lastPointInList.y : ip.y;
    IntegerPoint *pointMostCloseToLast = nil;
    for (int i = 0; i < [allDots count]; i++) {
        IntegerPoint *dotToCheck = [allDots objectAtIndex:i];
        if (dotToCheck.x == lastPointInList.x && dotToCheck.y < endCoord && dotToCheck.y > startCoord) {
            if (pointMostCloseToLast) {
                if (abs(dotToCheck.y - lastPointInList.y) < abs(pointMostCloseToLast.y - lastPointInList.y)) {
                    pointMostCloseToLast = dotToCheck;
                }
            } else {
                pointMostCloseToLast = dotToCheck;
            }
            BOOL isAlreadyInList = NO;
            for (int j = 0; j < [dotsFromCurrentChain count]; j++) {
                IntegerPoint *dotFromList = [dotsFromCurrentChain objectAtIndex:j];
                if (dotFromList.x == pointMostCloseToLast.x && dotFromList.y == pointMostCloseToLast.y) {
                    isAlreadyInList = YES;
                    break;
                }
            }
            if (isAlreadyInList) {
                NSLog(@"Cannot add a dot by intersecting a dot already in list");
                return nil;
            }
            ip = pointMostCloseToLast;
        }
    }
    return ip;
}

-(IntegerPoint *) detectNextPointToAddWhenYCoordAreEqual: (IntegerPoint *) point
{
    IntegerPoint *ip = point;
    IntegerPoint *lastPointInList = [dotsFromCurrentChain lastObject];
    int startCoord = (lastPointInList.x < ip.x) ? lastPointInList.x : ip.x;
    int endCoord = (lastPointInList.x > ip.x) ? lastPointInList.x : ip.x;
    IntegerPoint *pointMostCloseToLast = nil;
    for (int i = 0; i < [allDots count]; i++) {
        IntegerPoint *dotToCheck = [allDots objectAtIndex:i];
        if (dotToCheck.y == lastPointInList.y && dotToCheck.x < endCoord && dotToCheck.x > startCoord) {
            if (pointMostCloseToLast) {
                if (abs(dotToCheck.x - lastPointInList.x) < abs(pointMostCloseToLast.x - lastPointInList.x)) {
                    pointMostCloseToLast = dotToCheck;
                }
            } else {
                pointMostCloseToLast = dotToCheck;
            }
            NSLog(@"Im here");
            BOOL isAlreadyInList = NO;
            for (int j = 0; j < [dotsFromCurrentChain count]; j++) {
                IntegerPoint *dotFromList = [dotsFromCurrentChain objectAtIndex:j];
                if (dotFromList.x == pointMostCloseToLast.x && dotFromList.y == pointMostCloseToLast.y) {
                    isAlreadyInList = YES;
                    break;
                }
            }
            if (isAlreadyInList) {
                NSLog(@"Cannot add a dot by intersecting a dot already in list");
                return nil;
            }
            ip = pointMostCloseToLast;
        }
    }
    return ip;
}

@end

