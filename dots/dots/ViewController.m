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
NSMutableArray *rawBarriers;
NSMutableArray *horizontalBarriers;
NSMutableArray *verticalBarriers;
NSMutableArray *barrierLabels;
NSTimer *timer1;
long int score;
int difficulty;

BOOL visited[FIELD_SIZE * FIELD_SIZE];

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Start...");
    timer1 = [NSTimer scheduledTimerWithTimeInterval:TICK
                                     target:self
                                   selector:@selector(onTick:)
                                   userInfo:nil
                                    repeats:YES];
    buttons = [NSMutableArray new];
    allDots = [NSMutableArray new];
    dotsFromCurrentChain = [NSMutableArray new];
    allPointsUsedInCurrentChain = [NSMutableArray new];
    horizontalBarriers = [NSMutableArray new];
    verticalBarriers = [NSMutableArray new];
    barrierLabels = [NSMutableArray new];
    score = 0;
    difficulty = 9;
    
    int cellWidth = [[UIScreen mainScreen] bounds].size.height / 17;
    
    CGPoint buttonStartPoint = CGPointMake([[UIScreen mainScreen] bounds].size.width * 5 / 22,
                                           [[UIScreen mainScreen] bounds].size.height * 1 / 17);
    for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
        buttons[i] = [[UIButton alloc] initWithFrame:CGRectMake(buttonStartPoint.x + i % FIELD_SIZE * cellWidth,
                                                                buttonStartPoint.y + i / FIELD_SIZE * cellWidth,
                                                                cellWidth - 1,
                                                                cellWidth - 1)];
        [buttons[i] setBackgroundColor:[UIColor redColor]];
        [buttons[i] addTarget:self action:@selector(pressBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:buttons[i]];
    }
    
    for (int i = 0; i < STARTING_DOTS_COUNT; i++) {
        [self addDotToField];
    }
    NSLog(@"Starting generating barriers...");
    
    [self generateBarriersForDifficulty:difficulty];
    
    for (int i = 0; i < [horizontalBarriers count]; i++) {
        IntegerPoint *horbar = [horizontalBarriers objectAtIndex:i];
        barrierLabels[i] = [[UILabel alloc] initWithFrame:CGRectMake(buttonStartPoint.x + (horbar.x) * cellWidth,
                                                                    (buttonStartPoint.y - 1) + (1 + horbar.y)  * cellWidth,
                                                                    cellWidth,
                                                                     3)];
        [barrierLabels[i] setBackgroundColor:[UIColor blueColor]];
        [self.view addSubview:barrierLabels[i]];
    }
    for (int i = 0; i < [verticalBarriers count]; i++) {
        IntegerPoint *vertbar = [verticalBarriers objectAtIndex:i];
        barrierLabels[i + [horizontalBarriers count]] = [[UILabel alloc] initWithFrame:CGRectMake((buttonStartPoint.x - 1) + (1 + vertbar.x) * cellWidth,
                                                                     buttonStartPoint.y + (vertbar.y)  * cellWidth,
                                                                     3,
                                                                     cellWidth)];
        [barrierLabels[i + [horizontalBarriers count]] setBackgroundColor:[UIColor blueColor]];
        [self.view addSubview:barrierLabels[i + [horizontalBarriers count]]];
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
    int rand = arc4random_uniform(FIELD_SIZE * FIELD_SIZE);
    //IntegerPoint *point = [IntegerPoint integerPointWithX:random() % FIELD_SIZE andY:random() % FIELD_SIZE];
    IntegerPoint *point = [IntegerPoint integerPointWithX:rand % FIELD_SIZE andY:rand / FIELD_SIZE];
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
                        [self removePoint];         //obratit' vnimanie. vozmojni ne slishkom ochevidnie bugi
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
    NSMutableArray *pointsToBeRemoved = [NSMutableArray new];
    
    IntegerPoint *lastPointInList = nil;
    if ([dotsFromCurrentChain count] > 0) {
        lastPointInList = [dotsFromCurrentChain lastObject];
    }
    IntegerPoint *prelastPointInChain = nil;
    if ([dotsFromCurrentChain count] > 1) {
        prelastPointInChain = [dotsFromCurrentChain objectAtIndex:[dotsFromCurrentChain count] - 2];
    }
    [pointsToBeRemoved addObject:[dotsFromCurrentChain lastObject]];
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
                IntegerPoint *pointToRemove = [allPointsUsedInCurrentChain lastObject];
                [allPointsUsedInCurrentChain removeLastObject];
                
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
                    [pointsToBeRemoved addObject:pointToRemove];
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
                    IntegerPoint *pointToRemove = [allPointsUsedInCurrentChain lastObject];
                    [allPointsUsedInCurrentChain removeLastObject];
                    
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
                        [pointsToBeRemoved addObject:pointToRemove];
                    }
                }
            }
    } else {
        [allPointsUsedInCurrentChain removeLastObject];
    }
    
    for (int i = 0; i < [pointsToBeRemoved count]; i++) {
        IntegerPoint *pointToMarkAsUnused = [pointsToBeRemoved objectAtIndex:i];
        [buttons[pointToMarkAsUnused.x + pointToMarkAsUnused.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
    }
    
    if (prelastPointInChain) {
        [buttons[prelastPointInChain.x + prelastPointInChain.y * FIELD_SIZE] setBackgroundColor:[UIColor greenColor]];
    }
    
    NSLog(@"line length = %d", [allPointsUsedInCurrentChain count]);
}

-(BOOL) addPoint: (IntegerPoint*) nextPoint
{
    NSMutableArray *pointsToBeAdded = [NSMutableArray new];
    IntegerPoint *lastPointInChain = nil;
    
    if ([dotsFromCurrentChain count] > 0) {
        lastPointInChain = [dotsFromCurrentChain lastObject];
    }
    
    if (!nextPoint) {
        return NO;
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
                    [pointsToBeAdded addObject:pointToAdd];
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
                        [pointsToBeAdded addObject:pointToAdd];
                    }
                }
            
        } else {
            [allPointsUsedInCurrentChain addObject:nextPoint];
        }
        NSLog(@"DOTS CHECKED: %d", [dotsFromCurrentChain count]);
        NSLog(@"line length = %d", [allPointsUsedInCurrentChain count]);
        for (int i = 0; i < [pointsToBeAdded count]; i++) {
            IntegerPoint *pointToBeAdded = [pointsToBeAdded objectAtIndex:i];
            [buttons[pointToBeAdded.x + pointToBeAdded.y * FIELD_SIZE] setBackgroundColor:[UIColor yellowColor]];
        }
        [buttons[nextPoint.x + nextPoint.y * FIELD_SIZE] setBackgroundColor:[UIColor greenColor]];
        
        IntegerPoint *firstPointInChain = [dotsFromCurrentChain firstObject];
        lastPointInChain = [dotsFromCurrentChain lastObject];
        if ([firstPointInChain isEqualToPoint:lastPointInChain] &&
            [dotsFromCurrentChain count] >= 4) {
            [self explodeChain];
        }

        return YES;
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
        NSLog(@"Cannot add a dot by intersecting a dot already in list (x)");
        return nil;
    }
    //check for horizontal barriers
    for (int i = 0; i < [horizontalBarriers count]; i++) {
        IntegerPoint *barrier = [horizontalBarriers objectAtIndex:i];
        startCoord = (lastPointInChain.y < ip.y) ? lastPointInChain.y : ip.y;
        endCoord = (lastPointInChain.y > ip.y) ? lastPointInChain.y : ip.y;
        for (int j = startCoord; j < endCoord; j++) {
            IntegerPoint *pointToCheck = [IntegerPoint integerPointWithX:ip.x andY:j];
            if ([barrier isEqualToPoint:pointToCheck]) {
                NSLog(@"Cannot add a dot by intersecting a horizontal barrier");
                return nil;
            }
        }
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
        NSLog(@"Cannot add a dot by intersecting a dot already in list (y)");
        return nil;
    }
    
    //check for vertical barriers
    for (int i = 0; i < [verticalBarriers count]; i++) {
        IntegerPoint *barrier = [verticalBarriers objectAtIndex:i];
        startCoord = (lastPointInChain.x < ip.x) ? lastPointInChain.x : ip.x;
        endCoord = (lastPointInChain.x > ip.x) ? lastPointInChain.x : ip.x;
        for (int j = startCoord; j < endCoord; j++) {
            IntegerPoint *pointToCheck = [IntegerPoint integerPointWithX:j andY:ip.y];
            if ([barrier isEqualToPoint:pointToCheck]) {
                NSLog(@"Cannot add a dot by intersecting a vertical barrier");
                return nil;
            }
        }
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
    NSMutableArray *dotsToBeRemoved = [NSMutableArray new];
    NSMutableArray *pointsToBeRemoved = [NSMutableArray new];
    int n = [self calculateScore];
    score += n;
    NSLog(@"Chain is exploded for %d score; total score = %ld", n, score);
    NSLog(@"total dot count before deleting: %d", [allDots count]);
    
    for (int i = 0; i < [allPointsUsedInCurrentChain count]; i++) {
        IntegerPoint *pointToRemove = [allPointsUsedInCurrentChain objectAtIndex:i];
        [pointsToBeRemoved addObject:pointToRemove];
    }
    
    for (int i = 0; i < [dotsFromCurrentChain count] - 1; i++) {
        IntegerPoint *dotFromChain = [dotsFromCurrentChain objectAtIndex:i];
        for (int j = 0; j < [allDots count]; j++) {
            IntegerPoint *dotFromListOfAll = [allDots objectAtIndex:j];
            if ([dotFromChain isEqualToPoint:dotFromListOfAll]) {
                [dotsToBeRemoved addObject:[allDots objectAtIndex:j]];
                [allDots removeObjectAtIndex:j];
                break;
            }
        }
    }
    
    for (int i = 0; i < [dotsToBeRemoved count]; i++) {
        IntegerPoint *pointToRemove = [dotsToBeRemoved objectAtIndex:i];
        [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setTitle:@"" forState:UIControlStateNormal];
    }
    for (int i = 0; i < [pointsToBeRemoved count]; i++) {
        IntegerPoint *pointToRemove = [pointsToBeRemoved objectAtIndex:i];
        [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
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

//каждая ячейка - вершина графа
//нагенерировать очередной барьер
//проверить, у всех ли вершин осталось количество связей > 1
//если нет, удалить барьер, нагенерировать снова
//когда нагенерировано нужное количество барьеров
//совершить обход графа
//если можно посетить все точки, задача выполнена

//на данном этапе барьер представляется как ячейка матрицы смежности, т.е. показывает, между какими двумя ячейками разорвана связь
//позднее это нужно преобразовать в 2 массива (горизонтальных и вертикальных) барьеров

-(void) generateBarriersForDifficulty:(int) difficulty
{
    int field_etal[FIELD_SIZE * FIELD_SIZE][FIELD_SIZE * FIELD_SIZE];
    int field[FIELD_SIZE * FIELD_SIZE][FIELD_SIZE * FIELD_SIZE];
    int numberOfConnections = 0;
    int barriersCount = [self numberOfBarriersForDifficulty:difficulty];
    //сгенерируем матрицу смежности
    for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
        for (int j = 0; j < FIELD_SIZE * FIELD_SIZE; j++) {
            if ((abs(i - j) == 1 || abs(i - j) == FIELD_SIZE) &&    //если соседи по горизонтали или вертикали
                ((i % FIELD_SIZE == j % FIELD_SIZE) ||              //если находятся на одной линии
                (i / FIELD_SIZE == j / FIELD_SIZE))) {
                field[i][j] = 1;
                field_etal[i][j] = 1;
                numberOfConnections++;
            } else {
                field[i][j] = 0;
                field_etal[i][j] = 0;
            }
        }
    }
    BOOL barriersAreCorrect = NO;
    int numberOfGenerationTries = 0;
    while (!barriersAreCorrect) {
        rawBarriers = [NSMutableArray new];
        numberOfGenerationTries++;
        for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
            for (int j = 0; j < FIELD_SIZE * FIELD_SIZE; j++) {
                field[i][j] = field_etal[i][j];
            }
        }
        for (int k = 0; k < barriersCount; k++) {
            IntegerPoint *newBarrier = [self generateBarrierForField:field usingEtal:field_etal andNumberOfConnections:numberOfConnections];
            [rawBarriers addObject:newBarrier];
            field[newBarrier.x][newBarrier.y] = 0;
            field[newBarrier.y][newBarrier.x] = 0;
        }
        barriersAreCorrect = [self checkBarriersForField:field];
    }
//    for (int i = 0; i < [rawBarriers count]; i++) {
//        IntegerPoint *barrier = [rawBarriers objectAtIndex:i];
//        NSLog(@"barrier %d : %d %d", i, barrier.x, barrier.y);
//    }

    NSLog(@"tried to generate %d times", numberOfGenerationTries);
    
    for (int i = 0; i < [rawBarriers count]; i++) {
        IntegerPoint *barrier = [rawBarriers objectAtIndex:i];
        if (barrier.x > barrier.y) {
            barrier = [IntegerPoint integerPointWithX:barrier.y andY:(barrier.x)];
        }
        IntegerPoint *firstPoint = [IntegerPoint integerPointWithX:barrier.x % FIELD_SIZE andY:barrier.x / FIELD_SIZE];
        IntegerPoint *secondPoint = [IntegerPoint integerPointWithX:barrier.y % FIELD_SIZE andY:barrier.y / FIELD_SIZE];
        if (firstPoint.x < secondPoint.x) { //vertical
            [verticalBarriers addObject:firstPoint];
        } else {                            //horizontal
            [horizontalBarriers addObject:firstPoint];
        }
    }
//    for (int i = 0; i < [horizontalBarriers count]; i++) {
//        IntegerPoint *horbar = [horizontalBarriers objectAtIndex:i];
//        NSLog(@"horizontal barrier %d : %d %d", i, horbar.x, horbar.y);
//    }
//    for (int i = 0; i < [verticalBarriers count]; i++) {
//        IntegerPoint *vertbar = [verticalBarriers objectAtIndex:i];
//        NSLog(@"vertical barrier %d : %d %d", i, vertbar.x, vertbar.y);
//    }
//    for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
//        NSString *s = [NSString stringWithFormat:@"%d ", i];
//        for (int j = 0; j < FIELD_SIZE * FIELD_SIZE; j++) {
//            s = [s stringByAppendingString:[NSString stringWithFormat:@"%d", field[i][j]]];
//        }
//        NSLog(@"%@", s);
//    }
    
//    NSLog(@"number of connections: %d", numberOfConnections);
}

-(int) numberOfBarriersForDifficulty:(int) difficulty
{
    int barriersCount = 0;
    switch (difficulty) {
        case 0: case 1: case 2: case 3: barriersCount = difficulty * 4; break;
        case 4: barriersCount = 15; break;
        case 5: barriersCount = 18; break;
        case 6: barriersCount = 20; break;
        case 7: barriersCount = 22; break;
        case 8: barriersCount = 24; break;
        case 9: barriersCount = 26; break;
    }
    return barriersCount;
}

-(IntegerPoint *) generateBarrierForField:(int[FIELD_SIZE * FIELD_SIZE][FIELD_SIZE * FIELD_SIZE]) field
                                usingEtal:(int[FIELD_SIZE * FIELD_SIZE][FIELD_SIZE * FIELD_SIZE]) field_etal
                                andNumberOfConnections:(int) numberOfConnections
{
    IntegerPoint *ip = nil;
    BOOL isGenerated = NO;
    while (!isGenerated) {
        int newBarrierPosition = arc4random_uniform(numberOfConnections);
        int currentlyPassedConnections = 0;
        BOOL failedToGenerate = NO;
        for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
            if (!failedToGenerate) {
                for (int j = 0; j < FIELD_SIZE * FIELD_SIZE; j++) {
                    if (field_etal[i][j] == 1) {
                        if (currentlyPassedConnections < newBarrierPosition) {
                            currentlyPassedConnections++;
                        } else {
                            int connectionsForCurrentPoint1Count = 0;
                            for (int p = 0; p < FIELD_SIZE * FIELD_SIZE; p++) {
                                if (field[p][j] == 1) {
                                    connectionsForCurrentPoint1Count++;
                                }
                            }
                            int connectionsForCurrentPoint2Count = 0;
                            for (int p = 0; p < FIELD_SIZE * FIELD_SIZE; p++) {
                                if (field[i][p] == 1) {
                                    connectionsForCurrentPoint2Count++;
                                }
                            }
                            if (connectionsForCurrentPoint1Count > 2 && connectionsForCurrentPoint2Count > 2) {
                                ip = [IntegerPoint integerPointWithX:i andY:j];
                                IntegerPoint *ipr = [IntegerPoint integerPointWithX:ip.y andY:ip.x];
                                BOOL alreadyInBarrierList = NO;
                                for (int q = 0; q < [rawBarriers count]; q++) {
                                    IntegerPoint *alreadyGeneratedBarrier = [rawBarriers objectAtIndex:q];
                                    if ([ip isEqualToPoint:alreadyGeneratedBarrier] || [ipr isEqualToPoint:alreadyGeneratedBarrier]) {
                                        alreadyInBarrierList = YES;
                                    }
                                }
                                if (alreadyInBarrierList) {
                                    currentlyPassedConnections = 0;
                                    failedToGenerate = YES;
                                    break;
                                } else {
                                    field[i][j] = 0;
                                    field[j][i] = 0;
                                    return ip;
                                }
                            } else {
                                currentlyPassedConnections = 0;
                                failedToGenerate = YES;
                                break;
                            }
                            
                        }
                    }
                }
            } else {
                break;
            }
        }
    }
    return ip;
}

-(BOOL) checkBarriersForField:(int[FIELD_SIZE * FIELD_SIZE][FIELD_SIZE * FIELD_SIZE]) field
{
    for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
        visited[i] = NO;
    }
    [self dfs:0 field:field];
    for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
        if (!visited[i]) {
            return NO;
        }
    }
    return YES;
}

-(void)dfs: (int) v field:(int[FIELD_SIZE * FIELD_SIZE][FIELD_SIZE * FIELD_SIZE]) field
{
    visited[v] = YES;
    for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
        if (field[v][i] == 1 && !visited[i]) {
            [self dfs:i field:field];
        }
    }
}
//вызывать чтобы проиграть жалобный звук
-(void) actionIsImpossible
{
    NSLog(@"this action is impossible");
}

-(void) detectBonuses
{
    
}

@end

