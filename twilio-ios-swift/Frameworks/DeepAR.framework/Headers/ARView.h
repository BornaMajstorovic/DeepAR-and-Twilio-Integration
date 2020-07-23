//
//  ARView.h
//
//  Copyright © 2017 DeepAR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef struct {
    BOOL detected;
    float translation[3];
    float rotation[3];
    float poseMatrix[16];
    float landmarks[68*3];
    float landmarks2d[68*3];
    float faceRect[4];
    float emotions[5]; // 0=neutral, 1=happiness, 2=surprise, 3=sadness, 4=anger
    float actionUnits[63];
    int numberOfActionUnits;
} FaceData;

typedef struct {
    FaceData faceData[4];
} MultiFaceData;

typedef struct {
    float x;
    float y;
    float z;
    float w;
} Vector4;

typedef struct {
    float x;
    float y;
    float z;
} Vector3;


@protocol ARViewDelegate <NSObject>

// Called when the video recording is started.
- (void)didStartVideoRecording;

// Called when the video recording is finished and video file is saved.
- (void)didFinishVideoRecording:(NSString*)videoFilePath;

// Called if there is error encountered while recording video
- (void)recordingFailedWithError:(NSError*)error;

// Called when screenshot is taken
- (void)didTakeScreenshot:(UIImage*)screenshot;

// Called when the engine initialization is complete. Do not call ARView methods before initialization.
- (void)didInitialize;

// Called when the face appears or disappears.
- (void)faceVisiblityDidChange:(BOOL)faceVisible;

@optional

// Called when the new frame is available
- (void)frameAvailable:(CMSampleBufferRef)sampleBuffer;

- (void)faceTracked:(MultiFaceData)faceData;

- (void)numberOfFacesVisibleChanged:(NSInteger)facesVisible;

- (void)didFinishShutdown;

- (void)imageVisibilityChanged:(NSString*)gameObjectName imageVisible:(BOOL)imageVisible;

- (void)didSwitchEffect:(NSString*)slot;

- (void)animationTransitionedToState:(NSString*)state;

@end

@interface ARView : UIView

@property (nonatomic, weak) id<ARViewDelegate> delegate;

@property (nonatomic, readonly) BOOL initialized;
@property (nonatomic, readonly) BOOL faceVisible;
@property (nonatomic, readonly) CGSize renderingResolution;

@property (nonatomic, strong) NSDictionary* audioCompressionSettings;

// You can get your license key on https://developer.deepar.ai
- (void)setLicenseKey:(NSString*)key;

// Starts the engine initialization.
- (void)initialize;

// Resumes the rendering
- (void)resume;

// Pauses the rendering.
- (void)pause;

// Load and switch to effect.
// slot - this parameter is used to specify a "namespace" for effect. No two effects can be in
// one slot, so if we load new effect into already occupied slot, the old effect will be
// removed.
// path - The absolute path to the effect file.
- (void)switchEffectWithSlot:(NSString*)slot path:(NSString*)path;

// Switch effect for the face. Allowed values for face parameters are 0,1,2,3.
// This will only work if the DeepAR SDK build has multi face tracking enabled
- (void)switchEffectWithSlot:(NSString*)slot path:(NSString*)path face:(uint32_t)face;
- (void)switchEffectWithSlot:(NSString*)slot path:(NSString*)path face:(uint32_t)face targetGameObject:(NSString*)targetGameObject;

// Captures the screen. Delegate method didTakeScreenshot will be called when capture is finished.
- (void)takeScreenshot;

//Video recording helper functions
- (int)getMinSupportedHeight;
- (int)getMaxSupportedHeight;
- (int)getMinSupportedWidth;
- (int)getMaxSupportedWidth;

// Starts video recording of ARView in outputWidth x outputHeight resoulution
// CGRect subframe defines the area of ARView we want to record in normalized coordinates (from 0.0 to 1.0)
// Video compression properties is a NSDictionary used as value for key AVVideoCompressionPropertiesKey
// Audio recording can be disabled/enabled using the recordAudio parameter
- (void)startVideoRecordingWithOutputWidth:(int)outputWidth outputHeight:(int)outputHeight;
- (void)startVideoRecordingWithOutputWidth:(int)outputWidth outputHeight:(int)outputHeight subframe:(CGRect)subframe;
- (void)startVideoRecordingWithOutputWidth:(int)outputWidth outputHeight:(int)outputHeight subframe:(CGRect)subframe videoCompressionProperties:(NSDictionary*)videoCompressionProperties;
- (void)startVideoRecordingWithOutputWidth:(int)outputWidth outputHeight:(int)outputHeight subframe:(CGRect)subframe videoCompressionProperties:(NSDictionary*)videoCompressionProperties recordAudio:(BOOL)recordAudio;

// Finishes the video recording. Delegate method didFinishVideoRecording will be called when the recording is done.
- (void)finishVideoRecording;

// Set she audio processing (pitch change) for video recording enabled.
- (void)enableAudioProcessing:(BOOL)enabled;

// Sets the pitch change amount. Negative values will make the recorded audio lower in pitch and positive values will make it higher in pitch.
- (void)setAudioProcessingSemitone:(float)sts;

// Shutdowns the engine
- (void)shutdown;

- (void)moveSlotToFace:(NSString*)slot face:(uint32_t)face;

// Starts streaming the subframes to delegate method frameAvailable.
- (void)startFrameOutputWithOutputWidth:(int)outputWidth outputHeight:(int)outputHeight subframe:(CGRect)subframe;

// Stops streaming
- (void)stopFrameOutput;

// Passes the camera frame into the engine. This should only be called after initializeWithCustomCameraUsingPreset.
- (void)enqueueCameraFrame:(CMSampleBufferRef)sampleBuffer mirror:(BOOL)mirror;

// Passes the audo sample into the engine. This is used for the video/audio recording and only if initialized with initializeWithCustomCameraUsingPreset.
- (void)enqueueAudioSample:(CMSampleBufferRef)sampleBuffer;

- (void)pauseVideoRecording;
- (void)resumeVideoRecording;

// Should be called when the interface starts to change the orientation (e.g. in viewWillTransitionToSize). This will turn off the camera.
- (void)changeOrientationStart;

// Should be called when the interface orientation change is finished. orientation parameter is the new interface orientation.
- (void)changeOrientation:(UIInterfaceOrientation)orientation;

// Change a float parameter on a GameObject, the parameter variable contains parameter name, eg. blendshape name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter floatValue:(float)value;
// Change a vector4 parameter on a GameObject, the parameter variable contains parameter name, eg. uniform name 
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter vectorValue:(Vector4)value;
// Change a vector3 parameter on a GameObject, the parameter variable contains parameter name, eg. transform name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter vector3Value:(Vector3)value;
// Change a bool parameter on a GameObject, the parameter variable contains parameter name, eg. uniform name 
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter boolValue:(bool)value;
// Change an image parameter on a GameObject, the parameter variable contains parameter name, eg. uniform name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter image:(UIImage*)image;

// Fire trigger for all animation controllers
- (void)fireTrigger:(NSString*)trigger;

// Change face detection sensitivity
- (void)setFaceDetectionSensitivity:(int)sensitivity;

// Display debuging stats on screen
- (void)showStats:(bool)enabled;

// Sets the internal SDK parameter
- (void)setParameterWithKey:(NSString*)key value:(NSString*)value;
@end
