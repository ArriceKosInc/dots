//
//  ViewController.h
//  dots
//
//  Created by Admin on 24.12.14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *scoreLbl;
@property (weak, nonatomic) IBOutlet UIButton *removeAllChainButton;
@property (weak, nonatomic) IBOutlet UIView *gameOverView;
@property (weak, nonatomic) IBOutlet UIView *backgroundGameOverView;
@property (weak, nonatomic) IBOutlet UILabel *gameOverScoreLbl;

- (IBAction)backToMenuButtonTapped:(id)sender;

- (IBAction)retryButtonPressed:(id)sender;

- (IBAction)removeCurrentChain:(id)sender;

- (IntegerPoint *)getRandomPoint;

@end
