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
            [buttons[lastPointInList.x + lastPointInList.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
            [dotsFromCurrentChain removeLastObject];
            return;
        }
        // if same x
        if (lastPointInList.x == clickedPoint.x) {
            if (prelastPointInList == nil) {
                int startCoord = (lastPointInList.y < clickedPoint.y) ? lastPointInList.y : clickedPoint.y;
                int endCoord = (lastPointInList.y > clickedPoint.y) ? lastPointInList.y : clickedPoint.y;
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
                            return;
                        }
                        clickedPoint = pointMostCloseToLast;
                        positionOfSender = clickedPoint.x + clickedPoint.y * FIELD_SIZE;
                    }
                }
                [dotsFromCurrentChain addObject:clickedPoint];
                NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
                [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
            } else {
                if (lastPointInList.x == prelastPointInList.x) {
                    if (((clickedPoint.y - lastPointInList.y) < 0 && (lastPointInList.y - prelastPointInList.y) < 0) ||
                        ((clickedPoint.y - lastPointInList.y) > 0 && (lastPointInList.y - prelastPointInList.y) > 0)) {
                        
                        int startCoord = (lastPointInList.y < clickedPoint.y) ? lastPointInList.y : clickedPoint.y;
                        int endCoord = (lastPointInList.y > clickedPoint.y) ? lastPointInList.y : clickedPoint.y;
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
                                    return;
                                }
                                clickedPoint = pointMostCloseToLast;
                                positionOfSender = clickedPoint.x + clickedPoint.y * FIELD_SIZE;
                            }
                        }
                        [dotsFromCurrentChain addObject:clickedPoint];
                        NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
                        [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
                    } else {
                        [buttons[lastPointInList.x + lastPointInList.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
                        [dotsFromCurrentChain removeLastObject];
                    }
                }
                if (lastPointInList.y == prelastPointInList.y) {
                    
                    int startCoord = (lastPointInList.y < clickedPoint.y) ? lastPointInList.y : clickedPoint.y;
                    int endCoord = (lastPointInList.y > clickedPoint.y) ? lastPointInList.y : clickedPoint.y;
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
                                return;
                            }
                            clickedPoint = pointMostCloseToLast;
                            positionOfSender = clickedPoint.x + clickedPoint.y * FIELD_SIZE;
                        }
                    }
                    [dotsFromCurrentChain addObject:clickedPoint];
                    NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
                    [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
                }
            }
            
            
        }
        
        // if same y
        if (lastPointInList.y == clickedPoint.y) {
            if (prelastPointInList == nil) {
                
                int startCoord = (lastPointInList.x < clickedPoint.x) ? lastPointInList.x : clickedPoint.x;
                int endCoord = (lastPointInList.x > clickedPoint.x) ? lastPointInList.x : clickedPoint.x;
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
                            return;
                        }
                        clickedPoint = pointMostCloseToLast;
                        positionOfSender = clickedPoint.x + clickedPoint.y * FIELD_SIZE;
                    }
                }
                [dotsFromCurrentChain addObject:clickedPoint];
                NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
                [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
            } else {
                if (lastPointInList.y == prelastPointInList.y) {
                    if (((clickedPoint.x - lastPointInList.x) < 0 && (lastPointInList.x - prelastPointInList.x) < 0) ||
                        ((clickedPoint.x - lastPointInList.x) > 0 && (lastPointInList.x - prelastPointInList.x) > 0)) {
                        
                        int startCoord = (lastPointInList.x < clickedPoint.x) ? lastPointInList.x : clickedPoint.x;
                        int endCoord = (lastPointInList.x > clickedPoint.x) ? lastPointInList.x : clickedPoint.x;
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
                                    return;
                                }
                                clickedPoint = pointMostCloseToLast;
                                positionOfSender = clickedPoint.x + clickedPoint.y * FIELD_SIZE;
                            }
                        }
                        [dotsFromCurrentChain addObject:clickedPoint];
                        NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
                        [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
                    } else {
                        [buttons[lastPointInList.x + lastPointInList.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
                        [dotsFromCurrentChain removeLastObject];
                    }
                }
                if (lastPointInList.x == prelastPointInList.x) {
                    
                    int startCoord = (lastPointInList.x < clickedPoint.x) ? lastPointInList.x : clickedPoint.x;
                    int endCoord = (lastPointInList.x > clickedPoint.x) ? lastPointInList.x : clickedPoint.x;
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
                                return;
                            }
                            clickedPoint = pointMostCloseToLast;
                            positionOfSender = clickedPoint.x + clickedPoint.y * FIELD_SIZE;
                        }
                    }
                    [dotsFromCurrentChain addObject:clickedPoint];
                    NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
                    [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
                }

            }
            
        }
    } else {
        [dotsFromCurrentChain addObject:clickedPoint];
        NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
        [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
    }
   // [buttons[positionOfSender] setBackgroundColor:[UIColor greenColor]];
}

@end
