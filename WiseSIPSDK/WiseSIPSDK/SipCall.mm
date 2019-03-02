//
//  SipCall.m
//  WiseSIPSDK
//
//  Created by Yuriy Levytskyy on 3/2/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

#import "SipCall.h"
#import "SipCall+Private.h"

std::unordered_map<call*, SipCall*> sipCallsCache;

void call_event(struct call *call, enum call_event ev, const char *str, void *arg) {
    SipCall* sipCall = (__bridge SipCall*)(arg);
    
    switch (ev) {
        case CALL_EVENT_INCOMING: {
            debug("CALL_EVENT_INCOMING");
        }
            break;
            
        case CALL_EVENT_RINGING: {
            debug("CALL_EVENT_RINGING");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnRinging:)]) {
                    [sipCall.delegate OnRinging:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_PROGRESS: {
            debug("CALL_EVENT_PROGRESS");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnProgress:)]) {
                    [sipCall.delegate OnProgress:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_ESTABLISHED: {
            debug("CALL_EVENT_ESTABLISHED");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnEstablished:)]) {
                    [sipCall.delegate OnEstablished:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_CLOSED: {
            debug("CALL_EVENT_CLOSED");
            clearCall(call);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnClosed:)]) {
                    [sipCall.delegate OnClosed:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_TRANSFER: {
            debug("CALL_EVENT_TRANSFER");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnTransfer:)]) {
                    [sipCall.delegate OnTransfer:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_TRANSFER_FAILED: {
            debug("CALL_EVENT_TRANSFER_FAILED");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipCall.delegate respondsToSelector:@selector(OnFailedTransfer:)]) {
                    [sipCall.delegate OnFailedTransfer:sipCall];
                }
            });
        }
            break;
            
        case CALL_EVENT_MENC: {
            debug("CALL_EVENT_MENC");
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
    debug("DTMF %@ %c", @(call_peeruri(call)), key);
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
    const char *string = call_peeruri(self.call);
    if (!string) {
        return @"";
    }
    return @(string);
}

- (NSString*)localUri {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return @"";
    }
    const char *string = call_localuri(self.call);
    if (!string) {
        return @"";
    }
    return @(string);
}

- (NSString*)peerName {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return @"";
    }
    const char *string = call_peername(self.call);
    if (!string) {
        return @"";
    }
    return @(string);
}

- (NSString*)callId {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return @"";
    }
    
    const char *string = call_id(self.call);
    if (!string) {
        return @"";
    }
    return @(string);
}

- (unsigned)duration {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return 0;
    }

    return call_duration(self.call);
}

- (unsigned short)statusCode {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return 0;
    }

    return call_scode(self.call);
}

- (bool)hasAudio {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return false;
    }

    return call_has_audio(self.call);
}

- (bool)hasVideo {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return false;
    }

    return call_has_video(self.call);
}

- (void)answer {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return;
    }

    ua_answer(call_get_ua(self.call), self.call);
}

- (void)hangup:(unsigned short)statusCode reason:(NSString*)reason {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return;
    }

    ua_hangup(call_get_ua(self.call), self.call, statusCode, [reason cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)holdAnswer {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return;
    }

    ua_hold_answer(call_get_ua(self.call), self.call);
}

- (int)hold:(bool)hold {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return -1;
    }

    int error = call_hold(self.call, hold);
    if (error != 0) {
        return error;
    }
    return error;
}

- (int)transfer:(NSString*)uri {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return -1;
    }
    
    int error = call_transfer(self.call, [uri cStringUsingEncoding:NSUTF8StringEncoding]);
    if (error != 0) {
        return error;
    }
    return error;
}

- (int)sendDigit:(char)key {
    auto sipCallCache = sipCallsCache.find(self.call);
    if (sipCallCache == sipCallsCache.end()) {
        return -1;
    }

    int error = call_send_digit(self.call, key);
    if (error != 0) {
        return error;
    }
    return error;
}

/*
 int  call_modify(struct call *call);
 
 uint32_t      call_setup_duration(const struct call *call);
 const char   *call_localuri(const struct call *call);
 struct audio *call_audio(const struct call *call);
 struct video *call_video(const struct call *call);
 struct list  *call_streaml(const struct call *call);
 struct ua    *call_get_ua(const struct call *call);
 bool          call_is_onhold(const struct call *call);
 bool          call_is_outgoing(const struct call *call);
 */
@end
