//
//  YCImageCell.h
//  PhotoBrowser
//
//  Created by YuChengGuo on 14-10-1.
//  Copyright (c) 2014年 YuChengGuo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YCPhotoBrowser.h"

@interface YCPhotoCell : UICollectionViewCell <UIScrollViewDelegate, UIActionSheetDelegate>
@property(nonatomic,weak)YCPhotoBrowser *photoBrowser;

//刷新图片
- (void)refreshImage:(NSString *)imageUrl selectedImage:(UIImage *)image selectedRow:(NSInteger)row;

@end
