//
//  SipClient.m
//  TareSIPDemo
//
//  Created by Yuriy Levytskyy on 2/27/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

#import "SipClient.h"
#import "SipCall.h"
#import "SipCall+Private.h"

#define HAVE__BOOL

#import "re.h"
#import "baresip.h"

#include <unordered_map>

extern std::unordered_map<call*, SipCall*> sipCallsCache;

void call_event(struct call *call, enum call_event ev, const char *str, void *arg);
void call_dtmf(struct call *call, char key, void *arg);

static const int kDefaultPort = 5060;

static void signal_handler(int sig)
{
    static bool term = false;
    
    if (term) {
        mod_close();
        exit(0);
    }
    
    term = true;
    
    info("terminated by signal %d\n", sig);
    
    ua_stop_all(false);
}

static void ua_exit_handler(void *arg)
{
    (void)arg;
    debug("ua exited -- stopping main runloop\n");
    
    /* The main run-loop can be stopped now */
    re_cancel();
}

@interface SipClient()
@property (nonatomic) struct ua *ua;
@end

static SipCall* getSipCall(struct call *call, SipClient* sipSdk, NSString* remoteUri) {
    SipCall* sipCall;
    if (call != NULL) {
        auto sipCallCache = sipCallsCache.find(call);
        if (sipCallCache != sipCallsCache.end()) {
            NSLog(@"Existing call found %@", @(call_peeruri(call)));
            
            sipCall = sipCallCache->second;
        }
    }
    
    return sipCall;
}

static void ua_event_handler(struct ua *ua, enum ua_event ev,
    struct call *call, const char *prm, void *arg)
{
    NSLog(@"ua_event_handler ev = \"%@\" prm = \"%@\" call = \"%@\"", @(ev), @(prm), call != nil ? @(call_peeruri(call)) : @"NO CALL");
    
    SipClient* sipSdk = (__bridge SipClient*)(arg);
    
    switch (ev) {
        case UA_EVENT_REGISTERING: {
            NSLog(@"UA_EVENT_REGISTERING");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onRegistering:)]) {
                    [sipSdk.delegate onRegistering:sipSdk];
                }
            });
        }
            break;
            
        case UA_EVENT_REGISTER_OK: {
            NSLog(@"UA_EVENT_REGISTER_OK");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onRegistered:)]) {
                    [sipSdk.delegate onRegistered:sipSdk];
                }
            });
        }
            break;

        case UA_EVENT_REGISTER_FAIL: {
            NSLog(@"UA_EVENT_REGISTER_FAIL");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onFailedRegister:)]) {
                    [sipSdk.delegate onFailedRegister:sipSdk];
                }
            });
        }
            break;

        case UA_EVENT_UNREGISTERING: {
            NSLog(@"UA_EVENT_UNREGISTERING");
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onUnRegistering:)]) {
                    [sipSdk.delegate onUnRegistering:sipSdk];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_INCOMING: {
            NSLog(@"UA_EVENT_CALL_INCOMING");

            SipCall* sipCall = [[SipCall alloc] init];
            sipCall.call = call;
            sipCallsCache[call] = sipCall;

            call_set_handlers(call, &call_event, &call_dtmf, (__bridge void*)(sipCall));

            NSLog(@"New incoming call created %@", @(call_peeruri(call)));

            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallIncoming:)]) {
                    [sipSdk.delegate onCallIncoming:sipCall];
                }
            });
        }
            break;

        case UA_EVENT_CALL_RINGING: {
            NSLog(@"UA_EVENT_CALL_RINGING");
            SipCall* sipCall = getSipCall(call, sipSdk, @(prm));
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallRinging:)]) {
                    [sipSdk.delegate onCallRinging:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_PROGRESS: {
            NSLog(@"UA_EVENT_CALL_PROGRESS");
            SipCall* sipCall = getSipCall(call, sipSdk, @(prm));
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallProcess:)]) {
                    [sipSdk.delegate onCallProcess:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_ESTABLISHED: {
            NSLog(@"UA_EVENT_CALL_ESTABLISHED");
            SipCall* sipCall = getSipCall(call, sipSdk, @(prm));
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallEstablished:)]) {
                    [sipSdk.delegate onCallEstablished:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_CLOSED: {
            NSLog(@"UA_EVENT_CALL_CLOSED");
            SipCall* sipCall = getSipCall(call, sipSdk, @(prm));
            sipCallsCache.erase(call);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallClosed:)]) {
                    [sipSdk.delegate onCallClosed:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_TRANSFER_FAILED: {
            NSLog(@"UA_EVENT_CALL_TRANSFER_FAILED");
            SipCall* sipCall = getSipCall(call, sipSdk, @(prm));
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallTransferFailed:)]) {
                    [sipSdk.delegate onCallTransferFailed:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_DTMF_START: {
            NSLog(@"UA_EVENT_CALL_DTMF_START");
            SipCall* sipCall = getSipCall(call, sipSdk, @(prm));
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallDtmfStart:)]) {
                    [sipSdk.delegate onCallDtmfStart:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_DTMF_END: {
            NSLog(@"UA_EVENT_CALL_DTMF_END");
            SipCall* sipCall = getSipCall(call, sipSdk, @(prm));
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallDtmfEnd:)]) {
                    [sipSdk.delegate onCallDtmfEnd:sipCall];
                }
            });
        }
            break;
    }
}

