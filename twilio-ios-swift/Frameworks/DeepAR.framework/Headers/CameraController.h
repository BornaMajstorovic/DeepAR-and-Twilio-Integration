//  CameraController.h
//
//  Copyright © 2020 DeepAR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ARView.h"

@interface CameraController : NSObject

@property (nonatomic, weak) ARView* arview;

@property (nonatomic, assign) AVCaptureDevicePosition position;
@property (nonatomic, strong) AVCaptureSessionPreset preset;
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;

- (instancetype)init;

- (void)checkCameraPermission;
- (void)checkMicrophonePermission;

- (void)startCamera;
- (void)stopCamera;

- (void)startAudio;
- (void)stopAudio;

@end
