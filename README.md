# DeterminDownloadDemo
[@Lefe_x](https://weibo.com/p/1005055953150140/home?from=page_100505&mod=TAB&is_hot=1#place)提出了一个常见的需求: 


![](https://wx3.sinaimg.cn/mw690/006uSOiEly1fqgibf91wij30ic1xvdlz.jpg)


感受到这个需求的普遍性，虽然流程不复杂，但是却有着不同的实现方法，且体现出不同的优雅程度. 也许当遇到更加复杂的流程时，更优雅的实现将有效提高代码可读性和可调试性。

此Demo是这个需求的实现Demo，只是把下载音频改为下载图片, 给出了基于callback,PromiseKit,rj_async的三种实现.其中callback，PromiseKit是[@Lefe_x](https://weibo.com/p/1005055953150140/home?from=page_100505&mod=TAB&is_hot=1#place)已经提出的，我只是照着敲了一边代码.
rj_async实现方式是基于[RJIterator](https://github.com/renjinkui2719/RJIterator)中的async异步块。

三种方式都找得出优劣，重在探讨。
