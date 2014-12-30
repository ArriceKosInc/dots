//
//  ViewController.m
//  dots
//
//  Created by Admin on 24.12.14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "ViewController.h"
#import "Bonus.h"
#import <QuartzCore/QuartzCore.h>
#import "DACircularProgressView.h"
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
NSMutableArray *barrierImages;
NSMutableArray *bonuses;
NSMutableArray *bonusImages;
NSMutableArray *activatedBonusImages;
NSMutableArray *activatedBonuses;
NSMutableArray *bonusProgressViews;
NSMutableArray *bonusRemainingTicks;
NSMutableArray *bonusTimers;
NSTimer *timer1;
NSTimer *timer2;

long int score;
int difficulty;
int speed;
BOOL barriersAreActive;
BOOL ignoreBarriersBonusIsActivatedTwice;
float scoreModifier;
int maximumDotLimit;
float tickDuration;
BOOL isGameOver;

BOOL visited[FIELD_SIZE * FIELD_SIZE];

//реализовать режим динамически изменяемой скорости. в этом режиме скорость изменяется каждые там условные 20 секунд, во время смены скорости заново генерируются барьеры
//необходимо рассмотреть, что делать в этом случае с текущей цепью. возможно, генерировать их после замыкания или разрыва цепи
//реализовать паузу
//количество очков набранное за цепь показывать в центре, затем оно уезжает вверх
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Start...");
    [self.backgroundGameOverView setHidden:YES];
    [self.gameOverView setHidden:YES];
    buttons = [NSMutableArray new];
    allDots = [NSMutableArray new];
    dotsFromCurrentChain = [NSMutableArray new];
    allPointsUsedInCurrentChain = [NSMutableArray new];
    horizontalBarriers = [NSMutableArray new];
    verticalBarriers = [NSMutableArray new];
    barrierImages = [NSMutableArray new];
    bonuses = [NSMutableArray new];
    bonusImages = [NSMutableArray new];
    activatedBonusImages = [NSMutableArray new];
    activatedBonuses = [NSMutableArray new];
    bonusProgressViews = [NSMutableArray new];
    bonusRemainingTicks = [NSMutableArray new];
    bonusTimers = [NSMutableArray new];
    
    score = SCORE_INITIAL;
    difficulty = 1;
    speed = 5;
    tickDuration = [self tickDurationForSpeed:speed];
    barriersAreActive = YES;
    ignoreBarriersBonusIsActivatedTwice = NO;
    scoreModifier = SCORE_MODIFIER_NORMAL;
    maximumDotLimit = MAXIMUM_DOT_COUNT_INITIAL;
    isGameOver = NO;

    
    //возможно, перенести в конец метода, если время его работы будет соизмеримо с длиной тика на самой высокой скорости
    timer1 = [NSTimer scheduledTimerWithTimeInterval:tickDuration
                                              target:self
                                            selector:@selector(onTick:)
                                            userInfo:nil
                                             repeats:YES];
    //создать таймер для спауна бонусов
    timer2 = [NSTimer scheduledTimerWithTimeInterval:BONUS_SPAWN_COOLDOWN
                                              target:self
                                            selector:@selector(addBonusToField:)
                                            userInfo:nil
                                             repeats:YES];
    
    
    int cellWidth = [[UIScreen mainScreen] bounds].size.height / 17;
    
    CGPoint buttonStartPoint = CGPointMake([[UIScreen mainScreen] bounds].size.width * 4 / 22,
                                           [[UIScreen mainScreen] bounds].size.height * 1.5 / 17);
    for (int i = 0; i < FIELD_SIZE * FIELD_SIZE; i++) {
        buttons[i] = [[UIButton alloc] initWithFrame:CGRectMake(buttonStartPoint.x + i % FIELD_SIZE * (cellWidth + 3),
                                                                buttonStartPoint.y + i / FIELD_SIZE * (cellWidth + 3),
                                                                cellWidth - 1,
                                                                cellWidth - 1)];
//        [buttons[i] setBackgroundColor:[UIColor redColor]];
        UIButton *button = buttons[i];
        button.layer.cornerRadius = button.bounds.size.width/2.0;
        [buttons[i] setBackgroundColor:[UIColor lightGrayColor]];
        [buttons[i] addTarget:self action:@selector(pressBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:buttons[i]];
    }
    
    _removeAllChainButton.layer.cornerRadius = _removeAllChainButton.bounds.size.width/2.0;
    [_removeAllChainButton setBackgroundColor:[UIColor lightGrayColor]];
    [self.view bringSubviewToFront:_removeAllChainButton];
    
    for (int i = 0; i < STARTING_DOTS_COUNT; i++) {
        [self addDotToField];
    }
    
    [self generateBarriersForDifficulty:difficulty];
    
    for (int i = 0; i < [horizontalBarriers count]; i++) {
        IntegerPoint *horbar = [horizontalBarriers objectAtIndex:i];
        barrierImages[i] = [[UILabel alloc] initWithFrame:CGRectMake(buttonStartPoint.x + (horbar.x) * (cellWidth + 3),
                                                                    (buttonStartPoint.y - 3) + (1 + horbar.y)  * (cellWidth + 3),
                                                                    cellWidth,
                                                                     3)];
        [barrierImages[i] setBackgroundColor:[UIColor blueColor]];
        [self.view addSubview:barrierImages[i]];
    }
    for (int i = 0; i < [verticalBarriers count]; i++) {
        IntegerPoint *vertbar = [verticalBarriers objectAtIndex:i];
        barrierImages[i + [horizontalBarriers count]] = [[UILabel alloc] initWithFrame:CGRectMake((buttonStartPoint.x - 3) + (1 + vertbar.x) * (cellWidth + 3),
                                                                     buttonStartPoint.y + (vertbar.y)  * (cellWidth + 3),
                                                                     3,
                                                                     cellWidth)];
        [barrierImages[i + [horizontalBarriers count]] setBackgroundColor:[UIColor blueColor]];
        [self.view addSubview:barrierImages[i + [horizontalBarriers count]]];
    }

  	// Do any additional setup after loading the view, typically from a nib.
//    DACircularProgressView *progressView;
//    progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 500.0f, 500.0f)];
//    progressView.roundedCorners = NO;
//    progressView.thicknessRatio = 1.0f;
//    progressView.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0];
//    progressView.progressTintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
//    [self.view addSubview:progressView];
//    [self.view bringSubviewToFront:progressView];
//    progressView.progress = 0.6;
}

