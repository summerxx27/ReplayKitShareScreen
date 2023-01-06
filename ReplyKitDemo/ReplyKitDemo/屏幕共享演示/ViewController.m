//
//  ViewController.m
//  screen-share-ios
//
//  Created by summerxx on 2022/12/28.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>
#import <VideoToolbox/VideoToolbox.h>
#import "CaptureViewController.h"
#import "VideoH264EnCode.h"
#import "VideoH264Decoder.h"
#import "VideoDisplayLayer.h"
#import "NTESI420Frame.h"
#import "ReplyKitUnloader.h"
#import "FJDeepSleepPreventer.h"
#import "FJDeepSleepPreventerPlus.h"

static NSString * _Nonnull kAppGroup = @"group.summerxx.com.screen.share";
static void *KVOContext = &KVOContext;

@interface ViewController ()<VideoH264DecoderDelegate>

@property (nonatomic, strong) RPSystemBroadcastPickerView *broadcastPickerView;

// 编码
@property (nonatomic, strong) VideoH264EnCode *h264code;

// 解码以及播放
@property (nonatomic, strong) VideoDisplayLayer *playLayer;
@property (nonatomic, strong) VideoH264Decoder *h264Decoder;

@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) UILabel *label;

@end

@implementation ViewController

- (void)dealloc
{
    [self.userDefaults removeObserver:self forKeyPath:@"frame"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupDeCoder];
    [self setupUserDefaults];
    [self addObserver];
}

- (void)setupViews
{
    self.view.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:self.label];
    self.label.frame = CGRectMake(0, 100, UIScreen.mainScreen.bounds.size.width, 50);
    self.label.backgroundColor = UIColor.cyanColor;

    // 兼容 iOS12 或更高的版本
    if (@available(iOS 12.0, *)) {
        self.broadcastPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(50, 200, 100, 100)];
        self.broadcastPickerView.preferredExtension = @"summerxx.com.screen-share-ios.broadcast-extension";
        self.broadcastPickerView.backgroundColor = UIColor.redColor;
        self.broadcastPickerView.showsMicrophoneButton = YES;
        [self.view addSubview:self.broadcastPickerView];

        UIButton *button = [self.broadcastPickerView.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [evaluatedObject isKindOfClass:UIButton.class];
        }]].firstObject;
        [button setImage:nil forState:UIControlStateNormal];
        [button setTitle:@"开始共享" forState:UIControlStateNormal];
        [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }

    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    startButton.frame = CGRectMake(50, 310, 100, 100);
    startButton.backgroundColor = UIColor.redColor;
    [startButton setTitle:@"开启摄像头" forState:UIControlStateNormal];
    [startButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
}

// APP Group 数据传输
- (void)setupUserDefaults
{
    // 通过UserDefaults建立数据通道，接收Extension传递来的视频帧
    self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroup];
}

// 监听: 保活, 屏幕数据
- (void)addObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackGround) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

    // KVO
    [self.userDefaults addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:KVOContext];
}

- (void)willEnterForeground
{
    [[FJDeepSleepPreventerPlus sharedInstance] stop];
}

- (void)didEnterBackGround
{
    [[FJDeepSleepPreventerPlus sharedInstance] start];
}

// KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"]) {
        NSDictionary *i420Frame = change[NSKeyValueChangeNewKey];
        NSData *data = i420Frame[@"data"];
//        unsigned int width = [i420Frame[@"width"] unsignedIntValue];
//        unsigned int height = [i420Frame[@"height"] unsignedIntValue];

        NTESI420Frame *frame = [NTESI420Frame initWithData:data];
//        frame.width = width;
//        frame.height = height;
        CMSampleBufferRef sampleBuffer = [frame convertToSampleBuffer];

        // 防止内存泄漏
        if (sampleBuffer == NULL) {
            return;
        }

#warning 不需要解码, 屏幕共享的数据, 编码的同时解码, 内存会暴涨, 这个只用来测试画面
        __weak typeof(self) weakSelf = self;
        [self.h264code encodeSampleBuffer:sampleBuffer H264DataBlock:^(NSData * data) {
            NSLog(@"%@", data);
            // 测试可以解码
            // 正常情况应该去推流
//                [weakSelf didReadData:data];
        }];

        // 释放对象
        CFRelease(sampleBuffer);

        // 测试kvo是是否收到的 Log
        static int i = 0;
        i++;
        _label.text = [NSString stringWithFormat:@"您收到了%d条数据", i];
    }
}

#pragma mark - Action
- (void)startAction
{
    CaptureViewController *vc =  [CaptureViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Init
- (VideoH264EnCode *)h264code
{
    if (!_h264code) {
        _h264code = [[VideoH264EnCode alloc]init];
    }
    return _h264code;
}

- (UILabel *)label
{
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = UIColor.blackColor;
    }
    return _label;
}

#pragma mark - 解码以及播放操作
- (void)setupDeCoder
{
    self.h264Decoder = [[VideoH264Decoder alloc]init];
    self.h264Decoder.delegate = self;
    [self setupDisplayLayer];
}

- (void)setupDisplayLayer
{
    self.playLayer = [[VideoDisplayLayer alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 300, self.view.bounds.size.width, 300)];
    self.playLayer.backgroundColor = self.view.backgroundColor.CGColor;
    [self.view.layer addSublayer:self.playLayer];
}

// 获取数据进行解码
- (void)didReadData:(NSData *)data
{
    [self.h264Decoder decodeNalu:(uint8_t *)[data bytes] size:(uint32_t)data.length];
}

// 解码完成回调
- (void)decoder:(VideoH264Decoder *)decoder didDecodingFrame:(CVImageBufferRef)imageBuffer
{
    if (!imageBuffer) {
        return;
    }
    // 回主线程给 layer 进行展示
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    });
}

@end
