//
//  ReplyKitUnloader.m
//  extension-demo
//
//  Created by summerxx on 2023/1/4.
//

#import "ReplyKitUnloader.h"
#import "VideoH264EnCode.h"

@interface ReplyKitUnloader ()

@property (nonatomic, strong) VideoH264EnCode *h264code;

@end

@implementation ReplyKitUnloader

static ReplyKitUnloader *shareSingleton = nil;

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareSingleton = [[super allocWithZone:NULL] init];
    });
    return shareSingleton;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [ReplyKitUnloader shared];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return [ReplyKitUnloader shared];
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer sampleBufferType:(RPSampleBufferType)sampleBufferType
{
    [self.h264code encodeSampleBuffer:sampleBuffer H264DataBlock:^(NSData * data) {
        NSLog(@"%@", data);
        // 去推流
    }];
}

- (void)endEncode
{
    [self.h264code endEncode];
}

- (VideoH264EnCode *)h264code
{
    if (!_h264code) {
        _h264code = [[VideoH264EnCode alloc]init];
    }
    return _h264code;
}

- (void)printEnable:(BOOL)enable
{
    if (enable) {
        static int i = 0;
        i++;
        NSLog(@"您收到了%d条数据", i);
    }
}

- (void)sampleHandlerPrintEnable:(BOOL)enable
{
    if (enable) {
        static int i = 0;
        i++;
        NSLog(@"sampleHandlerPrintEnable = %d", i);
    }
}
@end
