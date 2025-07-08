//
//  WebRTCClient.m
//  WebRTCPlayerView
//
//  Created by Nacho's MBP on 2025/7/8.
//

#import "WebRTCClient.h"
#import "HttpClient.h"

@interface WebRTCClient ()<RTCPeerConnectionDelegate, RTCDataChannelDelegate>

@property (nonatomic, strong) HttpClient *httpClient;

@end

@implementation WebRTCClient

- (instancetype)initWithPublish{
    self = [super init];
    if (self) {
        
        self.httpClient = [[HttpClient alloc] init];
        
        RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:self.optionalConstraints];
        RTCConfiguration *newConfig = [[RTCConfiguration alloc] init];
        newConfig.sdpSemantics = RTCSdpSemanticsUnifiedPlan;
        
        self.peerConnection = [self.factory peerConnectionWithConfiguration:newConfig constraints:constraints delegate:self];
        [self configureAudioSession];
    }
    return self;
}


- (void)configureAudioSession {
    [self.rtcAudioSession lockForConfiguration];
    @try {
        NSError *error;
        [self.rtcAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
        
        NSError *modeError;
        [self.rtcAudioSession setMode:AVAudioSessionModeDefault error:&modeError];
        NSLog(@"configureAudioSession error:%@, modeError:%@", error, modeError);
    } @catch (NSException *exception) {
        NSLog(@"configureAudioSession exception:%@", exception);
    }
    
    [self.rtcAudioSession unlockForConfiguration];
}

- (RTCAudioTrack *)createAudioTrack {
    /// enable google 3A algorithm.
    NSDictionary *mandatory = @{
        @"googEchoCancellation": kRTCMediaConstraintsValueTrue,
        @"googAutoGainControl": kRTCMediaConstraintsValueTrue,
        @"googNoiseSuppression": kRTCMediaConstraintsValueTrue,
    };
    
    RTCMediaConstraints *audioConstrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatory optionalConstraints:self.optionalConstraints];
    RTCAudioSource *audioSource = [self.factory audioSourceWithConstraints:audioConstrains];
    
    RTCAudioTrack *audioTrack = [self.factory audioTrackWithSource:audioSource trackId:@"audio0"];
    
    return audioTrack;
}

- (void)offer:(void (^)(RTCSessionDescription *sdp))completion {
    self.mediaConstrains = self.playMediaConstrains;
    
    RTCMediaConstraints *constrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:self.mediaConstrains optionalConstraints:self.optionalConstraints];
    NSLog(@"peerConnection:%@",self.peerConnection);
    __weak typeof(self) weakSelf = self;
    [weakSelf.peerConnection offerForConstraints:constrains completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            NSLog(@"offer offerForConstraints error:%@", error);
        }
        
        if (sdp) {
            [weakSelf.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"offer setLocalDescription error:%@", error);
                }
                if (completion) {
                    completion(sdp);
                }
            }];
        }
    }];
}

- (void)answer:(void (^)(RTCSessionDescription *sdp))completion {
    RTCMediaConstraints *constrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:self.mediaConstrains optionalConstraints:self.optionalConstraints];
    __weak typeof(self) weakSelf = self;
    [weakSelf.peerConnection answerForConstraints:constrains completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            NSLog(@"answer answerForConstraints error:%@", error);
        }
        
        if (sdp) {
            [weakSelf.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"answer setLocalDescription error:%@", error);
                }
                if (completion) {
                    completion(sdp);
                }
            }];
        }
    }];
}

- (void)setRemoteSdp:(RTCSessionDescription *)remoteSdp completion:(void (^)(NSError * _Nullable error))completion {
    [self.peerConnection setRemoteDescription:remoteSdp completionHandler:completion];
}

- (void)setRemoteCandidate:(RTCIceCandidate *)remoteCandidate {
    [self.peerConnection addIceCandidate:remoteCandidate];
}

- (void)setMaxBitrate:(int)maxBitrate {
    NSMutableArray *videoSenders = [NSMutableArray arrayWithCapacity:0];
    for (RTCRtpSender *sender in self.peerConnection.senders) {
        if (sender.track && [kRTCMediaStreamTrackKindVideo isEqualToString:sender.track.kind]) {
            [videoSenders addObject:sender];
        }
    }
    
    if (videoSenders.count > 0) {
        RTCRtpSender *firstSender = [videoSenders firstObject];
        RTCRtpParameters *parameters = firstSender.parameters;
        NSNumber *maxBitrateBps = [NSNumber numberWithInt:maxBitrate];
        parameters.encodings.firstObject.maxBitrateBps = maxBitrateBps;
    }
}

- (void)setMaxFramerate:(int)maxFramerate {
    NSMutableArray *videoSenders = [NSMutableArray arrayWithCapacity:0];
    for (RTCRtpSender *sender in self.peerConnection.senders) {
        if (sender.track && [kRTCMediaStreamTrackKindVideo isEqualToString:sender.track.kind]) {
            [videoSenders addObject:sender];
        }
    }
    
    if (videoSenders.count > 0) {
        RTCRtpSender *firstSender = [videoSenders firstObject];
        RTCRtpParameters *parameters = firstSender.parameters;
        NSNumber *maxFramerateNum = [NSNumber numberWithInt:maxFramerate];
        
        // 该版本暂时没有maxFramerate，需要更新到最新版本
        parameters.encodings.firstObject.maxFramerate = maxFramerateNum;
    }
}

