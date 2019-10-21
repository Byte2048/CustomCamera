//
//  XPCameraViewController.m
//  XPCamera
//
//  Created by spc on 2019/10/18.
//  Copyright © 2019 spc. All rights reserved.
//

#import "XPCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+fixOrientation.h"

#define kWidth ([UIScreen mainScreen].bounds.size.width)
#define kHeight ([UIScreen mainScreen].bounds.size.height)

static float kCameraScale=1.0;

API_AVAILABLE(ios(10.0))
@interface XPCameraViewController ()<AVCapturePhotoCaptureDelegate>
@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureDeviceInput *input;
@property (nonatomic,strong) AVCapturePhotoOutput *output11;// iOS 11以上
@property (nonatomic,strong) AVCaptureStillImageOutput *output4_10;// iOS 4~10
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;// 预览

@property (nonatomic,strong) UIView *focalView;// 对焦
@end



@implementation XPCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setSession];
    [self setCameraLayer];
    [self setUI];
    
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.session stopRunning];
}

#pragma mark - 初始化session
- (void)setSession{
    self.session = [[AVCaptureSession alloc] init];
    
    
    // 可以设置setting为全局变量
    //    if (@available(iOS 10.0, *)) {
    //        NSDictionary *settingDic = @{AVVideoCodecKey:AVVideoCodecJPEG};
    //        AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettingsWithFormat:settingDic];
    //        [self.output11 setPhotoSettingsForSceneMonitoring:setting];
    //    } else {
    //
    //    }
    
    
    // 获取摄像头device
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 获取麦克风 device
    //    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    
    
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if (@available(iOS 11.0,*)) {
        self.output11 = [[AVCapturePhotoOutput alloc] init];
        if ([self.session canAddOutput:self.output11]) {
            [self.session addOutput:self.output11];
        }
    }else{
        self.output4_10 = [[AVCaptureStillImageOutput alloc] init];
        self.output4_10.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
        if ([self.session canAddOutput:self.output4_10]) {
            [self.session addOutput:self.output4_10];
        }
    }
}

- (void)setCameraLayer{
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setFrame:self.view.bounds];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:self.previewLayer];
}

