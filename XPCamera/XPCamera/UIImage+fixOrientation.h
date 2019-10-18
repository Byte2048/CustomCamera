//
//  UIImage+fixOrientation.h
//  DYCustomTakePhtotoDemo
//
//  Created by  on 16/7/8.
//  Copyright © 2016年 __defaultyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (fixOrientation)

- (UIImage *)fixOrientation;

//旋转图片的方法
- (UIImage *)rotation:(UIImageOrientation)orientation;
@end
