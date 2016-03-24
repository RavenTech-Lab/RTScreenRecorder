//
//  RTScreenRecorder.h
//  RTScreenRecorder
//
//  Created by 叔 陈 on 16/3/23.
//  Copyright © 2016年 RavenTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface RTScreenRecorder : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate>

@property (retain) AVCaptureSession* session;
@property (retain) AVCaptureScreenInput* input;
@property (retain) AVCaptureOutput* output;

@property NSURL* file;

@property (copy) void (^callBack)(NSData *imageData);

/**
 *  Initialize recorder with a callback which included image for every frame
 *
 *  @param callBack call back block that you can custom
 *
 *  @return Instance of RTScreenRecorder
 */
- (instancetype)initWithCallBack:(void (^)(NSData *imageData))callBack;

/**
 *  Initialize recorder with a file URL that will be the destination file of the video
 *
 *  @param fileName Exact file path
 *
 *  @return Instance of RTScreenRecorder
 */
- (instancetype)initWithFileURL:(NSURL *)fileName;

/**
 *  Method you should call to start recording
 *
 *  @return Bool value indicates the status of start operation
 */
- (BOOL) startRecording;

/**
 *  If you are using Capturing-To-File mode, you can pause recording and resume it. Otherwise you will receive NO from calling this method
 *
 *  @return Bool value indicates the status of pause operation
 */
- (BOOL) pauseRecording;
- (BOOL) resumeRecording;

/**
 *  Method you should call to stop recording
 *
 *  @return Bool value indicates the status of stop operation
 */
- (BOOL) stopRecording;

/**
 *  Status of recording
 *
 *  @return Bool value indicates the status of the recorder
 */
- (BOOL) isRecording;

@end
