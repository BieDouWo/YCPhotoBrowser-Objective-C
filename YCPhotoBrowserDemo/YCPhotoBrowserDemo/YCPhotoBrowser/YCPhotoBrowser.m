//
//  YCPhotoBrowser.m
//  PhotoBrowser
//
//  Created by YuChengGuo on 14-10-1.
//  Copyright (c) 2014年 YuChengGuo. All rights reserved.
//

#import "YCPhotoBrowser.h"
#import "YCPhotoCell.h"

#define screenWidth  [[UIScreen mainScreen] bounds].size.width
#define screenHeight [[UIScreen mainScreen] bounds].size.height

@interface YCPhotoBrowser () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation YCPhotoBrowser
{
    NSString *_photoCellID;
}

static UIWindow *_window = nil;

#pragma mark- 加载视图
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //监听设备旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    self.view.backgroundColor = [UIColor clearColor];              //大背景开始设置为透明
    self.view.frame = CGRectMake(0, 0, screenWidth, screenHeight); //必须开始就指定全屏
    
    //记录开始时默认的设备方向
    self.orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    //设置图片滚动视图
    [self setImageCollectionView];
    
    //设置页数标签
    [self setPagesLabel];
    
    //去设置滚动到选中的图片位置
    [self setCurrentPhotoIndex];
}
#pragma mark- 设置图片滚动视图
- (void)setImageCollectionView
{
    //设置cell显示属性
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    //横向滚动
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //cell的大小
    layout.itemSize = CGSizeMake(screenWidth + 40, screenHeight);
    //cell之间的距离为0
    layout.minimumLineSpacing = 0;
    
    //设置列表视图
    self.imageCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-20, 0, screenWidth + 40, screenHeight)collectionViewLayout:layout];
    
    //判断ios11以上系统,不下移20
    if (@available(iOS 11.0, *)) {
        _imageCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    //设置为翻页模式
    self.imageCollectionView.pagingEnabled = YES;
    self.imageCollectionView.backgroundColor = [UIColor blackColor]; //滚动背景必须为黑色
    self.imageCollectionView.showsHorizontalScrollIndicator = NO;    //隐藏水平滚动条
    self.imageCollectionView.dataSource = self;
    self.imageCollectionView.delegate = self;
    [self.view addSubview:self.imageCollectionView];
    
    //注册cell
    _photoCellID = @"YCPhotoCell";
    [self.imageCollectionView registerClass:[YCPhotoCell class] forCellWithReuseIdentifier:_photoCellID];
}
#pragma mark- 设置页数标签
- (void)setPagesLabel
{
    //设置页数标签
    self.pagesLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 20)];
    self.pagesLabel.center = CGPointMake(screenWidth / 2, screenHeight - 20);
    self.pagesLabel.textColor = [UIColor whiteColor];
    self.pagesLabel.font = [UIFont systemFontOfSize:14];
    self.pagesLabel.textAlignment = NSTextAlignmentCenter;
    self.pagesLabel.alpha = 0; //开始为隐藏
    self.pagesLabel.autoresizesSubviews = YES;
    self.pagesLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    
    //设置阴影
    _pagesLabel.shadowColor = [UIColor blackColor];
    _pagesLabel.shadowOffset = CGSizeMake(1, 1);
    
    //设置点击页数
    self.pagesLabel.text = [NSString stringWithFormat:@"%d/%d", (int)self.currentImageIndex+1, (int)self.imagesURLArr.count];
    [self.view addSubview:self.pagesLabel];
}
#pragma mark- 计算全部缩略图片视图在屏幕下的位置和大小
- (void)computeThumbnailsRect
{
    self.thumbnailsRectArr = [NSMutableArray array];
    //计算这些缩略图在屏幕窗口下的位置大小
    NSValue *rectValue;
    CGRect thumbnailRect;
    UIImageView *thumbnailView;
    //循环计算这些缩略图在屏幕窗口下的位置大小
    for (int i = 0; i < self.imagesURLArr.count; i++) {
        //查看这张高清图是不是设置了缩略图了的
        for (int j = 0; j < self.thumbnailsArr.count; j++){
            thumbnailView = self.thumbnailsArr[j];
            if (i == thumbnailView.tag) {
                break;//找到了就结束
            }else{
                thumbnailView = nil;//没有找到
            }
        }
        //再次判断是不是高清图与缩略图对应
        if (i == thumbnailView.tag) {
           //有这张缩略图就记录在屏幕窗口下的位置大小
           thumbnailRect = [[thumbnailView superview] convertRect:thumbnailView.frame toView:_window];
        }else{
           //木有缩略图就设置y=100000,作放大效果处理
           thumbnailRect = CGRectMake(0, 100000, 0, 0);
        }
        //把CGRect转化为对象存数组
        rectValue = [NSValue valueWithCGRect:thumbnailRect];
        //存到数组
        [self.thumbnailsRectArr addObject:rectValue];
    }
}
#pragma mark- 设置滚动到选中的图片位置
- (void)setCurrentPhotoIndex
{
   //列表内容显示偏移到第n组第n行这里
    [self.imageCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentImageIndex inSection:0]  atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}
