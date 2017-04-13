//
//  NixViewController.m
//  PhotoCaptionInputView
//
//  Created by James Kong on 04/12/2017.
//  Copyright (c) 2017 James Kong. All rights reserved.
//

#import "NixViewController.h"
#import "PhotoCaptionInputViewController.h"
@interface NixViewController ()

@end

@implementation NixViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    [self presentViewController:vc animated:NO completion:^{
//        
//    }];
	// Do any additional setup after loading the view, typically from a nib.
}

-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    PhotoCaptionInputViewController *vc = [[PhotoCaptionInputViewController alloc] init];
    [self presentViewController:vc animated:NO completion:^{
        
    }];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
