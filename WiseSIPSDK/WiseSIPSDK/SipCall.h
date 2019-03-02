//
//  SipCall.h
//  WiseSIPSDK
//
//  Created by Yuriy Levytskyy on 3/2/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SipCall;

/// SIP Call Events
@protocol SipCallDelegate<NSObject>
@optional
- (void)OnRinging:(SipCall*)sipCall;
- (void)OnProgress:(SipCall*)sipCall;
- (void)OnEstablished:(SipCall*)sipCall;
- (void)OnClosed:(SipCall*)sipCall;
- (void)OnTransfer:(SipCall*)sipCall;
- (void)OnFailedTransfer:(SipCall*)sipCall;
- (void)OnMediaEncryption:(SipCall*)sipCall;
@end

/// SIP Call
@interface SipCall : NSObject
@property (nonatomic, readonly) NSString* peerUri;
@property (nonatomic, readonly) NSString* localUri;
@property (nonatomic, readonly) NSString* peerName;
@property (nonatomic, readonly) NSString* callId;
@property (nonatomic, readonly) unsigned duration;
@property (nonatomic, readonly) unsigned short statusCode;
@property (nonatomic, readonly) bool hasAudio;
@property (nonatomic, readonly) bool hasVideo;

@property (weak, nonatomic) id<SipCallDelegate> delegate;

- (void)answer;
- (void)hangup:(unsigned short)statusCode reason:(NSString*)reason;
- (void)holdAnswer;
- (int)hold:(bool)hold;
- (int)sendDigit:(char)key;
- (int)transfer:(NSString*)uri;
@end

NS_ASSUME_NONNULL_END
