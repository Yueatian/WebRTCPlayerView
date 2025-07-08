//
//  RTCPlayView.h
//  WebRTCPlayerView
//
//  Created by Nacho's MBP on 2025/7/8.
//

#import <UIKit/UIKit.h>
#import "WebRTCClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface RTCPlayView : UIView

- (instancetype)initWithFrame:(CGRect)frame webRTCClient:(WebRTCClient *)webRTCClient;

@end

NS_ASSUME_NONNULL_END
