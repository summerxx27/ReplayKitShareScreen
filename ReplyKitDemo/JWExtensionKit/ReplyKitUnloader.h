//
//  ReplyKitUnloader.h
//  extension-demo
//
//  Created by summerxx on 2023/1/4.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 用来推流解码, 如果扩展 app 向宿主 App 传数据有问题的话, 直接用这个类进行推流的逻辑
/// 数据上传类, 进行编码和推流
@interface ReplyKitUnloader : NSObject

/// 创建一个实例
+ (instancetype)shared;

/// 编码
/// - Parameters:
///   - sampleBuffer: 原数据
///   - sampleBufferType: 类型
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer sampleBufferType:(RPSampleBufferType)sampleBufferType;

/// 测试主工程打印 Log
/// - Parameter enable: 是否开启
- (void)printEnable:(BOOL)enable;

/// 测试扩展打印 Log
/// - Parameter enable: 是否开启
- (void)sampleHandlerPrintEnable:(BOOL)enable;

/// 结束编码
- (void)endEncode;
@end

NS_ASSUME_NONNULL_END