-(void)onTick:(NSTimer *)timer {
    [self addDotToField];
    [_scoreLbl setText:[NSString stringWithFormat:@"%ld", score]];
    if ([allDots count] > maximumDotLimit) {
        [timer1 invalidate];
        [timer2 invalidate];
        [self.view bringSubviewToFront:self.backgroundGameOverView];
        [self.backgroundGameOverView setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.5]];
        [self.backgroundGameOverView setHidden:NO];
        [self.gameOverView setHidden:NO];
        [self.gameOverView setAlpha:1.0];
        [_gameOverScoreLbl setText:[NSString stringWithFormat:@"%ld", score]];
        isGameOver = YES;
        NSLog(@"game over");
    }
}

- (IBAction)backToMenuButtonTapped:(id)sender {
    [timer1 invalidate];
    [timer2 invalidate];
    //zapisat' skor
}

- (IBAction)retryButtonPressed:(id)sender {
    [self loadView];
}

- (IBAction)removeCurrentChain:(id)sender {
    
    NSMutableArray *pointsToBeRemoved = [NSMutableArray new];
    
    for (int i = 0; i < [allPointsUsedInCurrentChain count]; i++) {
        IntegerPoint *pointToRemove = [allPointsUsedInCurrentChain objectAtIndex:i];
        [pointsToBeRemoved addObject:pointToRemove];
    }
    for (int i = 0; i < [pointsToBeRemoved count]; i++) {
        IntegerPoint *pointToRemove = [pointsToBeRemoved objectAtIndex:i];
        [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setBackgroundColor:[UIColor lightGrayColor]];
    }
    
    [allPointsUsedInCurrentChain removeAllObjects];
    [dotsFromCurrentChain removeAllObjects];

}

- (IntegerPoint *)getRandomPoint
{
    BOOL match;
    IntegerPoint *ip = nil;
    do {
        match = NO;
        int rand = arc4random_uniform(FIELD_SIZE * FIELD_SIZE);
        ip = [IntegerPoint integerPointWithX:rand % FIELD_SIZE andY:rand / FIELD_SIZE];
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
        if (!match) {
            for (int i = 0; i < [bonuses count]; i++) {
                Bonus *pointFromArray = [bonuses objectAtIndex:i];
                if ([pointFromArray.position isEqualToPoint:ip]) {
                    match = YES;
                    break;
                }
            }
        }
    } while (match);
    return ip;
}
////////////////////////////////////////////////////////////
- (BonusType)getRandomBonusType
{
    BOOL bonusTypeDotLimitIsAllowed = YES;
    BOOL bonusTypeLowerSpeedIsAllowed = YES;
    BonusType rand = 0;
    if (maximumDotLimit >= MAXIMUM_DOT_COUNT_LIMIT) {
        bonusTypeDotLimitIsAllowed = NO;
    }
    if (speed == MINIMUM_SPEED) {
        bonusTypeLowerSpeedIsAllowed = NO;
    }
    do {
        rand = arc4random_uniform(numBonusTypes);
    } while ((!bonusTypeLowerSpeedIsAllowed && rand == BonusTypeLowerSpeed) ||
             (!bonusTypeDotLimitIsAllowed && rand == BonusTypeDotLimit));
    return rand;
}

