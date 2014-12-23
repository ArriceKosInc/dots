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


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableArray *buttons = [NSMutableArray new];
    int cellWidth = [[UIScreen mainScreen] bounds].size.height / 13;
    NSLog(@"%d", cellWidth);
    CGPoint buttonStartPoint = CGPointMake([[UIScreen mainScreen] bounds].size.width * 2 / 17,
                                            [[UIScreen mainScreen] bounds].size.height * 1 / 13);
    for (int i = 0; i < FIELD_SIZE*FIELD_SIZE; i++) {
        buttons[i] = [[UIButton alloc] initWithFrame:CGRectMake(buttonStartPoint.x + i % FIELD_SIZE * cellWidth,
                                                                buttonStartPoint.y + i / FIELD_SIZE * cellWidth,
                                                                cellWidth, cellWidth)];
        //[buttons[i] setType:UIButtonTypeCustom];
        [buttons[i] setTitle:[NSString stringWithFormat:@"%d", i]];
        [buttons[i] setBackgroundColor:[UIColor redColor]];
        [self.view addSubview:buttons[i]];
    }
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