- (RTCDataChannel *)createDataChannel {
    RTCDataChannelConfiguration *config = [[RTCDataChannelConfiguration alloc] init];
    RTCDataChannel *dataChannel = [self.peerConnection dataChannelForLabel:@"WebRTCData" configuration:config];
    if (!dataChannel) {
        return nil;
    }
    
    dataChannel.delegate = self;
    self.localDataChannel = dataChannel;
    return dataChannel;
}

- (void)sendData:(NSData *)data {
    RTCDataBuffer *buffer = [[RTCDataBuffer alloc] initWithData:data isBinary:YES];
    [self.remoteDataChannel sendData:buffer];
}

- (void)changeSDP2Server:(RTCSessionDescription *)sdp
                  urlStr:(NSString *)urlStr
                 closure:(void (^)(BOOL isServerRetSuc))closure {
    
    __weak typeof(self) weakSelf = self;
    [self.httpClient changeSDP2Server:sdp urlStr:urlStr closure:^(RTCSessionDescription *result) {
        [weakSelf setRemoteSdp:result completion:^(NSError * _Nullable error) {
            NSLog(@"changeSDP2Server setRemoteDescription error:%@", error);
        }];
    }];
}

#pragma mark - Hiden or show Video
- (void)hidenVideo {
    [self setVideoEnabled:NO];
}

- (void)showVideo {
    [self setVideoEnabled:YES];
}

- (void)setVideoEnabled:(BOOL)isEnabled {
    [self setTrackEnabled:[RTCVideoTrack class] isEnabled:isEnabled];
}

- (void)setTrackEnabled:(Class)track isEnabled:(BOOL)isEnabled {
    for (RTCRtpTransceiver *transceiver in self.peerConnection.transceivers) {
        if (transceiver && [transceiver isKindOfClass:track]) {
            transceiver.sender.track.isEnabled = isEnabled;
        }
    }
}
#pragma mark - Hiden or show Audio
- (void)muteAudio {
    [self setAudioEnabled:NO];
}

- (void)unmuteAudio {
    [self setAudioEnabled:YES];
}

- (void)speakOff {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.audioQueue, ^{
        [weakSelf.rtcAudioSession lockForConfiguration];
        @try {
            
            NSError *error;
            [self.rtcAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
            
            NSError *ooapError;
            [self.rtcAudioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&ooapError];
            NSLog(@"speakOff error:%@, ooapError:%@", error, ooapError);
        } @catch (NSException *exception) {
            NSLog(@"speakOff exception:%@", exception);
        }
        [weakSelf.rtcAudioSession unlockForConfiguration];
    });
}

- (void)speakOn {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.audioQueue, ^{
        [weakSelf.rtcAudioSession lockForConfiguration];
        @try {
            
            NSError *error;
            [self.rtcAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
            
            NSError *ooapError;
            [self.rtcAudioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&ooapError];
            
            NSError *activeError;
            [self.rtcAudioSession setActive:YES error:&activeError];
            
            NSLog(@"speakOn error:%@, ooapError:%@, activeError:%@", error, ooapError, activeError);
        } @catch (NSException *exception) {
            NSLog(@"speakOn exception:%@", exception);
        }
        [weakSelf.rtcAudioSession unlockForConfiguration];
    });
}

- (void)setAudioEnabled:(BOOL)isEnabled {
    [self setTrackEnabled:[RTCAudioTrack class] isEnabled:isEnabled];
}