//переделать для случая, когда активирован бонус добавления точки в любое место
- (void)addDotToField
{
    IntegerPoint *ip = [self getRandomPoint];
    [allDots addObject:ip];
    [buttons[ip.x + ip.y * FIELD_SIZE] setTitle:@"x" forState:UIControlStateNormal];
    //типа анимировать появление точки
}

- (void)addBonusToField:(NSTimer *)timer
{
    IntegerPoint *ip = [self getRandomPoint];
    //choose bonus type
    BonusType bt = [self getRandomBonusType];
    Bonus *bonus = [[Bonus alloc] init];
    bonus.position = ip;
    bonus.bonusType = bt;
    [bonuses addObject:bonus];
    int cellWidth = [[UIScreen mainScreen] bounds].size.height / 17;
    CGPoint buttonStartPoint = CGPointMake([[UIScreen mainScreen] bounds].size.width * 4 / 22,
                                           [[UIScreen mainScreen] bounds].size.height * 1.5 / 17);
    
    UILabel *bonusLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonStartPoint.x + ip.x * (cellWidth + 3),
                                                                 buttonStartPoint.y + ip.y  * (cellWidth + 3),
                                                                 cellWidth - 1,
                                                                 cellWidth - 1)];
//    bonusLabel.layer.cornerRadius = bonusLabel.bounds.size.width/2.0;
    bonusLabel.layer.masksToBounds = YES;
    [bonusLabel.layer setCornerRadius:bonusLabel.bounds.size.width/2.0];
    [bonusLabel setBackgroundColor:[UIColor greenColor]];
    [bonusLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view bringSubviewToFront:bonusLabel];
    switch (bonus.bonusType) {
        case BonusTypeIgnoreBarriers:
            [bonusLabel setText:@"I"];
            break;
        case BonusTypeScoreModifier:
            [bonusLabel setText:@"S"];
            break;
        //case BonusTypeAdditionalPoint:
        case BonusTypeDotLimit:
            [bonusLabel setText:@"D"];
            break;
        case BonusTypeLowerSpeed:
            [bonusLabel setText:@"L"];
            break;
        default: [NSException raise:@"bonus_type_exception" format:@"invalid bonus type"];
            break;
    }
    
    
    [self.view addSubview:bonusLabel];
    [bonusImages addObject:bonusLabel];
    
    NSString *bonusInfo = [bonus toString];
    [NSTimer scheduledTimerWithTimeInterval:bonus.lifeTime
                                                      target:self
                                                    selector:@selector(prepareRemovingBonus:)
                                                    userInfo:bonusInfo
                                                     repeats:NO];
    
}

-(void) prepareRemovingBonus:(NSTimer *)theTimer
{
    NSString *bonusInfo = (NSString *)[theTimer userInfo];
    Bonus *bonus = [Bonus bonusFromString:bonusInfo];
    [self removeBonusFromField:bonus activate:NO];
}

