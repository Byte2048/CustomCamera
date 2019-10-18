//
//  ViewController.m
//  XPCamera
//
//  Created by spc on 2019/10/18.
//  Copyright © 2019 spc. All rights reserved.
//

#import "ViewController.h"
#import "XPCameraViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)takePhoto:(UIButton *)sender {
    [self presentViewController:[XPCameraViewController new] animated:YES completion:nil];  
}

@end
