# DeterminDownloadDemo
[@Lefe_x](https://weibo.com/p/1005055953150140/home?from=page_100505&mod=TAB&is_hot=1#place)提出了一个常见的需求: 


![](https://wx3.sinaimg.cn/mw690/006uSOiEly1fqgibf91wij30ic1xvdlz.jpg)


感受到这个需求的普遍性，虽然流程不复杂，但是却有着不同的实现方法，且体现出不同的优雅程度. 也许当遇到更加复杂的流程时，更优雅的实现将有效提高代码可读性和可调试性。

此Demo是这个需求的实现Demo，只是把下载音频改为下载图片, 给出了基于callback,PromiseKit,rj_async的三种实现.其中callback，PromiseKit是[@Lefe_x](https://weibo.com/p/1005055953150140/home?from=page_100505&mod=TAB&is_hot=1#place)已经提出的，我只是照着敲了一边代码:
```Objective-C
//callback实现
- (void)onCbDownloadButton:(id)sender {
    _downloadedImageView.image = nil;
    //确定是否可以下载
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

//PromiseKit实现
- (void)onPmkDownloadButton:(id)sender {
    _downloadedImageView.image = nil;
    //确定是否可以下载
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
```

rj_async实现方式是基于[RJIterator](https://github.com/renjinkui2719/RJIterator)中的async异步块:
```Objective-C
- (void)onRjDownloadButton:(id)sender {
    _downloadedImageView.image = nil;
    
    rj_async(^{
        //决定是否可以下载
        if (![rj_await([self rjDeterminDownload]).value boolValue]) {
            //不可下载
            return;
        }

        //请求下载地址
        [_rjDownloadButton setTitle:@"获取下载地址..." forState:UIControlStateNormal];
        _rjDownloadButton.enabled = YES;
        _cbDownloadButton.hidden = YES;
        _pmkDownloadButton.hidden = YES;
        
        NSString *url = rj_await([self rjQueryDownloadUrl]).value;
        if (!url) {
            //获取下载地址失败
            [[[Alert alloc] initWithTitle:@"提示" message:@"获取下载地址失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
            return;
        }
       
        //开始下载
        [_rjDownloadButton setTitle:@"下载中..." forState:UIControlStateNormal];
        UIImage *image = rj_await([self rjDownloadImageWithUrl:url]).value;
        if (!image) {
            //下载失败
            [[[Alert alloc] initWithTitle:@"提示" message:@"下载失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil] show];
            return;
        }
        //下载成功
        _downloadedImageView.image = image;
    })
    .finally(^{
        //恢复UI
        [_rjDownloadButton setTitle:@"rj_async决定下载" forState:UIControlStateNormal];
        _rjDownloadButton.enabled = YES;
        _cbDownloadButton.hidden = NO;
        _pmkDownloadButton.hidden = NO;
    });
}

```

#### 三种方式都找得出优劣，重在探讨。
