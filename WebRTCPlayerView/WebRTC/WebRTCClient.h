//
//  WebRTCClient.h
//  WebRTCPlayerView
//
//  Created by Nacho's MBP on 2025/7/8.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WebRTCClientDelegate;
@interface WebRTCClient : NSObject<RTCPeerConnectionDelegate>

@property (nonatomic, weak) id<WebRTCClientDelegate> delegate;

/**
 connect工厂
 */
@property (nonatomic, strong) RTCPeerConnectionFactory *factory;
/**
 connect
 */
@property (nonatomic, strong) RTCPeerConnection *peerConnection;

/**
 RTCAudioSession
 */
@property (nonatomic, strong) RTCAudioSession *rtcAudioSession;

/**
 DispatchQueue
 */
@property (nonatomic) dispatch_queue_t audioQueue;

/**
 mediaConstrains
 */
@property (nonatomic, strong) NSDictionary *mediaConstrains;

/**
 publishMediaConstrains
 */
@property (nonatomic, strong) NSDictionary *publishMediaConstrains;

/**
 playMediaConstrains
 */
@property (nonatomic, strong) NSDictionary *playMediaConstrains;
/**
 optionalConstraints
 */
@property (nonatomic, strong) NSDictionary *optionalConstraints;

/**
 remoteVideoTrack
 */
@property (nonatomic, strong) RTCVideoTrack *remoteVideoTrack;

/**
 RTCVideoRenderer
 */
@property (nonatomic, weak) id<RTCVideoRenderer> remoteRenderView;

/**
 localDataChannel
 */
@property (nonatomic, strong) RTCDataChannel *localDataChannel;

/**
 localDataChannel
 */
@property (nonatomic, strong) RTCDataChannel *remoteDataChannel;

- (instancetype)initWithPublish;

- (void)answer:(void (^)(RTCSessionDescription *sdp))completionHandler;

- (void)offer:(void (^)(RTCSessionDescription *sdp))completionHandler;

#pragma mark - Hiden or show Video
- (void)hidenVideo;

- (void)showVideo;

#pragma mark - Hiden or show Audio
- (void)muteAudio;

- (void)unmuteAudio;

- (void)speakOff;

- (void)speakOn;

- (void)changeSDP2Server:(RTCSessionDescription *)sdp
                  urlStr:(NSString *)urlStr
                 closure:(void (^)(BOOL isServerRetSuc))closure;

@end


@protocol WebRTCClientDelegate <NSObject>

- (void)webRTCClient:(WebRTCClient *)client didDiscoverLocalCandidate:(RTCIceCandidate *)candidate;
- (void)webRTCClient:(WebRTCClient *)client didChangeConnectionState:(RTCIceConnectionState)state;
- (void)webRTCClient:(WebRTCClient *)client didReceiveData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
