//
//  ViewController.m
//  YCPhotoBrowserDemo
//
//  Created by 别逗我 on 2017/10/19.
//  Copyright © 2017年 YuChengGuo. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
#import "YCPhotoBrowser.h"

@interface ViewController ()

@end

@implementation ViewController
{
    NSMutableArray *_urlArr;
    NSMutableArray *_imageViewArr;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _urlArr = [NSMutableArray array];
    _imageViewArr = [NSMutableArray array];
    
    [_urlArr addObject:@"http://dev-cdd.xiaoxi6.com/uploads/videos/video_150595926018015.jpg"];
    [_urlArr addObject:@"http://dev-cdd.xiaoxi6.com/uploads/videos/video_150633225271796.png"];
    [_urlArr addObject:@"http://dev-cdd.xiaoxi6.com/uploads/videos/video_150615279148029.png"];
    [_urlArr addObject:@"http://dev-cdd.xiaoxi6.com/uploads/videos/video_150615277856836.png"];
    [_urlArr addObject:@"http://dev-cdd.xiaoxi6.com/uploads/videos/video_150615267342410.png"];
    [_urlArr addObject:@"http://dev-cdd.xiaoxi6.com/uploads/videos/video_150615266275882.png"];

    for (NSInteger i = 0; i < _urlArr.count; ++i)
    {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.backgroundColor = [UIColor redColor];
        [imageView sd_setImageWithURL:[NSURL URLWithString:_urlArr[i]] placeholderImage:nil];
        [self.view addSubview:imageView];
        imageView.tag = i;
        [_imageViewArr addObject:imageView];
        
        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        CGFloat w = (screenW - 100) / 4.f;
        CGFloat h = w;
        CGFloat x = 20 * (i % 4 + 1) + w * (i % 4);
        CGFloat y = 64 + (20 * (i / 4) + h * (i / 4));
        imageView.frame = CGRectMake(x, y, w, h);
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [tap addTarget:self action:@selector(tap:)];
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:tap];
    }
}

- (void)tap:(UITapGestureRecognizer *)tap
{
    YCPhotoBrowser *photoVC = [[YCPhotoBrowser alloc] initWithNibName:@"YCPhotoBrowser" bundle:nil];
    photoVC.imagesURLArr = _urlArr;
    photoVC.thumbnailsArr = _imageViewArr;
    photoVC.currentImageIndex = tap.view.tag;
    [photoVC showPhotoBrowser];
}

@end





