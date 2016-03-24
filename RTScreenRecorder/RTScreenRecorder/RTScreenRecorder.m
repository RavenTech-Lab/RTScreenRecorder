//
//  RTScreenRecorder.m
//  RTScreenRecorder
//
//  Created by 叔 陈 on 16/3/23.
//  Copyright © 2016年 RavenTech. All rights reserved.
//

#import "RTScreenRecorder.h"

@interface RTScreenRecorder ()
{
    BOOL recording;
    
    NSData *lastFrameData;
}
@end

@implementation RTScreenRecorder

@synthesize session;
@synthesize input;
@synthesize output;

- (instancetype)initWithCallBack:(void (^)(NSData *imageData))callBack
{
    self = [super init];
    if(self) {
        self.callBack = callBack;
        
        recording = NO;
        
        self.session = [[AVCaptureSession alloc] init];
        self.session.sessionPreset = AVCaptureSessionPresetLow;
        
        self.input = [[AVCaptureScreenInput alloc] initWithDisplayID:CGMainDisplayID()];
        self.input.capturesMouseClicks = YES;
        self.input.minFrameDuration = CMTimeMake(1, 60);
        self.input.scaleFactor = 0.5f;
        self.input.cropRect = [self screenRect];
        
        self.output  = [[AVCaptureVideoDataOutput alloc] init];
        [((AVCaptureVideoDataOutput *)self.output) setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:@(kCVPixelFormatType_32BGRA),kCVPixelBufferPixelFormatTypeKey, nil]];
        dispatch_queue_t queue = dispatch_queue_create("com.sergio.chan", 0);
        [(AVCaptureVideoDataOutput *)self.output setSampleBufferDelegate:self queue:queue];
        //dispatch_release(queue);
        
        [self.session addInput:self.input];
        [self.session addOutput:self.output];
    }
    return self;
}

- (instancetype)initWithFileURL:(NSURL *)fileName
{
    self = [super init];
    if(self) {
        self.file = fileName;
        
        recording = NO;
        
        self.session = [[AVCaptureSession alloc] init];
        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
        
        self.input = [[AVCaptureScreenInput alloc] initWithDisplayID:CGMainDisplayID()];
        self.input.capturesMouseClicks = YES;
        self.input.minFrameDuration = CMTimeMake(1, 60);
        self.input.scaleFactor = 0.5f;
        self.input.cropRect = [self screenRect];
        
        self.output  = [[AVCaptureMovieFileOutput alloc] init];
        
        [self.session addInput:self.input];
        [self.session addOutput:self.output];
    }
    return self;
}

- (BOOL) startRecording
{
    [self.session startRunning];
    if ([self.output isKindOfClass:[AVCaptureMovieFileOutput class]]) {
        // Record to file
        [(AVCaptureMovieFileOutput *)self.output startRecordingToOutputFileURL:self.file recordingDelegate:self];
    }
    recording = YES;
    return YES;
}

- (BOOL) pauseRecording
{
    if ([self.output isKindOfClass:[AVCaptureMovieFileOutput class]]) {
        [(AVCaptureMovieFileOutput *)self.output pauseRecording];
        recording = NO;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) resumeRecording
{
    if ([self.output isKindOfClass:[AVCaptureMovieFileOutput class]]) {
        [(AVCaptureMovieFileOutput *)self.output resumeRecording];
        recording = YES;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) stopRecording
{
    [self.session stopRunning];
    lastFrameData = nil;
    recording = NO;
    return YES;
}

- (BOOL) isRecording
{
    return recording;
}

#pragma mark - Utilities

- (NSRect)screenRect
{
    NSRect screenRect;
    NSScreen *screen = [[NSScreen screens] objectAtIndex: 0];
    screenRect = [screen frame];
    
    return screenRect;
}

#pragma mark AVCaptureFileOutputDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [self imageFromSampleBuffer:sampleBuffer];
}

// Create a CGImageRef from sample buffer data
- (void) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    @try {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        CGContextRelease(newContext);
        
        CGColorSpaceRelease(colorSpace);
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:newImage];
        CGFloat imageCompression = 0.5;
        NSDictionary* jpegOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithDouble:imageCompression], NSImageCompressionFactor,
                                     [NSNumber numberWithBool:NO], NSImageProgressive,
                                     nil];
        NSData* jpegData = [bitmapRep representationUsingType:NSJPEGFileType properties:jpegOptions];
        
        CGImageRelease(newImage);
        
        if (lastFrameData == nil) {
            lastFrameData = jpegData;
        } else {
            if([jpegData isEqualToData:lastFrameData]) {
                NSLog(@"Duplicate frame");
                return;
            } else {
                lastFrameData = jpegData;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.callBack) {
                self.callBack(jpegData);
            }
        });

    }
    @catch (NSException *exception) {
        NSLog(@"Error at %@",exception.debugDescription);
    }
    @finally {
        return;
    }
}

#pragma mark AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections error:(NSError *)error {
}

@end
