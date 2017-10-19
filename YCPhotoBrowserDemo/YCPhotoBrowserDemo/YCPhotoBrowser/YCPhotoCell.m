//
//  YCImageCell.m
//  PhotoBrowser
//
//  Created by YuChengGuo on 14-10-1.
//  Copyright (c) 2014年 YuChengGuo. All rights reserved.
//

#import "YCPhotoCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SDWebImageManager.h"    
#import "UIImageView+WebCache.h"

#define screenWidth  [[UIScreen mainScreen] bounds].size.width
#define screenHeight [[UIScreen mainScreen] bounds].size.height

@implementation YCPhotoCell
{
    UIImageView *_imageView;             //图片视图
    UIScrollView *_imageScrollView;      //显示图片放大的滚动视图
    UIActivityIndicatorView *_actView;   //图片下载菊花视图
    NSInteger _selectedRow;              //记录翻到了那张图片
}
#pragma mark- 初始化
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self setScrollView];
        [self setImageView];
        [self radialProgressView];
        
        //监听照片停止滚动的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoDidScroll) name:kPhotoDidScroll object:nil];
    }
    return self;
}
#pragma mark- 设置滚动视图
- (void)setScrollView
{
    //滚动视图设置
    _imageScrollView = [[UIScrollView alloc]init];
    _imageScrollView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    _imageScrollView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    _imageScrollView.backgroundColor = [UIColor blackColor];//这个背景必须为黑色
    
    //设置滚动视图自带缩放的一些属性(在代理函数里指定那个视图可缩放,必须是加入到了滚动视图里的)
    _imageScrollView.maximumZoomScale = 4;   //放大到最大是5倍(这个可以不设置),1为不放大
    _imageScrollView.zoomScale = 1;          //设置放大缩小值(大于1为放大,小于1为缩小,等于1为原大小)
    _imageScrollView.minimumZoomScale = 1;   //缩小到最小是0.2倍(这个必须设置),1为不缩小
    _imageScrollView.showsHorizontalScrollIndicator = NO; //隐藏水平滚动条
    _imageScrollView.showsVerticalScrollIndicator = NO;   //隐藏垂直滚动条
    _imageScrollView.delegate = self;
    [self addSubview:_imageScrollView];
    
    //判断ios11以上系统,不下移20
    if (@available(iOS 11.0, *)) {
        _imageScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    //点击手势
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] init];
    [tap1 addTarget:self action:@selector(tapImage:)];
    [_imageScrollView addGestureRecognizer:tap1];
    
    //双击手势
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] init];
    [tap1 requireGestureRecognizerToFail:tap2];     //防止同时响应这2个手势
    [tap2 addTarget:self action:@selector(dblclickImage:)];
    tap2.numberOfTapsRequired = 2;                  //设置为双击手势
    [_imageScrollView addGestureRecognizer:tap2];
    
    //长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [tap2 requireGestureRecognizerToFail:longPress];
    //设置长按0.5秒调用第一次
    longPress.minimumPressDuration = 0.5;
    [_imageScrollView addGestureRecognizer:longPress];
}
#pragma mark- 设置图片视图
- (void)setImageView
{
    //设置图片视图
    _imageView = [[UIImageView alloc]init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_imageScrollView addSubview:_imageView];
}
#pragma mark- 设置进度视图
- (void)radialProgressView
{
    //菊花视图
    _actView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _actView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    _actView.color = [UIColor whiteColor];
    [self addSubview:_actView];
}
#pragma mark- 图片下载处理
//刷新图片
-(void)refreshImage:(NSString *)imageUrl selectedImage:(UIImage *)image selectedRow:(NSInteger)row;
{
    //记录翻到了那张图片
    _selectedRow = row;
    
    //复用cell时,先还原图片大小
    _imageScrollView.zoomScale = 1;
    
    //开始转圈
    [_actView startAnimating];
     _actView.hidesWhenStopped = NO;
    
    //设置新传来的缩略图
    _imageView.image = image;
    
    //如果有缩略图就计算位置大小
    if (image != nil) {
        _imageView.frame = [self computingCenter:image];
    }

    //下载图片(SDWebImageRetryFailed:失败后重试)
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager loadImageWithURL:[NSURL URLWithString:imageUrl] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
        //设置进度
        //NSLog(@"%ld",receivedSize);

    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        
        //如果断网会木有下载到图片就结束,不然会崩溃
        if (image == nil) {
            return;
        }
        
        //设置图片视图的位置大小
        _imageView.frame = [self computingCenter:image];
        
        //这样设置为了显示动态图片
        [_imageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:nil];
        
        //停止转圈
        [_actView stopAnimating];
        _actView.hidesWhenStopped = YES;
    }];
}
#pragma mark- 计算UIImageView宽度和高度等比例自适应UIImage高,图片视图居中位置
- (CGRect)computingCenter:(UIImage *)image
{
    CGFloat w = screenHeight * (image.size.width / image.size.height);
    CGFloat h = screenWidth * (image.size.height / image.size.width);
    //判断如果计算的宽度大于屏幕宽度就设置为屏幕宽
    if (w > screenWidth) {
        w = screenWidth;
    }
    //判断如果计算的高度大于屏幕高度就设置为屏幕高
    if (h > screenHeight) {
        h = screenHeight;
    }
    //计算UIImageView在屏幕中间的w坐标和y坐标
    CGFloat x = (screenWidth - w) / 2;
    CGFloat y = (screenHeight - h) / 2;
    //记录这个位置和大小
    CGRect rect=CGRectMake(x, y, w, h);
    
    return rect;
}
#pragma mark- 照片停止滚动的通知
- (void)photoDidScroll
{
    //判断这张图片已被翻过,还原图片大小
    if (_selectedRow != _photoBrowser.currentImageIndex) {
        _imageScrollView.zoomScale = 1;
    }
}
#pragma mark- 单击图片
- (void)tapImage:(UITapGestureRecognizer *)tap
{
    //隐藏页数标签
    self.photoBrowser.pagesLabel.alpha = 0;
    
    //取出当前滚动到的图片的缩略图在屏幕下的位置和大小
    NSValue *rectVale = self.photoBrowser.thumbnailsRectArr[_selectedRow];
    CGRect rect = [rectVale CGRectValue];
    //判断这张图的缩略图是不是在屏幕范围里
    if (rect.origin.y <= screenHeight - 49 - rect.size.height && rect.origin.y >= 64) {
        //缩小到原来位置大小在删除
        [UIView animateWithDuration:0.3 animations:^{
            //全部背景慢慢透明
            self.photoBrowser.view.backgroundColor = [UIColor clearColor];
            self.photoBrowser.imageCollectionView.backgroundColor = [UIColor clearColor];
            _imageScrollView.backgroundColor = [UIColor clearColor];
            
            //直接内容区域还原原大小
            _imageScrollView.contentSize = CGSizeMake(screenWidth, screenHeight);
            
            //当前滚到的图片视图慢慢回到缩略图时的位置和大小
            _imageView.frame = rect;
            
            //延迟设置图片视图内容模式
            [self performSelector:@selector(setImageViewContentMode) withObject:nil afterDelay:0.1];
            _imageView.clipsToBounds = YES;
            
        }completion:^(BOOL finished) {
            //删除视图(关闭图片浏览器)
            [self.photoBrowser closePhotoBrowser];
        }];
    }else{
        //图片视图慢慢放大消失
        [UIView animateWithDuration:0.3 animations:^{
            //全部背景慢慢透明
            self.photoBrowser.view.backgroundColor = [UIColor clearColor];
            self.photoBrowser.imageCollectionView.backgroundColor = [UIColor clearColor];
            _imageScrollView.backgroundColor = [UIColor clearColor];
            
            //当前滚到的图片视图慢慢放大消失
            _imageView.transform = CGAffineTransformScale(_imageView.transform, 1.2, 1.2);
            _imageView.alpha = 0;
            
        } completion:^(BOOL finished) {
            //删除视图(关闭图片浏览器)
            [self.photoBrowser closePhotoBrowser];
        }];
    }
}
#pragma mark- 缩小效果必须延迟设置图片视图内容模式
- (void)setImageViewContentMode
{
    //UIViewContentModeScaleAspectFit,UIViewContentModeScaleAspectFill
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
}
#pragma mark- 双击图片
-(void)dblclickImage:(UITapGestureRecognizer *)tap
{
    //双击图片的位置
    CGPoint touchPoint = [tap locationInView:self];
    //判断装图片的滚动视图有没有被放大
    if (_imageScrollView.zoomScale == 1) {
        //放大
        [_imageScrollView zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
    } else {
        //缩小
        [_imageScrollView setZoomScale:_imageScrollView.minimumZoomScale animated:YES];
    }
}
#pragma mark- 计算图片x,y坐标
- (void)centerScrollViewContents
{
    //屏幕大小
    CGSize boundsSize = [[UIScreen mainScreen] bounds].size;
    CGRect contentsFrame = _imageView.frame;
    //计算x坐标
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        //当图片放大的宽大于屏幕宽,设置x坐标为0
        contentsFrame.origin.x = 0.0f;
    }
    //计算y坐标
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        //当图片放大的高大于屏幕高,设置y坐标为0
        contentsFrame.origin.y = 0.0f;
    }
    //重新设置图片视图位置
    _imageView.frame = contentsFrame;
}
#pragma mark- UIScrollView代理
//正在缩放
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centerScrollViewContents];
}
//尝试进行缩放的时候调用
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    //返回要缩放的图片视图
    return _imageView;
}
#pragma mark- 默认是长按0.5后调用第一次,手放开再调一次
- (void)longPress:(UILongPressGestureRecognizer *)press
{
    if(press.state == UIGestureRecognizerStateBegan)
    {
        UIAlertController *alertVC= [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *alertAction1 = [UIAlertAction actionWithTitle:@"保存到本地相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
             //保存图片到相册
             [self saveImage];
        }];;
        [alertVC addAction:alertAction1];
        
        UIAlertAction *alertAction2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:alertAction2];
        
        [_photoBrowser presentViewController:alertVC animated:YES completion:nil];
    }
}
#pragma mark- 导出图片到相册
- (void)saveImage
{
    //判断没有权限访问相册
    if (![self isAlbumPermission]) {
        //获取app名字
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        NSString *msg = [NSString stringWithFormat:@"请在(设置-隐私-相机)中允许%@访问你的相机",appName];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"没有权限访问照片" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
        
        return;
    }
    
    //开始保存
    UIImage *image = _imageView.image;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                
        //请求创建一个imageAsset
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        //为Asset创建一个占位符,放到相册编辑请求中
        PHObjectPlaceholder *placeHolder = [assetRequest placeholderForCreatedAsset];
        
        //请求编辑相册
        PHAssetCollection *assetCollection = [[PHAssetCollection alloc] init];
        PHAssetCollectionChangeRequest *collectonRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        
        //相册中添加照片
        [collectonRequest addAssets:@[placeHolder]];
        
    } completionHandler:^(BOOL success, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *msg = nil ;
            if(success){
                msg = @"保存成功";
            }else{
                msg = @"保存失败";
            }
            UIAlertController *alertVC= [UIAlertController alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [alertVC addAction:alertAction];
            
            [_photoBrowser presentViewController:alertVC animated:YES completion:nil];
        });
    }];
}
#pragma mark- 判断是否有权限访问相册
- (BOOL)isAlbumPermission
{
    PHAuthorizationStatus author = [PHPhotoLibrary authorizationStatus];
    if (author == PHAuthorizationStatusRestricted || author == PHAuthorizationStatusDenied) {
        return NO;//无权限
    }
    return YES;
}

@end


