//
//  HttpClient.m
//  WebRTCPlayerView
//
//  Created by Nacho's MBP on 2025/7/8.
//

#import "HttpClient.h"

@interface HttpClient ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation HttpClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (void)changeSDP2Server:(RTCSessionDescription *)sdp
                  urlStr:(NSString *)urlStr
                 closure:(void (^)(RTCSessionDescription *result))closure {
    
    NSURL *urlString = [NSURL URLWithString:urlStr];
    
    //创建可变请求对象
    NSMutableURLRequest* mutableRequest = [[NSMutableURLRequest alloc] initWithURL:urlString];
    [mutableRequest setHTTPMethod:@"POST"];
    [mutableRequest addValue:@"application/sdp" forHTTPHeaderField:@"Content-Type"];
    mutableRequest.HTTPBody = [sdp.sdp dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:mutableRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            NSString *sdpAnswer = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            RTCSessionDescription *answer = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:sdpAnswer];
            if (closure) {
                closure(answer);
            }
        } else {
            NSLog(@"网络请求失败！");
        }
    }];
    
    //启动任务
    [dataTask resume];
}

- (NSString *)createTid {
    NSDate *date = [[NSDate alloc] init];
    int timeInterval = (int)([date timeIntervalSince1970]);
    int random = (int)(arc4random());
    NSString *str = [NSString stringWithFormat:@"%d*%d", timeInterval, random];
    if (str.length > 7) {
        NSString *tid = [str substringToIndex:7];
        return tid;
    }
    return @"";
}

#pragma mark -session delegate
-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

@end
