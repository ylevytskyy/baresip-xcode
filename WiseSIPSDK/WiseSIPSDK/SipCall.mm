//
//  SipCall.m
//  WiseSIPSDK
//
//  Created by Yuriy Levytskyy on 3/2/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

#import "SipCall.h"
#import "SipCall+Private.h"

#define HAVE__BOOL

#import "re.h"
#import "baresip.h"

#include <unordered_map>

std::unordered_map<call*, SipCall*> sipCallsCache;

void call_event(struct call *call, enum call_event ev, const char *str, void *arg) {
    SipCall* sipCall = (__bridge SipCall*)(arg);
    
    switch (ev) {
        case CALL_EVENT_INCOMING: {
            NSLog(@"CALL_EVENT_INCOMING");
        }
            break;
            
        case CALL_EVENT_RINGING: {
            NSLog(@"CALL_EVENT_RINGING");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnRinging:)]) {
                    [sipCall.delegate OnRinging:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_PROGRESS: {
            NSLog(@"CALL_EVENT_PROGRESS");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnProgress:)]) {
                    [sipCall.delegate OnProgress:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_ESTABLISHED: {
            NSLog(@"CALL_EVENT_ESTABLISHED");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnEstablished:)]) {
                    [sipCall.delegate OnEstablished:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_CLOSED: {
            NSLog(@"CALL_EVENT_CLOSED");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnClosed:)]) {
                    [sipCall.delegate OnClosed:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_TRANSFER: {
            NSLog(@"CALL_EVENT_TRANSFER");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnTransfer:)]) {
                    [sipCall.delegate OnTransfer:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_TRANSFER_FAILED: {
            NSLog(@"CALL_EVENT_TRANSFER_FAILED");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnFailedTransfer:)]) {
                    [sipCall.delegate OnFailedTransfer:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_MENC: {
            NSLog(@"CALL_EVENT_MENC");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnMediaEncryption:)]) {
                    [sipCall.delegate OnMediaEncryption:sipCall];
                }
            });
        }
            break;
    }
}

void call_dtmf(struct call *call, char key, void *arg) {
    NSLog(@"DTMF %@ %c", @(call_peeruri(call)), key);
}

@implementation SipCall
- (instancetype)init {
    self = [super init];
    return self;
}

- (void)deinit {
    sipCallsCache.erase(self.call);
}

- (NSString*)peerUri {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return @"";
    }
    
    return @(call_peeruri(self.call));
}

- (NSString*)peerName {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return @"";
    }
    
    return @(call_peername(self.call));
}

- (unsigned)duration {
    return call_duration(self.call);
}

- (unsigned short)statusCode {
    return call_scode(self.call);
}

- (bool)hasAudio {
    return call_has_audio(self.call);
}

- (bool)hasVideo {
    return call_has_video(self.call);
}

- (void)answer {
    ua_answer(call_get_ua(self.call), self.call);
}

- (void)hangup:(unsigned short)statusCode reason:(NSString*)reason {
    ua_hangup(call_get_ua(self.call), self.call, statusCode, [reason cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)holdAnswer {
    ua_hold_answer(call_get_ua(self.call), self.call);
}

- (int)hold:(bool)hold {
    int error = call_hold(self.call, hold);
    if (error != 0) {
        return error;
    }
    return error;
}

- (int)sendDigit:(char)key {
    int error = call_send_digit(self.call, key);
    if (error != 0) {
        return error;
    }
    return error;
}

/*
 int  call_modify(struct call *call);
 int  call_transfer(struct call *call, const char *uri);
 
 uint32_t      call_setup_duration(const struct call *call);
 const char   *call_id(const struct call *call);
 const char   *call_localuri(const struct call *call);
 struct audio *call_audio(const struct call *call);
 struct video *call_video(const struct call *call);
 struct list  *call_streaml(const struct call *call);
 struct ua    *call_get_ua(const struct call *call);
 bool          call_is_onhold(const struct call *call);
 bool          call_is_outgoing(const struct call *call);
 */
@end
