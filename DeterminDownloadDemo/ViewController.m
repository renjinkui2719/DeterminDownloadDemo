//
//  ViewController.m
//  DeterminDownloadDemo
//
//  Created by renjinkui on 2018/4/23.
//  Copyright © 2018年 JK. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"

#import <Alert/Alert.h>
#import <PromiseKit/PromiseKit.h>
#import <RJIterator/RJIterator.h>

#define DOWNLOAD_URL @"http://oem96wx6v.bkt.clouddn.com/bizhi-1030-1097-2.jpg"
//改变某个宏为1强制触发错误
#define MAKE_QUERY_URL_ERROR 0
#define MAKE_DOWNLOAD_ERROR 0

@interface ViewController ()
@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic, strong) UIButton *cbDownloadButton;
@property (nonatomic, strong) UIButton *pmkDownloadButton;
@property (nonatomic, strong) UIButton *rjDownloadButton;
@property (nonatomic, strong) UIImageView *downloadedImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _reachability = [Reachability reachabilityWithHostName:@"www.apple.com"];
    
    _cbDownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cbDownloadButton.backgroundColor = [UIColor blueColor];
    _cbDownloadButton.frame = CGRectMake(20, 90, self.view.frame.size.width - 2 * 20, 50);
    [_cbDownloadButton setTitle:@"callback决定下载" forState:UIControlStateNormal];
    [_cbDownloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_cbDownloadButton addTarget:self action:@selector(onCbDownloadButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cbDownloadButton];
    
    _pmkDownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _pmkDownloadButton.backgroundColor = [UIColor blueColor];
    _pmkDownloadButton.frame = CGRectMake(_cbDownloadButton.frame.origin.x, CGRectGetMaxY(_cbDownloadButton.frame) + 10, _cbDownloadButton.frame.size.width, _cbDownloadButton.frame.size.height);
    [_pmkDownloadButton setTitle:@"PromiseKit决定下载" forState:UIControlStateNormal];
    [_pmkDownloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_pmkDownloadButton addTarget:self action:@selector(onPmkDownloadButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_pmkDownloadButton];
    
    _rjDownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _rjDownloadButton.backgroundColor = [UIColor blueColor];
    _rjDownloadButton.frame = CGRectMake(_cbDownloadButton.frame.origin.x, CGRectGetMaxY(_pmkDownloadButton.frame) + 10, _pmkDownloadButton.frame.size.width, _pmkDownloadButton.frame.size.height);
    [_rjDownloadButton setTitle:@"rj_async决定下载" forState:UIControlStateNormal];
    [_rjDownloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_rjDownloadButton addTarget:self action:@selector(onRjDownloadButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_rjDownloadButton];
    
    _downloadedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(_rjDownloadButton.frame.origin.x, CGRectGetMaxY(_rjDownloadButton.frame) + 20, _rjDownloadButton.frame.size.width, self.view.frame.size.height - CGRectGetMaxY(_rjDownloadButton.frame) - 40)];
    _downloadedImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_downloadedImageView];
}

