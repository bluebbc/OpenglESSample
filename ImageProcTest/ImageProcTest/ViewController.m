//
//  ViewController.m
//  ImageProcTest
//
//  Created by maozheng on 2018/9/3.
//  Copyright © 2018年 maozheng. All rights reserved.
//

#import "ViewController.h"
//#import <SureVideoProcessCore/VideoProcessCoreWrapper.h>
//#import <SureVideoProcessCore/ParametersKeyWrapper.h>
//#import <SureVideoProcessCore/ActionTypeWrapper.h>
#import "OpenGLView.h"
#import "DotOpenGLView.h"
#import "TwoOpenGLView.h"
#import "CircleOpenGLView.h"
#import "MaskOpenGLView.h"
#import "SobelOpenGLView.h"

#define CAPTURE_FRAMES_PER_SECOND       20

@interface ViewController ()
{
    SobelOpenGLView *fGLView;
//    SureVideoProcessCore *processCore;
    AVCaptureSession *captureSession;
    AVCaptureConnection* _videoConnection;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    captureSession = [[AVCaptureSession alloc] init];
//    processCore = [[SureVideoProcessCore alloc] init];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onStart:(id)sender {
//    NSDictionary *dictionary1 = @{
//                                  @(START_TIME): @(0),
//                                  @(END_TIME): @(100),
//                                  @(MIRROR_TYPE): @(0),
//                                  };
//
//    NSDictionary *dictionary2 = @{
//                                  @(START_TIME): @(0),
//                                  @(END_TIME): @(100),
//                                  @(DARK_CORNER_START_RANGE): @(0.5),
//                                  @(DARK_CORNER_END_RANGE): @(0.5),
//                                  };
//    [processCore addAction2:MIRROR parameters:dictionary1];

    [self setupVideoCaprure];
    fGLView = [[SobelOpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:fGLView];
    [self.view sendSubviewToBack:fGLView];
    [captureSession commitConfiguration];
    [captureSession startRunning];
}

- (void) setupVideoCaprure
{
    NSError *deviceError;
    
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    
    // make output device
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* val = [NSNumber
                     numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings =
    [NSDictionary dictionaryWithObject:val forKey:key];
    
    NSError *error;
    [cameraDevice lockForConfiguration:&error];
    if (error == nil) {
        
        NSLog(@"cameraDevice.activeFormat.videoSupportedFrameRateRanges IS %@",[cameraDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0]);
        
        if (cameraDevice.activeFormat.videoSupportedFrameRateRanges){
            
            [cameraDevice setActiveVideoMinFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
            [cameraDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
        }
    }else{
        // handle error2
    }
    [cameraDevice unlockForConfiguration];
    
    // Start the session running to start the flow of data
    outputDevice.videoSettings = videoSettings;
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    // initialize capture session
    if ([captureSession canAddInput:inputDevice]) {
        [captureSession addInput:inputDevice];
    }
    if ([captureSession canAddOutput:outputDevice]) {
        [captureSession addOutput:outputDevice];
    }
    
    // begin configuration for the AVCaptureSession
    [captureSession beginConfiguration];
    
    // picture resolution
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset640x480]];
    
    _videoConnection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
    
    //Set landscape (if required)
    if ([_videoConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;        //<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [_videoConnection setVideoOrientation:orientation];
    }
}

-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection

{
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    double dPTS = (double)(pts.value) / pts.timescale;
    
    if (connection == _videoConnection) {
        CVPixelBufferRef videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//        CVPixelBufferRef outbuffer;
//        [processCore processRGBA:videoPixelBuffer output:&outbuffer width:640 height:480 time:0];
        [fGLView render:videoPixelBuffer];
        NSLog(@"video:%f",dPTS);
        
    } else {
        NSLog(@"audio:%f",dPTS);
    }
}


@end