- (void)setUI{
    UIButton *takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    takePhotoBtn.frame = CGRectMake(kWidth/2-24, kHeight-100, 48, 48);
    [takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"takePhoto"] forState:UIControlStateNormal];
    [takePhotoBtn addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takePhotoBtn];
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(50, 20, 48, 48);
    [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [back setTitle:@"返回" forState:UIControlStateNormal];
    [back setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:back];
    
    UIButton *flash = [UIButton buttonWithType:UIButtonTypeCustom];
    flash.frame = CGRectMake(kWidth - 100 - 20, 20, 100, 20);
    [flash setTitle:@"闪光灯-关" forState:UIControlStateNormal];
    [flash setTitle:@"闪光灯-开" forState:UIControlStateSelected];
    [flash setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [flash addTarget:self action:@selector(flashClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flash];
    
    UIButton *cut = [UIButton buttonWithType:UIButtonTypeCustom];
    cut.frame = CGRectMake(kWidth - 100 - 20, 120, 100, 20);
    [cut setTitle:@"后置" forState:UIControlStateNormal];
    [cut setTitle:@"前置" forState:UIControlStateSelected];
    [cut setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cut addTarget:self action:@selector(cutClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cut];
    
    UIButton *focalLengthBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    focalLengthBtn.frame = CGRectMake(kWidth - 100 - 20, 220, 100, 20);
    [focalLengthBtn setTitle:@"焦距1倍" forState:UIControlStateNormal];
    [focalLengthBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [focalLengthBtn addTarget:self action:@selector(focalClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:focalLengthBtn];
}

#pragma mark - 调整焦距
- (void)focalClick:(UIButton *)sender{
    kCameraScale += 1;
    if (kCameraScale > 4) {
        kCameraScale = 1;
    }
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.2];
    [sender setTitle:[NSString stringWithFormat:@"焦距%d倍",(int)kCameraScale] forState:UIControlStateNormal];
    
    AVCaptureConnection *connect;
    if (@available(iOS 11.0,*)) {
        connect = [self.output11 connectionWithMediaType:AVMediaTypeVideo];
    }else{
        connect = [self.output4_10 connectionWithMediaType:AVMediaTypeVideo];
    }
    
    connect.videoScaleAndCropFactor=kCameraScale;
    [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(kCameraScale, kCameraScale)];
    [CATransaction commit];
}

#pragma mark - 点击屏幕时
- (void)tapScreen:(UITapGestureRecognizer*)gesture{
    if (self.focalView.hidden == NO) {
        return;
    }
    CGPoint point = [gesture locationInView:gesture.view];
    [self focusAtPoint:point];
}

- (void)focusAtPoint:(CGPoint)point{
    CGSize size = self.view.bounds.size;
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1-point.x/size.width );
    
    
    // 判断设备是否支持对焦
    if ([self.input.device isFocusPointOfInterestSupported] && [self.input.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        NSError *error;
        if ([self.input.device lockForConfiguration:&error]) {

            // 白平衡
            if ([self.input.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [self.input.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }
            
            // 焦距模式调整
            if ([self.input.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [self.input.device setFocusMode:AVCaptureFocusModeAutoFocus];
                [self.input.device setFocusPointOfInterest:focusPoint];
            }
            
            // 曝光量调节
            if([self.input.device isExposurePointOfInterestSupported] && [self.input.device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [self.input.device setExposurePointOfInterest:focusPoint];
                [self.input.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            [self.input.device unlockForConfiguration];
        }
    }
    
    [self setFocusCursorWithPoint:point];
}

#pragma mark - 聚焦框动画
- (void)setFocusCursorWithPoint:(CGPoint)point{
    // 下面是手触碰屏幕后对焦的效果
    self.focalView.center = point;
    self.focalView.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.focalView.transform = CGAffineTransformMakeScale(1.25, 1.25);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            self.focalView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.focalView.hidden = YES;
        }];
    }];
}

#pragma mark - 手电筒
- (void)flashClick:(UIButton *)sender{
    sender.selected = !sender.selected;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch] && [device hasFlash]) {
        [device lockForConfiguration:nil];
        // 手电筒开关--其实就是相机的闪光灯
        if (sender.selected) {
            [device setTorchMode:AVCaptureTorchModeOn];
        }else{
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

#pragma mark - 切换前置和后置摄像头
- (void)cutClick:(UIButton *)sender{
    sender.selected = !sender.selected;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (sender.selected) {
        // 切换前置
        for (AVCaptureDevice *device in devices) {
            if (device.position == AVCaptureDevicePositionFront) {
                [self cameraWithDevice:device];
                break;
            }
        }
    }else{
        // 切换后置
        for (AVCaptureDevice *device in devices) {
            if (device.position == AVCaptureDevicePositionBack) {
                [self cameraWithDevice:device];
                break;
            }
        }
    }
}

- (void)cameraWithDevice:(AVCaptureDevice *)device{
    [self.session beginConfiguration];
    [self.session removeInput:self.input];
    self.input = nil;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    [self.session commitConfiguration];
}

- (void)takePhoto:(UIButton *)sender{
    // 需要权限 “Privacy - Camera Usage Description”
    if (@available(iOS 11.0,*)) {
        AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeJPEG}];
        if (!setting) {
            NSLog(@"拍照失败");
            return ;
        }
        // 获取当前屏幕输出 ，实现代理
        [self.output11 capturePhotoWithSettings:setting delegate:self];
    }else{
        AVCaptureConnection *connect = [self.output4_10 connectionWithMediaType:AVMediaTypeVideo];
        if (!connect) {
            NSLog(@"拍照失败");
            return ;
        }
        [self.output4_10 captureStillImageAsynchronouslyFromConnection:connect completionHandler:^(CMSampleBufferRef _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
            if (imageDataSampleBuffer == NULL) {
                return ;
            }
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            NSLog(@"获取图片成功4~10 --- %@",image);
            [self showCaptureImage:image];
        }];
        
    }
}

#pragma mark - 拍摄静态照片
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error{
    if (error) {
        NSLog(@"拍摄照片异常---%@",error);
    }else{
        if (photo) {
            if (@available(iOS 11.0,*)) {
                CGImageRef cgImage = [photo CGImageRepresentation];
                UIImage * image = [UIImage imageWithCGImage:cgImage];
                image = [image rotation:UIImageOrientationRight];
                NSLog(@"获取图片成功11111 --- %@",image);
                [self showCaptureImage:image];
            }
        }
    }
}

- (void)showCaptureImage:(UIImage *)image{
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    imageView.image = image;
    imageView.userInteractionEnabled = YES;
    [self.view addSubview:imageView];
    
    UIButton *reset = [UIButton buttonWithType:UIButtonTypeCustom];
    reset.frame = CGRectMake(50, kHeight-100, 50, 30);
    [reset setTitle:@"重拍" forState:UIControlStateNormal];
    [reset setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [reset addTarget:self action:@selector(resetClick:) forControlEvents:UIControlEventTouchUpInside];
    [imageView addSubview:reset];
    
    UIButton *save = [UIButton buttonWithType:UIButtonTypeCustom];
    save.frame = CGRectMake(kWidth - 50 - 30 , kHeight-100, 50, 30);
    [save setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [save setTitle:@"保存" forState:UIControlStateNormal];
    [save addTarget:self action:@selector(saveClick:) forControlEvents:UIControlEventTouchUpInside];
    [imageView addSubview:save];
}

#pragma mark - 重新拍照
- (void)resetClick:(UIButton *)sender{
    [sender.superview removeFromSuperview];
}

#pragma mark - 保存照片
- (void)saveClick:(UIButton *)sender{
    UIImageView *imv = (UIImageView *)sender.superview;
    // 需要权限 “Privacy - Photo Library Additions Usage Description”
    UIImageWriteToSavedPhotosAlbum(imv.image, nil, nil, nil);
    [imv removeFromSuperview];
}

- (void)back{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//隐藏状态栏
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIView *)focalView{
    if (!_focalView) {
        _focalView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        _focalView.layer.borderWidth = 1.0f;
        _focalView.layer.borderColor = [UIColor redColor].CGColor;
        _focalView.hidden = YES;
        [self.view addSubview:_focalView];
    }
    return _focalView;
}
@end
