//
//  ViewController.m
//  WhatsNew
//
//  Created by Artem Meleshko on 4/14/15.
//  Copyright (c) 2015 LeshkoApps. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.tag = 16;
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    b.showsTouchWhenHighlighted = YES;
    [b setTitle:@"Push Me and Restart App" forState:UIControlStateNormal];
    [b addTarget:self action:@selector(clearAll:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [[self.view viewWithTag:16] setFrame:self.view.bounds];
}

- (void)clearAll:(id)sender{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"kLSAppUpdateManagerLastStartedAppVersion"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"kLSAppUpdateManagerLastUserPromt"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"kLSAppUpdateManagerLastVersionInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    exit(0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
