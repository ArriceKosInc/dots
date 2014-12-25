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
long int score;

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
    
    score = 0;
    
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
    IntegerPoint *point = [IntegerPoint integerPointWithX:random() % FIELD_SIZE andY:random() % FIELD_SIZE];

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
            if ([pointFromArray isEqualToPoint:ip]) {
                match = YES;
                break;
            }
        }
        if (!match) {
            for (int i = 0; i < [allPointsUsedInCurrentChain count]; i++) {
                IntegerPoint *pointFromArray = [allPointsUsedInCurrentChain objectAtIndex:i];
                if ([pointFromArray isEqualToPoint:ip]) {
                    match = YES;
                    break;
                }
            }
        }
    } while (match);
    [allDots addObject:ip];
    [buttons[ip.x + ip.y * FIELD_SIZE] setTitle:@"x" forState:UIControlStateNormal];
}

-(void)pressBtn: (id)sender
{
    IntegerPoint *clickedPoint = [self pointByClickedSender:sender];
    if (![self pointContainsDot:clickedPoint]) {
        NSLog(@"No dot in this point");
        return;
    }
    
    if ([dotsFromCurrentChain count] != 0) {
        IntegerPoint *lastPointInChain = [dotsFromCurrentChain lastObject];
        IntegerPoint *prelastPointInList = nil;
        if ([dotsFromCurrentChain count] > 1) {
            prelastPointInList = [dotsFromCurrentChain objectAtIndex:[dotsFromCurrentChain count] - 2];
        }
        if ([lastPointInChain isEqualToPoint:clickedPoint]) {
            [self removePoint];
            return;
        }
        IntegerPoint *nextPointToAdd = nil;
        
        // if same x
        if (lastPointInChain.x == clickedPoint.x) {
            nextPointToAdd = [self detectNextPointToAddWhenXCoordAreEqual:clickedPoint];
            if (!prelastPointInList) {
                if (![self addPoint:nextPointToAdd]) {
                    return;
                }
            } else {
                if (lastPointInChain.x == prelastPointInList.x) {
                    if ([clickedPoint makesRayWithPoint1:lastPointInChain andPoint2:prelastPointInList]) {
                        if (![self addPoint:nextPointToAdd]) {
                            return;
                        }
                    } else {
                        [self removePoint];
                    }
                }
                if (lastPointInChain.y == prelastPointInList.y) {
                    if (![self addPoint:nextPointToAdd]) {
                        return;
                    }
                }
            }
        }
        
        // if same y
        if (lastPointInChain.y == clickedPoint.y) {
            nextPointToAdd = [self detectNextPointToAddWhenYCoordAreEqual:clickedPoint];
            if (!prelastPointInList) {
                if (![self addPoint:nextPointToAdd]) {
                    return;
                }
            } else {
                if (lastPointInChain.y == prelastPointInList.y) {
                    if ([clickedPoint makesRayWithPoint1:lastPointInChain andPoint2:prelastPointInList]) {
                        if (![self addPoint:nextPointToAdd]) {
                            return;
                        }
                    } else {
                        [self removePoint];
                    }
                }
                if (lastPointInChain.x == prelastPointInList.x) {
                    if (![self addPoint:nextPointToAdd]) {
                        return;
                    }
                }
            }
        }
    } else {    //first point
        [self addPoint:clickedPoint];
    }
}

