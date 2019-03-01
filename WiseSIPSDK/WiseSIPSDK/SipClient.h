//
//  SipClient.h
//  TareSIPDemo
//
//  Created by Yuriy Levytskyy on 2/27/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SipCall;
@class SipClient;

/// SIP Events
@protocol SipClientDelegate<NSObject>
@optional
- (void)onWillRegister:(SipClient*)sipSdk;
- (void)onDidRegister:(SipClient*)sipSdk;
- (void)onFailedRegister:(SipClient*)sipSdk;
- (void)onWillUnRegister:(SipClient*)sipSdk;

- (void)onCallIncoming:(SipCall*)sipCall;
- (void)onCallRinging:(SipCall*)sipCall;
- (void)onCallProcess:(SipCall*)sipCall;
- (void)onCallEstablished:(SipCall*)sipCall;
- (void)onCallClosed:(SipCall*)sipCall;
- (void)onCallTransferFailed:(SipCall*)sipCall;
- (void)onCallDtmfStart:(SipCall*)sipCall;
- (void)onCallDtmfEnd:(SipCall*)sipCall;
@end

/// SIP Client
@interface SipClient : NSObject
@property (readonly, nonatomic, nonnull) NSString* username;
@property (readonly, nonatomic, nonnull) NSString* domain;
@property (nonatomic) NSString* password;
@property (nonatomic) int port;

@property (readonly, nonatomic) NSString* aor;

@property (nonatomic) id<SipClientDelegate> delegate;

- (instancetype)initWithUsername:(NSString*)username domain:(NSString*)domain;

- (int)start;
- (void)stop;

- (int)registry;
- (void)unregister;
- (bool)isRegistered;

- (SipCall*)makeCall:(NSString*)uri;
@end

/// SIP Call
@interface SipCall : NSObject
@property (nonatomic, readonly) NSString* peerUri;

- (void)answer;
- (void)hangup:(unsigned short)statusCode reason:(NSString*)reason;
- (void)holdAnswer;
@end

NS_ASSUME_NONNULL_END
