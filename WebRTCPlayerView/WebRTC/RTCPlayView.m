//
//  RTCPlayView.m
//  WebRTCPlayerView
//
//  Created by Nacho's MBP on 2025/7/8.
//

#import "RTCPlayView.h"


@interface RTCPlayView ()<RTCVideoViewDelegate>

@property (nonatomic, assign) CGSize remoteVideoSize;
@property (nonatomic, strong) WebRTCClient *webRTCClient;
@property (nonatomic, strong) RTCEAGLVideoView *remoteRenderer;

@end


@implementation RTCPlayView

- (instancetype)initWithFrame:(CGRect)frame webRTCClient:(WebRTCClient *)webRTCClient {
    self = [super initWithFrame:frame];
    if (self) {
        self.webRTCClient = webRTCClient;
        
        self.remoteRenderer = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
        self.remoteRenderer.delegate = self;
        self.remoteRenderer.backgroundColor = [UIColor clearColor];
        self.remoteRenderer.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.remoteRenderer];
        self.webRTCClient.remoteRenderView = self.remoteRenderer;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    NSLog(@"remoteRendererBounds: %@",NSStringFromCGRect(bounds));
    if (_remoteVideoSize.width > 0 && _remoteVideoSize.height > 0) {
        CGRect remoteVideoFrame =
        AVMakeRectWithAspectRatioInsideRect(_remoteVideoSize, bounds);
        CGFloat scale = 1;
        if (remoteVideoFrame.size.width > remoteVideoFrame.size.height) {
            scale = bounds.size.height / remoteVideoFrame.size.height;
        } else {
            scale = bounds.size.width / remoteVideoFrame.size.width;
        }
        remoteVideoFrame.size.height *= scale;
        remoteVideoFrame.size.width *= scale;
        self.remoteRenderer.frame = remoteVideoFrame;
        NSLog(@"remoteRendererFrame: %@",NSStringFromCGRect(remoteVideoFrame));
        self.remoteRenderer.center =
        CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    } else {
        self.remoteRenderer.frame = bounds;
    }
}

- (void)videoView:(id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size{
    if (videoView == self.remoteRenderer) {
        _remoteVideoSize = size;
    }
    [self setNeedsLayout];
}

@end
