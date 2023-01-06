//
//  SampleHandler.m
//  extension-demo
//
//  Created by summerxx on 2022/12/29.
//

#import "SampleHandler.h"
#import "ReplyKitUnloader.h"
#import "libyuv.h"
#import "NTESYUVConverter.h"
#import "NTESI420Frame.h"

// 自己的App Group
static NSString * _Nonnull kAppGroup = @"group.summerxx.com.screen.share";

@interface SampleHandler()

@property (nonatomic, strong) NSUserDefaults *userDefautls;

@end

@implementation SampleHandler


- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo
{
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    self.userDefautls = [[NSUserDefaults alloc] initWithSuiteName:kAppGroup];
}

- (void)broadcastPaused
{
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed
{
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished
{
    // User has requested to finish the broadcast.
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType
{

    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
        {
            // Handle video sample buffer

            @autoreleasepool {
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

                float cropRate = (float)CVPixelBufferGetWidth(pixelBuffer) / (float)CVPixelBufferGetHeight(pixelBuffer);
//                CGSize targetSize = CGSizeMake(360, 360 / cropRate);
                CGSize targetSize = CGSizeMake(540, 960);
                NTESVideoPackOrientation targetOrientation = NTESVideoPackOrientationPortrait;
                if (@available(iOS 11.0, *)) {
                    CFStringRef RPVideoSampleOrientationKeyRef = (__bridge CFStringRef)RPVideoSampleOrientationKey;
                    NSNumber *orientation = (NSNumber *)CMGetAttachment(sampleBuffer, RPVideoSampleOrientationKeyRef,NULL);
                    if (orientation.integerValue == kCGImagePropertyOrientationUp ||
                        orientation.integerValue == kCGImagePropertyOrientationUpMirrored) {
                        targetOrientation = NTESVideoPackOrientationPortrait;
                    } else if(orientation.integerValue == kCGImagePropertyOrientationDown ||
                              orientation.integerValue == kCGImagePropertyOrientationDownMirrored) {
                        targetOrientation = NTESVideoPackOrientationPortraitUpsideDown;
                    } else if (orientation.integerValue == kCGImagePropertyOrientationLeft ||
                               orientation.integerValue == kCGImagePropertyOrientationLeftMirrored) {
                        targetOrientation = NTESVideoPackOrientationLandscapeLeft;
                    } else if (orientation.integerValue == kCGImagePropertyOrientationRight ||
                               orientation.integerValue == kCGImagePropertyOrientationRightMirrored) {
                        targetOrientation = NTESVideoPackOrientationLandscapeRight;
                    }
                }
                NTESI420Frame *videoFrame = [NTESYUVConverter pixelBufferToI420:pixelBuffer
                                                                       withCrop:cropRate
                                                                     targetSize:targetSize
                                                                 andOrientation:targetOrientation];
                NSDictionary *frame = @{
                    @"width": @(videoFrame.width),
                    @"height": @(videoFrame.height),
                    @"data": [videoFrame bytes],
                    @"timestamp": @(CACurrentMediaTime() * 1000)
                };
                [self.userDefautls setObject:frame forKey:@"frame"];
                [self.userDefautls synchronize];
            }
        }
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;

        default:
            break;
    }
}

// 暂时无用
- (void)encode:(CMSampleBufferRef)sampleBuffer sampleBufferType:(RPSampleBufferType)sampleBufferType
{
    [[ReplyKitUnloader shared] sampleHandlerPrintEnable:YES];
    [[ReplyKitUnloader shared] encodeSampleBuffer:sampleBuffer sampleBufferType:sampleBufferType];
}

@end