#pragma mark- 关闭图片浏览器
- (void)closePhotoBrowser
{
    _window.rootViewController = nil;
    _window.windowLevel = UIWindowLevelNormal - 1;
    [_window resignKeyWindow];
    [_window removeFromSuperview];
     _window = nil;
}
#pragma mark- 弹出图片浏览器
- (void)showPhotoBrowser
{
    _window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.backgroundColor = [UIColor clearColor];
    _window.windowLevel = UIWindowLevelAlert;
    [_window makeKeyAndVisible];
    _window.rootViewController = self;
    
    //去计算全部缩略图片视图在屏幕下的位置和大小
    [self computeThumbnailsRect];
    
    //去执行放大图片效果
    [self imageEnlarge];
}
#pragma mark- 图片放大到全屏效果
- (void)imageEnlarge
{
    //先隐藏图片浏览器
    self.imageCollectionView.alpha = 0;
    
    //找出点击的这张是否设置了缩略图
    UIImageView *thumbnailView;
    for (int j = 0; j < self.thumbnailsArr.count; j++){
        thumbnailView = self.thumbnailsArr[j];
        if (self.currentImageIndex == thumbnailView.tag) {
            break;//找到了就结束
        }else{
            thumbnailView = nil;//没有找到
        }
    }
    //判断点击的这张是否设置了缩略图
    if (thumbnailView) {
        //取出被点击的缩略图
        UIImageView *tapImageView = thumbnailView;
        //判断点击的这张缩略图木有加载到图片
        if (tapImageView.image == nil) {
            //直接显示图片浏览器
            [self directDisplayPhotoBrowser];
            return;
        }
        //设置假的图片视图放大效果
        UIImageView *imageView = [[UIImageView alloc] initWithImage:tapImageView.image];
        //取出他在屏幕下的位置和大小
        NSValue *rectVale = self.thumbnailsRectArr[self.currentImageIndex];
        imageView.frame = [rectVale CGRectValue];
        //UIViewContentModeScaleAspectFit,UIViewContentModeScaleAspectFill
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [self.view addSubview:imageView];
    
        //放大效果
        [UIView animateWithDuration:0.3 animations:^{
            //假视图放大到这个位置和大小
            imageView.frame = [self computingCenter:tapImageView.image];
            //大背景慢慢显示黑色
            self.view.backgroundColor = [UIColor blackColor];
        } completion:^(BOOL finished) {
            //动画停止删除这个假的放大图片视图
            [imageView removeFromSuperview];
            //显示图片浏览器
            self.imageCollectionView.alpha = 1;
            //显示页数标签
            self.pagesLabel.alpha = 1;
        }];
    }else{
        //直接显示图片浏览器
        [self directDisplayPhotoBrowser];
    }
}
#pragma mark- 点击的缩略图没设置或者没加载到图片就直接显示图片浏览器
- (void)directDisplayPhotoBrowser
{
    [UIView animateWithDuration:0.3 animations:^{
        //大背景慢慢显示黑色
        self.view.backgroundColor = [UIColor blackColor];
        //显示图片浏览器
        self.imageCollectionView.alpha = 1;
        //显示页数标签
        self.pagesLabel.alpha = 1;
    } completion:^(BOOL finished) {
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
    CGRect rect = CGRectMake(x, y, w, h);
    
    return rect;
}
#pragma mark- UICollectionView代理
//多少行
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.imagesURLArr.count;
}
//返回cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    YCPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:_photoCellID forIndexPath:indexPath];
    
    //把缩略图片传到cell
    UIImage *image;
    //找出这行的这张高清图是否设置了缩略图
    UIImageView *thumbnailView;
    
    for (int j = 0; j < self.thumbnailsArr.count; j++){
        thumbnailView = self.thumbnailsArr[j];
        if (indexPath.row == thumbnailView.tag) {
            break;//找到了就结束
        }else{
            thumbnailView = nil;//没有找到
        }
    }
    //判断有没有缩略图片
    if (thumbnailView.image) {
        image = thumbnailView.image;
    }else{
        image = nil;
    }
    
    //刷新图片
    [cell refreshImage:self.imagesURLArr[indexPath.row] selectedImage:image selectedRow:indexPath.row];
    cell.photoBrowser = self;
    
    return cell;
}
//正在滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //(当前偏移的位置)除(每次偏移的x)就是第几张,移到一半算一张
    CGFloat p = (scrollView.contentOffset.x / (screenWidth + 40)) + 0.5;
    NSInteger pages = (NSInteger)p;
    if (pages < _imagesURLArr.count && pages >= 0) {
        self.currentImageIndex = pages;//记录翻到的页数
        //设置页数
        self.pagesLabel.text = [NSString stringWithFormat:@"%zd/%zd", pages + 1, self.imagesURLArr.count];
    }
}
//已经结束滚动
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPhotoDidScroll object:nil];
}
#pragma mark- 监听设备旋转
- (void)deviceOrientationChange:(NSNotification *)notification
{
    //重新设置图片滚动视图的方向
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (_orientation != interfaceOrientation)
    {
        _orientation = interfaceOrientation;
        [self.imageCollectionView removeFromSuperview];
        self.imageCollectionView = nil;
        [self setImageCollectionView];
        
        //重新滚动到选中的图片位置
        [self setCurrentPhotoIndex];
        
        //设置页数标签放在最上面
        [self.view bringSubviewToFront:self.pagesLabel];
    }
}

@end