#pragma mark - callback决定下载
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
- (void)onCbDownloadButton:(id)sender {
    _downloadedImageView.image = nil;
    
    [self cbDeterminDownloadWithCallback:^(BOOL download) {
        if (!download) {
            return;
        }
        //请求下载地址
        [_cbDownloadButton setTitle:@"获取下载地址..." forState:UIControlStateNormal];
        _cbDownloadButton.enabled = NO;
        _pmkDownloadButton.hidden = YES;
        _rjDownloadButton.hidden = YES;
        
        [self cbQueryDownloadUrlWithCallback:^(NSString *url) {
            if (url) {
                //下载
                [_cbDownloadButton setTitle:@"下载中..." forState:UIControlStateNormal];
                
                [self cbDownloadImageWithUrl:url callback:^(UIImage *image) {
                    //下载成功
                    if (image) {
                        _downloadedImageView.image = image;
                    }
                    else {
                        //下载失败
                        [[[Alert alloc] initWithTitle:@"提示" message:@"下载失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
                    }
                    //恢复UI
                    [_cbDownloadButton setTitle:@"callback决定下载" forState:UIControlStateNormal];
                    _cbDownloadButton.enabled = YES;
                    _pmkDownloadButton.hidden = NO;
                    _rjDownloadButton.hidden = NO;
                }];
            }
            else {
                [[[Alert alloc] initWithTitle:@"提示" message:@"获取下载地址失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
                //恢复UI
                [_cbDownloadButton setTitle:@"callback决定下载" forState:UIControlStateNormal];
                _cbDownloadButton.enabled = YES;
                _pmkDownloadButton.hidden = NO;
                _rjDownloadButton.hidden = NO;
            }
        }];
    }];

}

//是否下载
- (void)cbDeterminDownloadWithCallback:(void (^)(BOOL download))callback {
    //当前网络未连接
    if (_reachability.currentReachabilityStatus == NotReachable) {
        [[[Alert alloc] initWithTitle:@"提示" message:@"当前无网络连接,请检查网络" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
        callback(NO);
        return;
    }
    //当前是Wifi连接
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        callback(YES);
        return;
    }
    //弹框决定
    Alert *alert = [[Alert alloc] initWithTitle:@"提示" message:@"当前正使用2/3/4G网络，继续下载将产生流量费用，是否确定下载" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"下载", nil];
    [alert setClickBlock:^(Alert *alertView, NSInteger buttonIndex) {
        callback(buttonIndex == 1);
    }];
    [alert show];
}
//请求下载地址
- (void)cbQueryDownloadUrlWithCallback:(void (^)(NSString * url))callback {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
#if MAKE_QUERY_URL_ERROR
        callback(nil);
#else
        callback(DOWNLOAD_URL);
#endif
    });
}
//下载
- (void)cbDownloadImageWithUrl:(NSString *)url callback:(void( ^)(UIImage *image))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        UIImage *image = data ? [UIImage imageWithData:data] : nil;
        
        [NSThread sleepForTimeInterval:2.0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
#if MAKE_DOWNLOAD_ERROR
            callback(nil);
#else
            callback(image);
#endif
        });
    });
}


#pragma mark - PromiseKit决定下载
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
- (void)onPmkDownloadButton:(id)sender {
    _downloadedImageView.image = nil;
    
    [self pmkDeterminDownload]
    .then(^{
        //可以下载，请求下载地址
        [_pmkDownloadButton setTitle:@"获取下载地址..." forState:UIControlStateNormal];
        _pmkDownloadButton.enabled = NO;
        _cbDownloadButton.hidden = YES;
        _rjDownloadButton.hidden = YES;
        
        return [self pmkQueryDownloadUrl];
    })
    .then(^(NSString *url) {
        //获取下载地址成功
        //开始下载
        [_pmkDownloadButton setTitle:@"下载中..." forState:UIControlStateNormal];
        return [self pmkDownloadImageWithUrl:url];
    })
    .then(^(UIImage *image) {
        //下载成功
        _downloadedImageView.image = image;
    })
    .catch(^(NSError *error) {
        //出错提示
        if (error.code == -3) {
            [[[Alert alloc] initWithTitle:@"提示" message:@"获取下载地址失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
        }
        else if (error.code == -4) {
            [[[Alert alloc] initWithTitle:@"提示" message:@"下载失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
        }
    })
    .ensure(^{
        //恢复UI
        [_pmkDownloadButton setTitle:@"PromiseKit决定下载" forState:UIControlStateNormal];
        _pmkDownloadButton.enabled = YES;
        _cbDownloadButton.hidden = NO;
        _rjDownloadButton.hidden = NO;
    });
}

//决定是否可以下载
- (AnyPromise *)pmkDeterminDownload {
    return [AnyPromise promiseWithAdapterBlock:^(PMKAdapter  _Nonnull adapter) {
        //当前网络未连接
        if (_reachability.currentReachabilityStatus == NotReachable) {
            [[[Alert alloc] initWithTitle:@"提示" message:@"当前无网络连接,请检查网络" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
            adapter(nil, [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:nil]);
            return;
        }
        //当前是Wifi连接
        if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
            adapter(nil, nil);
            return;
        }
        //流量连接,弹框确认
        Alert *alert = [[Alert alloc] initWithTitle:@"提示" message:@"当前正使用2/3/4G网络，继续下载将产生流量费用，是否确定下载" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"下载", nil];
        [alert setClickBlock:^(Alert *alertView, NSInteger buttonIndex) {
            adapter(nil, buttonIndex == 1 ? nil : [NSError errorWithDomain:NSURLErrorDomain code:-2 userInfo:nil]);
        }];
        [alert show];
    }];
}
//请求下载地址
- (AnyPromise *)pmkQueryDownloadUrl {
    return [AnyPromise promiseWithAdapterBlock:^(PMKAdapter  _Nonnull adapter) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
#if MAKE_QUERY_URL_ERROR
            NSString *url = nil;
#else
            NSString *url = DOWNLOAD_URL;
#endif
            adapter(url, url ? nil : [NSError errorWithDomain:NSURLErrorDomain code:-3 userInfo:nil]);
        });
    }];
}
//下载
- (AnyPromise *)pmkDownloadImageWithUrl:(NSString *)url {
    return [AnyPromise promiseWithAdapterBlock:^(PMKAdapter  _Nonnull adapter) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            UIImage *image = data ? [UIImage imageWithData:data] : nil;
            
            [NSThread sleepForTimeInterval:2.0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
#if MAKE_DOWNLOAD_ERROR
                adapter(nil, [NSError errorWithDomain:NSURLErrorDomain code:-4 userInfo:nil]);
#else
                adapter(image, image ? nil : [NSError errorWithDomain:NSURLErrorDomain code:-4 userInfo:nil]);
#endif
            });
        });
    }];
}

