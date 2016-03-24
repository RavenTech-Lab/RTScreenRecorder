//
//  ViewController.m
//  RTScreenRecorder
//
//  Created by 叔 陈 on 16/3/23.
//  Copyright © 2016年 RavenTech. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.recorder = [[RTScreenRecorder alloc] initWithCallBack:^(NSData *imageData) {
        NSLog(@"image data size:%ld bytes",imageData.length);
        self.imageView.image = [[NSImage alloc] initWithData:imageData];
    }];
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)RecordButtonPressed:(id)sender {
    if([self.recorder isRecording]) {
        [self.recorder stopRecording];
    } else {
        [self.recorder startRecording];
    }
}

@end