@implementation SipClient

- (NSString*)aor {
    return @(ua_aor(self.ua));
}

- (instancetype)initWithUsername:(NSString*)username domain:(NSString*)domain {
    self = [super init];
    if (self) {
        _username = username;
        _domain = domain;
        
        _port = kDefaultPort;
    }
    return self;
}

- (int)start {
    int error = libre_init();
    if (error != 0) {
        return error;
    }
    
    // Initialize dynamic modules.
    mod_init();
    
    NSString *path = [[[NSBundle mainBundle] pathForResource:@"config" ofType:@""] stringByDeletingLastPathComponent];
    conf_path_set([path cStringUsingEncoding:NSUTF8StringEncoding]);
    
    error = conf_configure();
    if (error != 0) {
        return error;
    }
    
    bool prefer_ipv6 = false;

    error = baresip_init(conf_config(), prefer_ipv6);
    if (error != 0) {
        return error;
    }

    // Initialize the SIP stack.
    error = ua_init("SIP", true, true, true, prefer_ipv6);
    if (error != 0) {
        return error;
    }
    
    uag_set_exit_handler(ua_exit_handler, (__bridge void *)(self));

    // Register UA event handler
    error = uag_event_register(ua_event_handler, (__bridge void *)(self));
    if (error != 0) {
        return error;
    }
    
    error = conf_modules();
    if (error != 0) {
        return error;
    }
    
    NSString* aor;
    if (self.password) {
        aor = [NSString stringWithFormat:@"sip:%@@%@:%@;auth_pass=%@", self.username, self.domain, @(self.port), self.password];
    } else {
        aor = [NSString stringWithFormat:@"sip:%@@%@:%@", self.username, self.domain, @(self.port)];
    }
    
    // Start user agent.
    error = ua_alloc(&_ua, [aor cStringUsingEncoding:NSUTF8StringEncoding]);
    if (error != 0) {
        return error;
    }
    
    // Start the main loop.
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(_run) object:nil];
    [thread start];
    
    return 0;
}

- (void)stop {
    if (!self.ua) {
        return;
    }
    
    ua_stop_all(false);
    
    mem_deref(self.ua);
    self.ua = nil;
    
    ua_close();
    conf_close();
    
    baresip_close();

    uag_event_unregister(ua_event_handler);
    
    mod_close();
    
    // Close
    libre_close();
    
    // Check for memory leaks.
    tmr_debug();
    mem_debug();
}

- (int)registry {
    int error = ua_register(self.ua);
    if (error != 0) {
        return error;
    }
    return 0;
}

- (void)unregister {
    ua_unregister(self.ua);
}

- (bool)isRegistered {
    return ua_isregistered(self.ua);
}

- (SipCall*)makeCall:(NSString*)uri {
    SipCall* sipCall = [[SipCall alloc] init];

    struct call *call;
    int error = ua_connect(self.ua, &call, nil, [uri cStringUsingEncoding:NSUTF8StringEncoding], VIDMODE_ON);
    if (error != 0) {
        return nil;
    } else {
        sipCall.call = call;
        sipCallsCache[call] = sipCall;

        call_set_handlers(call, &call_event, &call_dtmf, (__bridge void*)(sipCall));
        
        NSLog(@"New outgoing call created %@", @(call_peeruri(call)));
    }

    return sipCall;
}

-(void)_run {
    // Start the main loop.
    re_main(signal_handler);
}

@end