-(void)removeBonusFromField:(Bonus *) bonus activate:(BOOL) activate
{
    for (int i = 0; i < [bonuses count]; i++) {
        Bonus *bon = [bonuses objectAtIndex:i];
        if ([bonus isEqualToBonus:bon]) {
            if (activate) {
                [self activateBonus:bonus];
                UILabel *image = [bonusImages objectAtIndex:i];
                [activatedBonusImages addObject:image];
                int cellWidth = [[UIScreen mainScreen] bounds].size.height / 17;
                CGPoint bonusStartPoint = CGPointMake([[UIScreen mainScreen] bounds].size.width * 27 / 22,
                                                       [[UIScreen mainScreen] bounds].size.height * 1 / 17);
                [UIView animateWithDuration:0.3 animations:^{  // animate the following:
                    image.frame = CGRectMake(bonusStartPoint.x,
                                             bonusStartPoint.y + (cellWidth + 3) * [activatedBonusImages count],
                                             image.frame.size.width,
                                             image.frame.size.height); // move to new location
                }];
                DACircularProgressView *progressView;
                progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(bonusStartPoint.x,
                                                                                        bonusStartPoint.y + (cellWidth + 3) * [activatedBonusImages count],
                                                                                        image.frame.size.width,
                                                                                        image.frame.size.height)];
                progressView.roundedCorners = NO;
                progressView.thicknessRatio = 1.0f;
                progressView.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0];
                progressView.progressTintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
                [self.view addSubview:progressView];
                [self.view bringSubviewToFront:progressView];
                progressView.progress = 0.0f;
                [bonusProgressViews addObject:progressView];
                [bonusRemainingTicks addObject:[NSNumber numberWithInt:(int)(bonus.effectDuration / BONUS_TIME_REFRESH_TICK)]];
                NSLog(@"%d",(int)(bonus.effectDuration / BONUS_TIME_REFRESH_TICK));
                [activatedBonuses addObject:bonus];
                NSTimer *timer;
                NSString *bonusInfo = [bonus toString];
                timer = [NSTimer scheduledTimerWithTimeInterval:BONUS_TIME_REFRESH_TICK
                                                 target:self
                                               selector:@selector(bonusEffectAnimation:)
                                               userInfo:bonusInfo
                                                repeats:YES];
                [bonusTimers addObject:timer];
            } else {
                //типа анимировать исчезновение бонуса
                UILabel *image = [bonusImages objectAtIndex:i];
                [image removeFromSuperview];
            }
            
//            UILabel *image = [bonusImages objectAtIndex:i];
//            [image removeFromSuperview];
//            
//            [bonusImages removeObjectAtIndex:i];
            [bonuses removeObjectAtIndex:i];    /////???????????????????????????????
            [bonusImages removeObjectAtIndex:i];
            return;
        }
    }
}
//сделать что-то с бонусом предела точек. придумать, как он будет отображаться, т.к. он единственный, который не имеет продолжительности
-(void)bonusEffectAnimation:(NSTimer *) theTimer
{
    NSString *bonusInfo = (NSString *)[theTimer userInfo];
    Bonus *bonus = [Bonus bonusFromString:bonusInfo];
    for (int i = 0; i < [activatedBonuses count]; i++) {
        Bonus *bon = [activatedBonuses objectAtIndex:i];
        if ([bonus isEqualToBonus:bon]) {
            DACircularProgressView *progressView = [bonusProgressViews objectAtIndex:i];
            NSNumber *remainingTicks = [bonusRemainingTicks objectAtIndex:i];
            remainingTicks = [NSNumber numberWithInt:[remainingTicks intValue] - 1];
            [bonusRemainingTicks replaceObjectAtIndex:i withObject:remainingTicks];
            progressView.progress += 1. / bonus.effectDuration * BONUS_TIME_REFRESH_TICK;
            if ([remainingTicks intValue] == 0) {   //типа тоже добавить анимацию исчезновения бонуса итд
                NSLog(@"bonusu privet + %@", [bonus toString]);
                NSTimer *timer = [bonusTimers objectAtIndex:i];
                [timer invalidate];
                [progressView removeFromSuperview];
                UILabel *label = [activatedBonusImages objectAtIndex:i];
                [label removeFromSuperview];
                [activatedBonuses removeObjectAtIndex:i];
                [activatedBonusImages removeObjectAtIndex:i];
                [bonusProgressViews removeObjectAtIndex:i];
                [bonusRemainingTicks removeObjectAtIndex:i];
                [bonusTimers removeObjectAtIndex:i];
                
                int cellWidth = [[UIScreen mainScreen] bounds].size.height / 17;
                CGPoint bonusStartPoint = CGPointMake([[UIScreen mainScreen] bounds].size.width * 27 / 22,
                                                      [[UIScreen mainScreen] bounds].size.height * 1 / 17);
                for (int k = 0; k < [activatedBonusImages count]; k++) {
                    UILabel *activatedBonusImage = [activatedBonusImages objectAtIndex:k];
                    DACircularProgressView *progressView = [bonusProgressViews objectAtIndex:k];
                    
                    [UIView animateWithDuration:0.3 animations:^{
                        activatedBonusImage.frame = CGRectMake(bonusStartPoint.x,
                                                 activatedBonusImage.frame.origin.y - (cellWidth + 3),
                                                 activatedBonusImage.frame.size.width,
                                                 activatedBonusImage.frame.size.height);
                        progressView.frame = CGRectMake(bonusStartPoint.x,
                                                               progressView.frame.origin.y - (cellWidth + 3),
                                                               progressView.frame.size.width,
                                                               progressView.frame.size.height);
                    }];
                }
            }
        }
    }
}