-(void) removePoint
{
    IntegerPoint *lastPointInList = nil;
    if ([dotsFromCurrentChain count] > 0) {
        lastPointInList = [dotsFromCurrentChain lastObject];
    }
    IntegerPoint *prelastPointInChain = nil;
    if ([dotsFromCurrentChain count] > 1) {
        prelastPointInChain = [dotsFromCurrentChain objectAtIndex:[dotsFromCurrentChain count] - 2];
    }
    [buttons[lastPointInList.x + lastPointInList.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
    [dotsFromCurrentChain removeLastObject];
    if (prelastPointInChain) {
        if (prelastPointInChain.x == lastPointInList.x) {
            int startCoord = (lastPointInList.y < prelastPointInChain.y) ? lastPointInList.y : prelastPointInChain.y;
            int endCoord = (lastPointInList.y > prelastPointInChain.y) ? lastPointInList.y : prelastPointInChain.y;
            if (lastPointInList.y > prelastPointInChain.y) {
                startCoord++;
            } else {
                endCoord--;
            }
            for (int i = startCoord; i <= endCoord; i++) {
                [allPointsUsedInCurrentChain removeLastObject];
                IntegerPoint *pointToRemove = [IntegerPoint integerPointWithX:lastPointInList.x andY:i];
                
                //preventing from making point red if is still exists in chain
                BOOL isStillInList = NO;
                for (int j = 0; j < [allPointsUsedInCurrentChain count]; j++) {
                    IntegerPoint *pointFromList = [allPointsUsedInCurrentChain objectAtIndex:j];
                    if ([pointToRemove isEqualToPoint:pointFromList]) {
                        isStillInList = YES;
                        break;
                    }
                }
                if (!isStillInList) {
                    [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
                }
                
            }
        } else
            if (prelastPointInChain.y == lastPointInList.y) {
                int startCoord = (lastPointInList.x < prelastPointInChain.x) ? lastPointInList.x : prelastPointInChain.x;
                int endCoord = (lastPointInList.x > prelastPointInChain.x) ? lastPointInList.x : prelastPointInChain.x;
                if (lastPointInList.x > prelastPointInChain.x) {
                    startCoord++;
                } else {
                    endCoord--;
                }
                for (int i = startCoord; i <= endCoord; i++) {
                    [allPointsUsedInCurrentChain removeLastObject];
                    IntegerPoint *pointToRemove = [IntegerPoint integerPointWithX:i andY:lastPointInList.y];
                    
                    //preventing from making point red if is still exists in chain
                    BOOL isStillInList = NO;
                    for (int j = 0; j < [allPointsUsedInCurrentChain count]; j++) {
                        IntegerPoint *pointFromList = [allPointsUsedInCurrentChain objectAtIndex:j];
                        if ([pointToRemove isEqualToPoint:pointFromList]) {
                            isStillInList = YES;
                            break;
                        }
                    }
                    if (!isStillInList) {
                        [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
        [buttons[prelastPointInChain.x + prelastPointInChain.y * FIELD_SIZE] setBackgroundColor:[UIColor greenColor]];
    } else {
        [allPointsUsedInCurrentChain removeLastObject];
    }
    NSLog(@"line length = %d", [allPointsUsedInCurrentChain count]);
}

-(BOOL) addPoint: (IntegerPoint*) nextPoint
{
    IntegerPoint *lastPointInChain = nil;
    if ([dotsFromCurrentChain count] > 0) {
        lastPointInChain = [dotsFromCurrentChain lastObject];
    }
    
    if (!nextPoint) {
        return false;
    } else {
        [dotsFromCurrentChain addObject:nextPoint];
        if (lastPointInChain) {
            if (nextPoint.x == lastPointInChain.x) {
                int startCoord = (lastPointInChain.y < nextPoint.y) ? lastPointInChain.y : nextPoint.y;
                int endCoord = (lastPointInChain.y > nextPoint.y) ? lastPointInChain.y : nextPoint.y;
                if (nextPoint.y > lastPointInChain.y) {
                    startCoord++;
                } else {
                    endCoord--;
                }
                for (int i = startCoord; i <= endCoord; i++) {
                    IntegerPoint *pointToAdd = [IntegerPoint integerPointWithX:nextPoint.x andY:i];
                    [allPointsUsedInCurrentChain addObject:pointToAdd];
                    [buttons[pointToAdd.x + pointToAdd.y * FIELD_SIZE] setBackgroundColor:[UIColor yellowColor]];
                }
            } else
                if (nextPoint.y == lastPointInChain.y) {
                    int startCoord = (lastPointInChain.x < nextPoint.x) ? lastPointInChain.x : nextPoint.x;
                    int endCoord = (lastPointInChain.x > nextPoint.x) ? lastPointInChain.x : nextPoint.x;
                    if (nextPoint.x > lastPointInChain.x) {
                        startCoord++;
                    } else {
                        endCoord--;
                    }
                    for (int i = startCoord; i <= endCoord; i++) {
                        IntegerPoint *pointToAdd = [IntegerPoint integerPointWithX:i andY:nextPoint.y];
                        [allPointsUsedInCurrentChain addObject:pointToAdd];
                        [buttons[pointToAdd.x + pointToAdd.y * FIELD_SIZE] setBackgroundColor:[UIColor yellowColor]];
                    }
                }
            
        } else {
            [allPointsUsedInCurrentChain addObject:nextPoint];
        }
        NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
        [buttons[nextPoint.x + nextPoint.y * FIELD_SIZE] setBackgroundColor:[UIColor greenColor]];
        NSLog(@"line length = %d", [allPointsUsedInCurrentChain count]);
        
        IntegerPoint *firstPointInChain = [dotsFromCurrentChain firstObject];
        lastPointInChain = [dotsFromCurrentChain lastObject];
        if ([firstPointInChain isEqualToPoint:lastPointInChain] &&
            [dotsFromCurrentChain count] >= 4) {
            [self explodeChain];
        }
        
        return true;
    }
}

-(IntegerPoint *) detectNextPointToAddWhenXCoordAreEqual: (IntegerPoint *) point
{
    IntegerPoint *ip = point;
    IntegerPoint *lastPointInChain = [dotsFromCurrentChain lastObject];
    int startCoord = (lastPointInChain.y < ip.y) ? lastPointInChain.y : ip.y;
    int endCoord = (lastPointInChain.y > ip.y) ? lastPointInChain.y : ip.y;
    IntegerPoint *pointMostCloseToLast = nil;
    for (int i = 0; i < [allDots count]; i++) {
        IntegerPoint *dotToCheck = [allDots objectAtIndex:i];
        if (dotToCheck.x == lastPointInChain.x && dotToCheck.y < endCoord && dotToCheck.y > startCoord) {
            if (pointMostCloseToLast) {
                if (abs(dotToCheck.y - lastPointInChain.y) < abs(pointMostCloseToLast.y - lastPointInChain.y)) {
                    pointMostCloseToLast = dotToCheck;
                }
            } else {
                pointMostCloseToLast = dotToCheck;
            }
            ip = pointMostCloseToLast;
        }
    }
    BOOL isAlreadyInList = NO;
    for (int j = 1; j < [dotsFromCurrentChain count]; j++) {
        IntegerPoint *dotFromList = [dotsFromCurrentChain objectAtIndex:j];
        if ([dotFromList isEqualToPoint:ip]) {
            isAlreadyInList = YES;
            break;
        }
    }
    if (isAlreadyInList) {
        NSLog(@"Cannot add a dot by intersecting a dot already in list");
        return nil;
    }
    return ip;
}

-(IntegerPoint *) detectNextPointToAddWhenYCoordAreEqual: (IntegerPoint *) point
{
    IntegerPoint *ip = point;
    IntegerPoint *lastPointInChain = [dotsFromCurrentChain lastObject];
    int startCoord = (lastPointInChain.x < ip.x) ? lastPointInChain.x : ip.x;
    int endCoord = (lastPointInChain.x > ip.x) ? lastPointInChain.x : ip.x;
    IntegerPoint *pointMostCloseToLast = nil;
    for (int i = 0; i < [allDots count]; i++) {
        IntegerPoint *dotToCheck = [allDots objectAtIndex:i];
        if (dotToCheck.y == lastPointInChain.y && dotToCheck.x < endCoord && dotToCheck.x > startCoord) {
            if (pointMostCloseToLast) {
                if (abs(dotToCheck.x - lastPointInChain.x) < abs(pointMostCloseToLast.x - lastPointInChain.x)) {
                    pointMostCloseToLast = dotToCheck;
                }
            } else {
                pointMostCloseToLast = dotToCheck;
            }
            ip = pointMostCloseToLast;
        }
    }
    BOOL isAlreadyInList = NO;
    for (int j = 1; j < [dotsFromCurrentChain count]; j++) {
        IntegerPoint *dotFromList = [dotsFromCurrentChain objectAtIndex:j];
        if ([dotFromList isEqualToPoint:ip]) {
            isAlreadyInList = YES;
            break;
        }
    }
    if (isAlreadyInList) {
        NSLog(@"Cannot add a dot by intersecting a dot already in list");
        return nil;
    }
    return ip;
}

-(BOOL) pointContainsDot: (IntegerPoint *) point
{
    
    BOOL isDotInClickedButton = NO;
    for (int i = 0; i < [allDots count]; i++) {
        IntegerPoint *curPoint = [allDots  objectAtIndex:i];
        if ([point isEqualToPoint:curPoint]) {
            isDotInClickedButton = YES;
        }
    }
    
    if (isDotInClickedButton) {
        return YES;
    } else {
        return NO;
    }
}

-(IntegerPoint *) pointByClickedSender: (id) sender
{
    int positionOfSender = -1;
    for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
        if ([sender isEqual:buttons[i]]) {
            positionOfSender = i;
            break;
        }
    }
    IntegerPoint *point = nil;
    point = [IntegerPoint integerPointWithX:positionOfSender % FIELD_SIZE andY:positionOfSender / FIELD_SIZE];
    return point;
}

-(void) explodeChain
{
    int n = [self calculateScore];
    score += n;
    NSLog(@"Chain is exploded for %d score; total score = %ld", n, score);
    NSLog(@"total dot count before deleting: %d", [allDots count]);
    
    for (int i = 0; i < [dotsFromCurrentChain count] - 1; i++) {
        IntegerPoint *dotFromChain = [dotsFromCurrentChain objectAtIndex:i];
        for (int j = 0; j < [allDots count]; j++) {
            IntegerPoint *dotFromListOfAll = [allDots objectAtIndex:j];
            if ([dotFromChain isEqualToPoint:dotFromListOfAll]) {
                [allDots removeObjectAtIndex:j];
                [buttons[dotFromChain.x + dotFromChain.y * FIELD_SIZE] setTitle:@"" forState:UIControlStateNormal];
                break;
            }
        }
    }
    
    for (int i = 0; i < [allPointsUsedInCurrentChain count]; i++) {
        IntegerPoint *point = [allPointsUsedInCurrentChain objectAtIndex:i];
        [buttons[point.x + point.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
    }
    
    [allPointsUsedInCurrentChain removeAllObjects];
    [dotsFromCurrentChain removeAllObjects];
    NSLog(@"total dot count after deleting: %d", [allDots count]);
}

//calculates score for exploding a chain
-(int) calculateScore
{
    int score = 0;
    
    score = [allPointsUsedInCurrentChain count];
    
    return score;
}

@end

