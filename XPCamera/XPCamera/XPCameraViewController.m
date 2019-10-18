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
@interface XPCameraViewController ()<AVCapturePhotoCaptureDelegate>
@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureDeviceInput *input;
@property (nonatomic,strong) AVCapturePhotoOutput *output;
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;// 预览

@property (nonatomic,strong) UIButton *takePhotoBtn;// 拍照
@property (nonatomic,strong) UIView *focalView;//对焦

@property (nonatomic,strong) UIButton *focalLengthBtn;//焦距
@end

@implementation XPCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setSession];
    [self setCameraLayer];
    [self setUI];
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
    
    // 获取摄像头device
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 获取麦克风 device
//    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    self.output = [[AVCapturePhotoOutput alloc] init];
    
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    }
}

- (void)setCameraLayer{
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setFrame:self.view.bounds];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:self.previewLayer];
}

- (void)setUI{
    self.takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.takePhotoBtn.frame = CGRectMake(kWidth/2-24, kHeight-100, 48, 48);
    [self.takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"takePhoto"] forState:UIControlStateNormal];
    [self.takePhotoBtn addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.takePhotoBtn];
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(50, kHeight-100, 48, 48);
    [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [back setBackgroundImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [self.view addSubview:back];
    
}

- (void)takePhoto:(UIButton *)sender{
//    AVCaptureConnection *connect = [self.output connectionWithMediaType:AVMediaTypeVideo];
    AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeJPEG}];
    if (!setting) {
        NSLog(@"拍照失败");
        return ;
    }
    [self.output capturePhotoWithSettings:setting delegate:self];
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
                NSLog(@"获取图片成功 --- %@",image);
                [self showCaptureImage:image];
            }
        }
    }
}

- (void)showCaptureImage:(UIImage *)image{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    imageView.image = image;
    [self.view addSubview:imageView];
    
}

- (void)back{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//隐藏状态栏
-(BOOL)prefersStatusBarHidden {
    return YES;
}
@end
