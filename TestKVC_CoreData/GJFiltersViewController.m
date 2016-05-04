//
//  GJFiltersViewController.m
//  TestKVC_CoreData
//
//  Created by 66 on 16/5/3.
//  Copyright © 2016年 genglei. All rights reserved.
// 发动机号 153540363 车架号 LSGGA53E7GH079392

#import <Masonry.h>
#import <CoreImage/CoreImage.h>
#import <GPUImage/GPUImage.h>

#import "GJFiltersViewController.h"

@interface GJFiltersViewController ()

@property (nonatomic, strong) UIImageView *filterImage;

@property (nonatomic, strong) UIImageView *GPUinage;

@property (nonatomic, strong) UIImageView *shaderImage;

@end

@implementation GJFiltersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Filters";

    
    [self.view addSubview:self.filterImage];
    [self.view addSubview:self.GPUinage];
    [self.view addSubview:self.shaderImage];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filterFromGPUImage:[UIImage imageNamed:@"girl"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.GPUinage.image = image;
        });
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self filterFromGPUImageShader:[UIImage imageNamed:@"girl"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.shaderImage.image = image;
        });
    });
    
}

- (void)viewWillLayoutSubviews {
    [self.filterImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.centerY.equalTo(self.view.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(110, 110));
    }];
    
    [self.GPUinage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view).with.offset(100);
        make.size.mas_equalTo(CGSizeMake(110, 110));
    }];
    
    [self.shaderImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view).with.offset(-100);
        make.size.mas_equalTo(CGSizeMake(110, 110));
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Method

- (UIImage *)filterFromCoreImage:(UIImage *)image {
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *originImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:originImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:1] forKey:kCIInputRadiusKey];
    CIImage *outPutImage = filter.outputImage;
    CGImageRef cgImage = [context createCGImage:outPutImage fromRect:[outPutImage extent]];
    UIImage *resultImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return resultImage;
}

- (UIImage *)filterFromGPUImage:(UIImage *)image {
    
    UIImage *resultImage = nil;
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc]initWithImage:image];
    GPUImageFilterGroup *groupFilter = [[GPUImageFilterGroup alloc]init];
    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc]init];
    GPUImageHighlightShadowFilter *overlayBlendFilter = [[GPUImageHighlightShadowFilter alloc]init];
    overlayBlendFilter.shadows = 0.5;
    overlayBlendFilter.highlights = 0.5;
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc]init];
    GPUImageSaturationFilter *saturationFilter = [[GPUImageSaturationFilter alloc]init];
    saturationFilter.saturation =  - 0.04f;
    GPUImageHueFilter *hueFilter = [[GPUImageHueFilter alloc]init];
    hueFilter.hue = 1.0f;
    GPUImageFilter *filter = [[GPUImageFilter alloc]initWithFragmentShaderFromFile:@"Shader1"];
    
    [groupFilter addTarget:brightnessFilter];
    [groupFilter addTarget:overlayBlendFilter];
    [groupFilter addTarget:contrastFilter];
    [groupFilter addTarget:saturationFilter];
    [groupFilter addTarget:hueFilter];
    [groupFilter addTarget:filter];
    
    [brightnessFilter addTarget:overlayBlendFilter];
    [overlayBlendFilter addTarget:contrastFilter];
    [contrastFilter addTarget:saturationFilter];
    [saturationFilter addTarget:hueFilter];
    [hueFilter addTarget:filter];

    
    [(GPUImageFilterGroup *) groupFilter setInitialFilters:[NSArray arrayWithObject:brightnessFilter]];
    [(GPUImageFilterGroup *) groupFilter setTerminalFilter:filter];

    [stillImageSource addTarget:groupFilter];
    [stillImageSource processImage];
    [groupFilter useNextFrameForImageCapture];
    
    resultImage = [groupFilter imageFromCurrentFramebuffer];
    return resultImage;
}

- (UIImage *)filterFromGPUImageShader:(UIImage *)image {
    
        //    NSString *vertexStringPath = [[NSBundle mainBundle]pathForResource:@"shader" ofType:@"vsh"];
    NSString *fragmentStringPath = [[NSBundle mainBundle]pathForResource:@"GPUImageCustomFilter" ofType:@"fsh"];
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragmentStringPath encoding:NSUTF8StringEncoding error:nil];
    
    UIImage *reslutImage = nil;
    GPUImagePicture *imageSource = [[GPUImagePicture alloc]initWithImage:image];
    GPUImageFilter *filter = [[GPUImageFilter alloc]initWithFragmentShaderFromString:fragmentShaderString];

//    GPUImageFilter *filter = [[GPUImageFilter alloc]initWithVertexShaderFromString:nil fragmentShaderFromString:fragmentStringPath];
    [imageSource addTarget:filter];
    [imageSource processImage];
    [filter useNextFrameForImageCapture];
    reslutImage = [filter imageFromCurrentFramebuffer];
    return reslutImage;;
}

#pragma mark - Setter Getter 

- (UIImageView *)filterImage {
    if (_filterImage == nil) {
        _filterImage = [UIImageView new];
        _filterImage.image = [UIImage imageNamed:@"girl"];
    }
    return _filterImage;
}

- (UIImageView *)GPUinage {
    if (_GPUinage == nil) {
        _GPUinage = [UIImageView new];
    }
    return _GPUinage;
}

- (UIImageView *)shaderImage {
    if (_shaderImage == nil) {
        _shaderImage = [UIImageView new];
    }
    return _shaderImage;
}

@end
