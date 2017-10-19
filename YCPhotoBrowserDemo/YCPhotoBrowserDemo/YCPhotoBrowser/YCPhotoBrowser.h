//
//  YCPhotoBrowser.h
//  PhotoBrowser
//
//  Created by YuChengGuo on 14-10-1.
//  Copyright (c) 2014年 YuChengGuo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

//照片停止滚动的通知
#define kPhotoDidScroll @"PhotoDidScroll"

@interface YCPhotoBrowser : UIViewController
@property (nonatomic, strong) UICollectionView *imageCollectionView; //图片滚动视图
@property (nonatomic, strong) UILabel *pagesLabel;                   //页数标签
@property (nonatomic, strong) NSMutableArray *thumbnailsRectArr;     //全部缩略图片视图在屏幕下的位置和大小
@property (nonatomic, assign) UIInterfaceOrientation orientation;    //记录设备方向

@property (nonatomic, strong) NSArray *imagesURLArr;  //全部高清图片地址(必须设置)
@property (nonatomic, strong) NSArray *thumbnailsArr; //全部缩略图片视图(可以不设置)
@property (nonatomic) NSInteger currentImageIndex;    //点击的第几张图(必须设置)(从0开始)

//弹出图片浏览器
- (void)showPhotoBrowser;

//关闭图片浏览器
- (void)closePhotoBrowser;

@end
