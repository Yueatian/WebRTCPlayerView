//
//  HttpClient.h
//  WebRTCPlayerView
//
//  Created by Nacho's MBP on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

NS_ASSUME_NONNULL_BEGIN

@interface HttpClient : NSObject<NSURLSessionDelegate>

- (void)changeSDP2Server:(RTCSessionDescription *)sdp
                  urlStr:(NSString *)urlStr
                 closure:(void (^)(RTCSessionDescription *result))closure;

@end

NS_ASSUME_NONNULL_END