#pragma mark - RTCPeerConnectionDelegate
/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged {
    NSLog(@"peerConnection didChangeSignalingState:%ld", (long)stateChanged);
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream {
    NSLog(@"peerConnection didAddStream");
    
    
    NSArray *videoTracks = stream.videoTracks;
    if (videoTracks && videoTracks.count > 0) {
        RTCVideoTrack *track = videoTracks.firstObject;
        self.remoteVideoTrack = track;
    }
    
    if (self.remoteVideoTrack && self.remoteRenderView) {
        id<RTCVideoRenderer> remoteRenderView = self.remoteRenderView;
        RTCVideoTrack *remoteVideoTrack = self.remoteVideoTrack;
        [remoteVideoTrack addRenderer:remoteRenderView];
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream {
    NSLog(@"peerConnection didRemoveStream");
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
    NSLog(@"peerConnection peerConnectionShouldNegotiate");
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"peerConnection didChangeIceConnectionState:%ld", newState);
    if (self.delegate && [self.delegate respondsToSelector:@selector(webRTCClient:didChangeConnectionState:)]) {
        [self.delegate webRTCClient:self didChangeConnectionState:newState];
    }
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState {
    NSLog(@"peerConnection didChangeIceGatheringState:%ld", newState);
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    NSLog(@"peerConnection didGenerateIceCandidate:%@", candidate);
    if (self.delegate && [self.delegate respondsToSelector:@selector(webRTCClient:didDiscoverLocalCandidate:)]) {
        [self.delegate webRTCClient:self didDiscoverLocalCandidate:candidate];
    }
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"peerConnection didRemoveIceCandidates:%@", candidates);
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel {
    NSLog(@"peerConnection didOpenDataChannel:%@", dataChannel);
    self.remoteDataChannel = dataChannel;
}

/** Called when signaling indicates a transceiver will be receiving media from
 *  the remote endpoint.
 *  This is only called with RTCSdpSemanticsUnifiedPlan specified.
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didStartReceivingOnTransceiver:(RTCRtpTransceiver *)transceiver {
    NSLog(@"peerConnection didStartReceivingOnTransceiver:%@", transceiver);
}

/** Called when a receiver and its track are created. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
        didAddReceiver:(RTCRtpReceiver *)rtpReceiver
               streams:(NSArray<RTCMediaStream *> *)mediaStreams {
    NSLog(@"peerConnection didAddReceiver");
}

/** Called when the receiver and its track are removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
     didRemoveReceiver:(RTCRtpReceiver *)rtpReceiver {
    NSLog(@"peerConnection didRemoveReceiver");
}

#pragma mark - RTCDataChannelDelegate
/** The data channel state changed. */
- (void)dataChannelDidChangeState:(RTCDataChannel *)dataChannel {
    NSLog(@"dataChannelDidChangeState:%@", dataChannel);
}

/** The data channel successfully received a data buffer. */
- (void)dataChannel:(RTCDataChannel *)dataChannel
didReceiveMessageWithBuffer:(RTCDataBuffer *)buffer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webRTCClient:didReceiveData:)]) {
        [self.delegate webRTCClient:self didReceiveData:buffer.data];
    }
}


#pragma mark - Lazy
- (RTCPeerConnectionFactory *)factory {
    if (!_factory) {
        RTCInitializeSSL();
        RTCDefaultVideoEncoderFactory *videoEncoderFactory = [[RTCDefaultVideoEncoderFactory alloc] init];
        
        RTCDefaultVideoDecoderFactory *videoDecoderFactory = [[RTCDefaultVideoDecoderFactory alloc] init];
        
        for (RTCVideoCodecInfo *codec in videoEncoderFactory.supportedCodecs) {
            if (codec.parameters) {
                NSString *profile_level_id = codec.parameters[@"profile-level-id"];
                if (profile_level_id && [profile_level_id isEqualToString:@"42e01f"]) {
                    videoEncoderFactory.preferredCodec = codec;
                    break;
                }
            }
        }
        _factory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:videoEncoderFactory decoderFactory:videoDecoderFactory];
    }
    return _factory;
}

- (dispatch_queue_t)audioQueue {
    if (!_audioQueue) {
        _audioQueue = dispatch_queue_create("cn.ifour.webrtc", NULL);
    }
    return _audioQueue;
}

- (RTCAudioSession *)rtcAudioSession {
    if (!_rtcAudioSession) {
        _rtcAudioSession = [RTCAudioSession sharedInstance];
    }
    
    return _rtcAudioSession;
}

- (NSDictionary *)mediaConstrains {
    if (!_mediaConstrains) {
        _mediaConstrains = [[NSDictionary alloc] initWithObjectsAndKeys:
                            kRTCMediaConstraintsValueFalse, kRTCMediaConstraintsOfferToReceiveAudio,
                            kRTCMediaConstraintsValueFalse, kRTCMediaConstraintsOfferToReceiveVideo,
                            kRTCMediaConstraintsValueTrue, @"IceRestart",
                            nil];
    }
    return _mediaConstrains;
}

- (NSDictionary *)publishMediaConstrains {
    if (!_publishMediaConstrains) {
        _publishMediaConstrains = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   kRTCMediaConstraintsValueFalse, kRTCMediaConstraintsOfferToReceiveAudio,
                                   kRTCMediaConstraintsValueFalse, kRTCMediaConstraintsOfferToReceiveVideo,
                                   kRTCMediaConstraintsValueTrue, @"IceRestart",
                                   nil];
    }
    return _publishMediaConstrains;
}

- (NSDictionary *)playMediaConstrains {
    if (!_playMediaConstrains) {
        _playMediaConstrains = [[NSDictionary alloc] initWithObjectsAndKeys:
                                kRTCMediaConstraintsValueTrue, kRTCMediaConstraintsOfferToReceiveAudio,
                                kRTCMediaConstraintsValueTrue, kRTCMediaConstraintsOfferToReceiveVideo,
                                kRTCMediaConstraintsValueTrue, @"IceRestart",
                                nil];
    }
    return _playMediaConstrains;
}

- (NSDictionary *)optionalConstraints {
    if (!_optionalConstraints) {
        _optionalConstraints = [[NSDictionary alloc] initWithObjectsAndKeys:
                                kRTCMediaConstraintsValueTrue, @"DtlsSrtpKeyAgreement",
                                nil];
    }
    return _optionalConstraints;
}

@end
