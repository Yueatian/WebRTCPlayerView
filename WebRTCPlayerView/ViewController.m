//
//  ViewController.m
//  WebRTCPlayerView
//
//  Created by Nacho's MBP on 2025/7/8.
//

#import "ViewController.h"

static NSString* urlString = @"https://stream.luyantech.com:1990/rtc/v1/whep/?app=live&stream=livestream111469";

@interface ViewController ()<WebRTCClientDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    
    WebRTCClient *webRTCClient = [[WebRTCClient alloc] initWithPublish];
    webRTCClient.delegate = self;
    
    RTCPlayView* rtcPlayView = [[RTCPlayView alloc] initWithFrame:CGRectZero webRTCClient:webRTCClient];
    [self.view addSubview: rtcPlayView];
    rtcPlayView.backgroundColor = [UIColor clearColor];
    rtcPlayView.contentMode = UIViewContentModeScaleAspectFit;;
    rtcPlayView.frame = self.view.bounds;
    
//    CGFloat screenWidth = CGRectGetWidth(self.view.bounds);
//    CGFloat screenHeight = CGRectGetHeight(self.view.bounds);
//    
//    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    self.playBtn.frame = CGRectMake(50, screenHeight - 160, screenWidth - 2*50, 46);
//    self.playBtn.backgroundColor = [UIColor grayColor];
//    [self.playBtn setTitle:@"publish" forState:UIControlStateNormal];
//    [self.playBtn addTarget:self action:@selector(playBtnClick) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.playBtn];
//    
    
    [webRTCClient offer:^(RTCSessionDescription *sdp) {
        [webRTCClient changeSDP2Server:sdp urlStr:urlString  closure:^(BOOL isServerRetSuc) {
            NSLog(@"isServerRetSuc:%@",(isServerRetSuc?@"YES":@"NO"));
        }];
    }];
    
}

#pragma mark - WebRTCClientDelegate
- (void)webRTCClient:(WebRTCClient *)client didDiscoverLocalCandidate:(RTCIceCandidate *)candidate {
    NSLog(@"webRTCClient didDiscoverLocalCandidate");
}

- (void)webRTCClient:(WebRTCClient *)client didChangeConnectionState:(RTCIceConnectionState)state {
    NSLog(@"webRTCClient didChangeConnectionState");

    UIColor *textColor = [UIColor blackColor];
    BOOL openSpeak = NO;
    switch (state) {
        case RTCIceConnectionStateCompleted: //3
        case RTCIceConnectionStateConnected: //2
            textColor = [UIColor blueColor];
            openSpeak = YES;
            break;
            
        case RTCIceConnectionStateDisconnected: //5
            textColor = [UIColor yellowColor];
            break;
            
        case RTCIceConnectionStateFailed: //4
        case RTCIceConnectionStateClosed: //6
            textColor = [UIColor redColor];
            break;
            
        case RTCIceConnectionStateNew: //0
        case RTCIceConnectionStateChecking: //1
        case RTCIceConnectionStateCount: //7
            textColor = [UIColor greenColor];
            break;
            
        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = [NSString stringWithFormat:@"%ld", state];
        
        if (openSpeak) {
            [client speakOn];
        }
    });
}

- (void)webRTCClient:(WebRTCClient *)client didReceiveData:(NSData *)data {
    NSLog(@"webRTCClient didReceiveData");
}


@end