#pragma mark - rj_async决定下载
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
- (void)onRjDownloadButton:(id)sender {
    _downloadedImageView.image = nil;
    
    rj_async(^{
        RJResult *result = nil;
        //决定是否可以下载
        result = rj_await([self rjDeterminDownload]);
        //不可下载
        if (![result.value boolValue]) {
            return;
        }

        //请求下载地址
        [_rjDownloadButton setTitle:@"获取下载地址..." forState:UIControlStateNormal];
        _rjDownloadButton.enabled = YES;
        _cbDownloadButton.hidden = YES;
        _pmkDownloadButton.hidden = YES;
        
        result = rj_await([self rjQueryDownloadUrl]);
        if (!result.value) {
            //获取下载地址失败
            [[[Alert alloc] initWithTitle:@"提示" message:@"获取下载地址失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
            return;
        }
        NSString *url = result.value;
       
        //开始下载
        [_rjDownloadButton setTitle:@"下载中..." forState:UIControlStateNormal];
        result = rj_await([self rjDownloadImageWithUrl:url]);
        if (!result.value) {
            //下载失败
            [[[Alert alloc] initWithTitle:@"提示" message:@"下载失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
            return;
        }
        //下载成功
        _downloadedImageView.image = result.value;
    })
    .finally(^{
        //恢复UI
        [_rjDownloadButton setTitle:@"rj_async决定下载" forState:UIControlStateNormal];
        _rjDownloadButton.enabled = YES;
        _cbDownloadButton.hidden = NO;
        _pmkDownloadButton.hidden = NO;
    });
}

//决定是否可以下载
- (RJAsyncClosure)rjDeterminDownload {
    return ^(RJAsyncCallback callback) {
        //当前网络未连接
        if (_reachability.currentReachabilityStatus == NotReachable) {
            [[[Alert alloc] initWithTitle:@"提示" message:@"当前无网络连接,请检查网络" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
            callback(@(NO), nil);
            return;
        }
        //当前是Wifi连接
        if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
            callback(@(YES), nil);
            return;
        }
        //流量连接,弹框确认
        Alert *alert = [[Alert alloc] initWithTitle:@"提示" message:@"当前正使用2/3/4G网络，继续下载将产生流量费用，是否确定下载" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"下载", nil];
        [alert setClickBlock:^(Alert *alertView, NSInteger buttonIndex) {
            callback(@(buttonIndex == 1), nil);
        }];
        [alert show];
    };
}
//请求下载地址
- (RJAsyncClosure)rjQueryDownloadUrl {
    return ^(RJAsyncCallback callback) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
#if MAKE_QUERY_URL_ERROR
            callback(nil, nil);
#else
            callback(DOWNLOAD_URL, nil);
#endif
        });
    };
}
//下载
- (RJAsyncClosure)rjDownloadImageWithUrl:(NSString *)url {
    return ^(RJAsyncCallback callback) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            UIImage *image = data ? [UIImage imageWithData:data] : nil;
            
            [NSThread sleepForTimeInterval:2.0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
#if MAKE_DOWNLOAD_ERROR
                callback(nil, nil);
#else
                callback(image, nil);
#endif
            });
        });
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