-(void)pressBtn: (id)sender
{
    IntegerPoint *clickedPoint = [self pointByClickedSender:sender];
    if (![self pointContainsDot:clickedPoint]) {
        NSLog(@"No dot in this point");
        return;
    }

    if ([dotsFromCurrentChain count] == 1) {
        IntegerPoint *nextPointToAdd = nil;
        IntegerPoint *lastPointInChain = [dotsFromCurrentChain lastObject];
        if (clickedPoint.x != lastPointInChain.x && clickedPoint.y != lastPointInChain.y) {
            [self removePoint];
            [self addPoint:clickedPoint];
            return;
        }
        if (clickedPoint.x == lastPointInChain.x) {
            int dotsToAddInARow = 0;
            nextPointToAdd = lastPointInChain;
            while (![nextPointToAdd isEqualToPoint:clickedPoint]) {
                dotsToAddInARow++;
                nextPointToAdd = [self detectNextPointEqualByX:clickedPoint fromPoint:nextPointToAdd];
                NSLog(@"%d %d", nextPointToAdd.x, nextPointToAdd.y);
                if (!nextPointToAdd) {
                    [self removePoint];
                    [self addPoint:clickedPoint];
                    NSLog(@"replacing first point");
                    return;
                }
            }
        } else if (clickedPoint.y == lastPointInChain.y) {
            int dotsToAddInARow = 0;
            nextPointToAdd = lastPointInChain;
            while (![nextPointToAdd isEqualToPoint:clickedPoint]) {
                dotsToAddInARow++;
                nextPointToAdd = [self detectNextPointEqualByY:clickedPoint fromPoint:nextPointToAdd];
                NSLog(@"%d %d", nextPointToAdd.x, nextPointToAdd.y);
                if (!nextPointToAdd) {
                    [self removePoint];
                    [self addPoint:clickedPoint];
                    NSLog(@"replacing first point");
                    return;
                }
            }
        }
    }
    
    if ([dotsFromCurrentChain count] > 1) {
        IntegerPoint *firstPointInChain = [dotsFromCurrentChain firstObject];
        IntegerPoint *lastPointInChain = [dotsFromCurrentChain lastObject];
        IntegerPoint *nextPointToAdd = nil;
        
        if ([dotsFromCurrentChain count] == 2 && [clickedPoint isEqualToPoint:firstPointInChain]) {
            [self removeCurrentChain:nil];
            NSLog(@"chain is destroyed by clicking first point?");
            return;
        }
        
        if ([clickedPoint isEqualToPoint:firstPointInChain]) {
            if (firstPointInChain.x == lastPointInChain.x) {
                int dotsToAddInARow = 0;
                nextPointToAdd = lastPointInChain;
                while (![nextPointToAdd isEqualToPoint:clickedPoint]) {
                    dotsToAddInARow++;
                    nextPointToAdd = [self detectNextPointEqualByX:clickedPoint fromPoint:nextPointToAdd];
                    NSLog(@"%d %d", nextPointToAdd.x, nextPointToAdd.y);
                    if (!nextPointToAdd) {
                        [self removeCurrentChain:nil];
                        NSLog(@"chain is destroyed by clicking first point?");
                        return;
                    }
                }
            } else if (firstPointInChain.y == lastPointInChain.y) {
                int dotsToAddInARow = 0;
                nextPointToAdd = lastPointInChain;
                while (![nextPointToAdd isEqualToPoint:clickedPoint]) {
                    dotsToAddInARow++;
                    nextPointToAdd = [self detectNextPointEqualByY:clickedPoint fromPoint:nextPointToAdd];
                    NSLog(@"%d %d", nextPointToAdd.x, nextPointToAdd.y);
                    if (!nextPointToAdd) {
                        [self removeCurrentChain:nil];
                        NSLog(@"chain is destroyed by clicking first point?");
                        return;
                    }
                }
            } else if (firstPointInChain.x != lastPointInChain.x && firstPointInChain.y && lastPointInChain) {
                [self removeCurrentChain:nil];
                NSLog(@"chain is destroyed by clicking first point?");
                return;
            }
        }
    }
    
    
    
    if ([dotsFromCurrentChain count] != 0) {
        IntegerPoint *lastPointInChain = [dotsFromCurrentChain lastObject];
        IntegerPoint *prelastPointInList = nil;
        if ([dotsFromCurrentChain count] > 1) {
            prelastPointInList = [dotsFromCurrentChain objectAtIndex:[dotsFromCurrentChain count] - 2];
        }
        if ([lastPointInChain isEqualToPoint:clickedPoint]) {
            [self removePoint];
            NSLog(@"removed last point");
            return;
        }
        
        for (int i = 1; i < [dotsFromCurrentChain count]; i++) {
            IntegerPoint *dotFromChain = [dotsFromCurrentChain objectAtIndex:i];
            if ([dotFromChain isEqualToPoint:clickedPoint]) {
                for (int k = [dotsFromCurrentChain count] - 1; k > i; k--) {
                    [self removePoint];
                }
                NSLog(@"removed points till number %d", i);
                return;
            }
        }
        
        IntegerPoint *nextPointToAdd = nil;
        
        // if same x
        if (lastPointInChain.x == clickedPoint.x) {
            int dotsToAddInARow = 0;
            nextPointToAdd = lastPointInChain;
            while (![nextPointToAdd isEqualToPoint:clickedPoint]) {
                dotsToAddInARow++;
                nextPointToAdd = [self detectNextPointEqualByX:clickedPoint fromPoint:nextPointToAdd];
                if (!nextPointToAdd) {
                    NSLog(@"NO WAY");
                    return;
                }
            }
            nextPointToAdd = lastPointInChain;
            
            
//            nextPointToAdd = [self detectNextPointEqualByX:clickedPoint];
            if (!prelastPointInList) {
                for (int i = 0; i < dotsToAddInARow; i++) {
                    nextPointToAdd = [self detectNextPointEqualByX:clickedPoint fromPoint:nextPointToAdd];
                    if (![self addPoint:nextPointToAdd]) {
                        [self actionIsImpossible];
                        return;
                    }
                }
            } else {
                if (lastPointInChain.x == prelastPointInList.x) {
                    if ([clickedPoint makesRayWithPoint1:lastPointInChain andPoint2:prelastPointInList]) {
                        for (int i = 0; i < dotsToAddInARow; i++) {
                            nextPointToAdd = [self detectNextPointEqualByX:clickedPoint fromPoint:nextPointToAdd];
                            if (![self addPoint:nextPointToAdd]) {
                                [self actionIsImpossible];
                                return;
                            }
                        }
                    } else {
//                        [self removePoint];
                    }
                }
                if (lastPointInChain.y == prelastPointInList.y) {
                    for (int i = 0; i < dotsToAddInARow; i++) {
                        nextPointToAdd = [self detectNextPointEqualByX:clickedPoint fromPoint:nextPointToAdd];
                        if (![self addPoint:nextPointToAdd]) {
                            [self actionIsImpossible];
                            return;
                        }
                    }
                }
            }
        }
        
        // if same y
        if (lastPointInChain.y == clickedPoint.y) {
            int dotsToAddInARow = 0;
            nextPointToAdd = lastPointInChain;
            while (![nextPointToAdd isEqualToPoint:clickedPoint]) {
                dotsToAddInARow++;
                nextPointToAdd = [self detectNextPointEqualByY:clickedPoint fromPoint:nextPointToAdd];
                if (!nextPointToAdd) {
                    NSLog(@"NO WAY");
                    return;
                }
            }
            nextPointToAdd = lastPointInChain;
//            nextPointToAdd = [self detectNextPointEqualByY:clickedPoint];
            if (!prelastPointInList) {
                for (int i = 0; i < dotsToAddInARow; i++) {
                    nextPointToAdd = [self detectNextPointEqualByY:clickedPoint fromPoint:nextPointToAdd];
                    if (![self addPoint:nextPointToAdd]) {
                        [self actionIsImpossible];
                        return;
                    }
                }
            } else {
                if (lastPointInChain.y == prelastPointInList.y) {
                    if ([clickedPoint makesRayWithPoint1:lastPointInChain andPoint2:prelastPointInList]) {
                        for (int i = 0; i < dotsToAddInARow; i++) {
                            nextPointToAdd = [self detectNextPointEqualByY:clickedPoint fromPoint:nextPointToAdd];
                            if (![self addPoint:nextPointToAdd]) {
                                [self actionIsImpossible];
                                return;
                            }
                        }
                    } else {
//                        [self removePoint];         //obratit' vnimanie. vozmojni ne slishkom ochevidnie bugi
                    }
                }
                if (lastPointInChain.x == prelastPointInList.x) {
                    for (int i = 0; i < dotsToAddInARow; i++) {
                        nextPointToAdd = [self detectNextPointEqualByY:clickedPoint fromPoint:nextPointToAdd];
                        if (![self addPoint:nextPointToAdd]) {
                            [self actionIsImpossible];
                            return;
                        }
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
        //[buttons[pointToMarkAsUnused.x + pointToMarkAsUnused.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
        [buttons[pointToMarkAsUnused.x + pointToMarkAsUnused.y * FIELD_SIZE] setBackgroundColor:[UIColor lightGrayColor]];
    }
    
    if (prelastPointInChain) {
        if ([allPointsUsedInCurrentChain count] == 1) {
            [buttons[prelastPointInChain.x + prelastPointInChain.y * FIELD_SIZE] setBackgroundColor:[UIColor grayColor]];
        } else {
            [buttons[prelastPointInChain.x + prelastPointInChain.y * FIELD_SIZE] setBackgroundColor:[UIColor greenColor]];
        }
    }
    NSLog(@"dots in chain = %d", [dotsFromCurrentChain count]);
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
            [buttons[pointToBeAdded.x + pointToBeAdded.y * FIELD_SIZE] setBackgroundColor:[UIColor greenColor]];
        }
        
        if ([allPointsUsedInCurrentChain count] == 1) {
            [buttons[nextPoint.x + nextPoint.y * FIELD_SIZE] setBackgroundColor:[UIColor grayColor]];
        } else {
            [buttons[nextPoint.x + nextPoint.y * FIELD_SIZE] setBackgroundColor:[UIColor greenColor]];
        }
        
        
        IntegerPoint *firstPointInChain = [dotsFromCurrentChain firstObject];
        lastPointInChain = [dotsFromCurrentChain lastObject];
        if ([firstPointInChain isEqualToPoint:lastPointInChain] &&
            [dotsFromCurrentChain count] >= 4) {
            [self explodeChain];
        }
        
        return YES;
    }
}

-(IntegerPoint *) detectNextPointEqualByX: (IntegerPoint *) point fromPoint: (IntegerPoint *) point1
{
    IntegerPoint *ip = point;
//    IntegerPoint *lastPointInChain = [dotsFromCurrentChain lastObject];
    IntegerPoint *lastPointInChain = point1;
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
    if (barriersAreActive) {
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
    }
    
    
    return ip;
}

-(IntegerPoint *) detectNextPointEqualByY: (IntegerPoint *) point fromPoint: (IntegerPoint *) point1
{
    IntegerPoint *ip = point;
//    IntegerPoint *lastPointInChain = [dotsFromCurrentChain lastObject];
    IntegerPoint *lastPointInChain = point1;
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
    if (barriersAreActive) {
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
    
    [self detectBonuses];
    
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
      //  [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setBackgroundColor:[UIColor redColor]];
        [buttons[pointToRemove.x + pointToRemove.y * FIELD_SIZE] setBackgroundColor:[UIColor lightGrayColor]];
        
    }
    
    [allPointsUsedInCurrentChain removeAllObjects];
    [dotsFromCurrentChain removeAllObjects];
    
    NSLog(@"total dot count after deleting: %d", [allDots count]);
}

//придумать и написать адекватную формулу для подсчета очков
-(int) calculateScore
{
    int score = 0;
    
    score = round([allPointsUsedInCurrentChain count] * scoreModifier) * (speed + 1) * (difficulty + 1);
    
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
}

-(int) numberOfBarriersForDifficulty:(int) difficulty
{
    if (difficulty > MAXIMUM_DIFFICULTY || difficulty < MINIMUM_DIFFICULTY) {
        [NSException raise:@"difficulty_exception" format:@"invalid difficulty"];
    }
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

-(float) tickDurationForSpeed:(int) speed
{
    if (speed > MAXIMUM_SPEED || speed < MINIMUM_SPEED) {
        [NSException raise:@"speed_exception" format:@"invalid speed"];
    }
    float tickDuration = 0;
    tickDuration = MAXIMUM_TICK_DURATION - (MAXIMUM_TICK_DURATION - MINIMUM_TICK_DURATION) / MAXIMUM_SPEED * speed;
    return tickDuration;
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
//определить бонусы, которые должны быть активированы после взрыва цепи
-(void) detectBonuses
{
    NSMutableArray *detectedBonuses = [NSMutableArray new];
    for (int i = 0; i < [allPointsUsedInCurrentChain count]; i++) {
        IntegerPoint *pointInChain = [allPointsUsedInCurrentChain objectAtIndex:i];
        for (int j = 0; j < [bonuses count]; j++) {
            Bonus *bonus = [bonuses objectAtIndex:j];
            if ([bonus.position isEqualToPoint:pointInChain]) {
                [detectedBonuses addObject:bonus];
                break;
            }
        }
    }
    for (int i = 0; i < [detectedBonuses count]; i++) {
        Bonus *detectedBonus = [detectedBonuses objectAtIndex:i];
        [self removeBonusFromField:detectedBonus activate:YES];
    }
    
}
//возможно, внести в бонус поле время действия и, возможно, время существования
//в методе activateBonus создавать одноразовый таймер, который спустя время действия бонуса запустит метод deactivateBonus
-(void) activateBonus:(Bonus *) bonus
{
    switch (bonus.bonusType) {
        case BonusTypeIgnoreBarriers:
            NSLog(@"activated bonus: IGNORE_BARRIERS");
            if (!barriersAreActive) {
                ignoreBarriersBonusIsActivatedTwice = YES;
            }
            barriersAreActive = NO;
            [self changeBarrierState:NO];
            break;
        case BonusTypeScoreModifier:
            NSLog(@"activated bonus: SCORE_MODIFIER");
            scoreModifier *= SCORE_MODIFIER_BONUS;
            break;
        //case BonusTypeAdditionalPoint:
        case BonusTypeDotLimit:
            NSLog(@"activated bonus: MAXIMUM_DOT_LIMIT");
            if (maximumDotLimit + MAXIMUM_DOT_COUNT_STEP <= MAXIMUM_DOT_COUNT_LIMIT) {
                maximumDotLimit += MAXIMUM_DOT_COUNT_STEP;
            }
            NSLog(@"maximum dot limit now is %d", maximumDotLimit);
            break;
        case BonusTypeLowerSpeed:
            NSLog(@"activated bonus: LOWER_SPEED");
            if (speed > MINIMUM_SPEED) {
                speed--;
                float newTickDuration = [self tickDurationForSpeed:speed];
                [timer1 invalidate];
                timer1 = nil;
                timer1 = [NSTimer scheduledTimerWithTimeInterval:newTickDuration
                                                          target:self
                                                        selector:@selector(onTick:)
                                                        userInfo:nil
                                                         repeats:YES];
            } else {
                [NSException raise:@"speed_exception" format:@"invalid speed"];
            }
            break;
        default: [NSException raise:@"bonus_type_exception" format:@"invalid bonus type"];
            break;
    }
    
    NSString *bonusInfo = [bonus toString];
    [NSTimer scheduledTimerWithTimeInterval:bonus.effectDuration
                                     target:self
                                   selector:@selector(deactivateBonus:)
                                   userInfo:bonusInfo
                                    repeats:NO];
}

-(void) deactivateBonus:(NSTimer *)theTimer
{
    NSString *bonusInfo = (NSString *)[theTimer userInfo];
    Bonus *bonus = [Bonus bonusFromString:bonusInfo];
    switch (bonus.bonusType) {
        case BonusTypeIgnoreBarriers:
            if (!ignoreBarriersBonusIsActivatedTwice) {
                NSLog(@"deactivated bonus: IGNORE_BARRIERS");
                barriersAreActive = YES;
                [self changeBarrierState:YES];
            }
            ignoreBarriersBonusIsActivatedTwice = NO;
            break;
        case BonusTypeScoreModifier:
            NSLog(@"deactivated bonus: SCORE_MODIFIER");
            scoreModifier /= SCORE_MODIFIER_BONUS;
            break;
        //case BonusTypeAdditionalPoint:
        case BonusTypeDotLimit:
            NSLog(@"this bonus will not be deactivated: MAXIMUM_DOT_LIMIT");
            break;
        case BonusTypeLowerSpeed:
            if (speed < MAXIMUM_SPEED) {
                speed++;
                float newTickDuration = [self tickDurationForSpeed:speed];
                if (!isGameOver) {
                    NSLog(@"deactivated bonus: LOWER_SPEED");
                    [timer1 invalidate];
                    timer1 = nil;
                    timer1 = [NSTimer scheduledTimerWithTimeInterval:newTickDuration
                                                              target:self
                                                            selector:@selector(onTick:)
                                                            userInfo:nil
                                                             repeats:YES];
                }
                
            } else {
                [NSException raise:@"speed_exception" format:@"invalid speed"];
            }
            break;
        default: [NSException raise:@"bonus_type_exception" format:@"invalid bonus type"];
            break;
    }
}

//yes = active, no = transparent
-(void) changeBarrierState:(BOOL) active
{
    if (active) {
        for (int i = 0; i < [barrierImages count]; i++) {
            UILabel *image = [barrierImages objectAtIndex:i];
            [image setBackgroundColor:[UIColor blueColor]];
        }
    } else {
        for (int i = 0; i < [barrierImages count]; i++) {
            UILabel *image = [barrierImages objectAtIndex:i];
            [image setBackgroundColor:[UIColor orangeColor]];
        }
    }
}

@end

