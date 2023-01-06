//
//  VideoH264EnCode.h
//  InteractiveScreen
//
//  Created by 刘川 on 2018/12/3.
//  Copyright © 2018 王楠. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoH264EnCode : NSObject

/// 硬编码
/// - Parameters:
///   - sampleBuffer: CMSampleBufferRef每一帧原始数据
///   - h264DataBlock: 十六进制数据
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
             H264DataBlock:(void (^)(NSData *data))h264DataBlock;

/// 结束编码
- (void)endEncode;

@end

NS_ASSUME_NONNULL_END
