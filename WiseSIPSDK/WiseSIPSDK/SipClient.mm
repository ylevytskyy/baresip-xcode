//
//  SipClient.m
//  TareSIPDemo
//
//  Created by Yuriy Levytskyy on 2/27/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

#import "SipClient.h"

#define HAVE__BOOL

#import "re.h"
#import "baresip.h"

#include <unordered_map>

/*
static struct tag_baresip {
    struct network *net;
    struct contacts *contacts;
    struct commands *commands;
    struct player *player;
    struct message *message;
    struct list mnatl;
    struct list mencl;
    struct list aucodecl;
    struct list ausrcl;
    struct list auplayl;
    struct list aufiltl;
    struct list vidcodecl;
    struct list vidsrcl;
    struct list vidispl;
    struct list vidfiltl;
    struct ui_sub uis;
} tag_baresip;
static int cmd_quit(struct re_printf *pf, void *unused)
{
    int err;
    
    (void)unused;
    
    err = re_hprintf(pf, "Quit\n");
    
    ua_stop_all(false);
    
    return err;
}
static int insmod_handler(struct re_printf *pf, void *arg)
{
    const struct cmd_arg *carg = (const struct cmd_arg *)arg;
    int err;
    
    err = module_load(carg->prm);
    if (err) {
        return re_hprintf(pf, "insmod: ERROR: could not load module"
                          " '%s': %m\n", carg->prm, err);
    }
    
    return re_hprintf(pf, "loaded module %s\n", carg->prm);
}
static int rmmod_handler(struct re_printf *pf, void *arg)
{
    const struct cmd_arg *carg = (const struct cmd_arg *)arg;
    (void)pf;
    
    module_unload(carg->prm);
    
    return 0;
}
static const struct cmd corecmdv[] = {
    {"quit", 'q', 0, "Quit",                     cmd_quit             },
    {"insmod", 0, CMD_PRM, "Load module",        insmod_handler       },
    {"rmmod",  0, CMD_PRM, "Unload module",      rmmod_handler        },
};
*/
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

static const int kDefaultPort = 5060;

static std::unordered_map<call*, SipCall*> sipCallsCache;

@interface SipCall ()
@property (nonatomic) struct call* call;
@end

@implementation SipCall
- (instancetype)init {
    self = [super init];
    return self;
}

- (void)deinit {
    sipCallsCache.erase(self.call);
}

- (NSString*)peerUri {
    return @(call_peeruri(self.call));
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

/*
 int  call_connect(struct call *call, const struct pl *paddr);
 int  call_modify(struct call *call);
 int  call_hold(struct call *call, bool hold);
 int  call_send_digit(struct call *call, char key);
 bool call_has_audio(const struct call *call);
 bool call_has_video(const struct call *call);
 int  call_transfer(struct call *call, const char *uri);

 uint16_t      call_scode(const struct call *call);
 uint32_t      call_duration(const struct call *call);
 uint32_t      call_setup_duration(const struct call *call);
 const char   *call_id(const struct call *call);
 const char   *call_peername(const struct call *call);
 const char   *call_localuri(const struct call *call);
 struct audio *call_audio(const struct call *call);
 struct video *call_video(const struct call *call);
 struct list  *call_streaml(const struct call *call);
 struct ua    *call_get_ua(const struct call *call);
 bool          call_is_onhold(const struct call *call);
 bool          call_is_outgoing(const struct call *call);
 */
@end

@interface SipClient()
@property (nonatomic) struct ua *ua;
@end

static SipCall* getSipCall(struct call *call, SipClient* sipSdk, NSString* remoteUri) {
    SipCall* sipCall;
    auto sipCallCache = sipCallsCache.find(call);
    if (sipCallCache == sipCallsCache.end()) {
        NSLog(@"New call created");
        
        sipCall = [[SipCall alloc] init];
        sipCall.call = call;
    } else {
        NSLog(@"Existing call found");
        
        sipCall = sipCallCache->second;
    }
    
    return sipCall;
}

static void ua_event_handler(struct ua *ua, enum ua_event ev,
    struct call *call, const char *prm, void *arg)
{
    NSLog(@"ua_event_handler ev = \"%@\" prm = \"%@\" call = \"%@\"", @(ev), @(prm), @((long)call));
    
    SipClient* sipSdk = (__bridge SipClient*)arg;
    SipCall* sipCall = getSipCall(call, sipSdk, @(prm));
    
    switch (ev) {
        case UA_EVENT_REGISTERING: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onWillRegister:)]) {
                    [sipSdk.delegate onWillRegister:sipSdk];
                }
            });
        }
            break;
            
        case UA_EVENT_REGISTER_OK: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onDidRegister:)]) {
                    [sipSdk.delegate onDidRegister:sipSdk];
                }
            });
        }
            break;

        case UA_EVENT_REGISTER_FAIL: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onFailedRegister:)]) {
                    [sipSdk.delegate onFailedRegister:sipSdk];
                }
            });
        }
            break;

        case UA_EVENT_UNREGISTERING: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onWillUnRegister:)]) {
                    [sipSdk.delegate onWillUnRegister:sipSdk];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_INCOMING: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallIncoming:)]) {
                    [sipSdk.delegate onCallIncoming:sipCall];
                }
            });
        }
            break;

        case UA_EVENT_CALL_RINGING: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallRinging:)]) {
                    [sipSdk.delegate onCallRinging:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_PROGRESS: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallProcess:)]) {
                    [sipSdk.delegate onCallProcess:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_ESTABLISHED: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallEstablished:)]) {
                    [sipSdk.delegate onCallEstablished:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_CLOSED: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallClosed:)]) {
                    [sipSdk.delegate onCallClosed:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_TRANSFER_FAILED: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallTransferFailed:)]) {
                    [sipSdk.delegate onCallTransferFailed:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_DTMF_START: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sipSdk.delegate respondsToSelector:@selector(onCallDtmfStart:)]) {
                    [sipSdk.delegate onCallDtmfStart:sipCall];
                }
            });
        }
            break;
            
        case UA_EVENT_CALL_DTMF_END: {
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
    
//    NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//    if (documentDirectory != nil) {
//        conf_path_set([documentDirectory cStringUsingEncoding:NSUTF8StringEncoding]);
//    }
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
    
//    uag_set_exit_handler(ua_exit_handler, NULL);

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
/*
- (int)start {
    // Start the main loop.
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(_start) object:nil];
    [thread start];

    return 0;
}

- (int)_start {
    int error = libre_init();
    if (error != 0) {
        return error;
    }
    
    // Initialize dynamic modules.
    mod_init();
    
    NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (documentDirectory != nil) {
        conf_path_set([documentDirectory cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    error = conf_configure();
    if (error != 0) {
        return error;
    }
    
    bool prefer_ipv6 = false;
    
     tag_baresip.net = (struct network *)mem_deref(tag_baresip.net);
     list_init(&tag_baresip.mnatl);
     list_init(&tag_baresip.mencl);
     list_init(&tag_baresip.aucodecl);
     list_init(&tag_baresip.ausrcl);
     list_init(&tag_baresip.auplayl);
     list_init(&tag_baresip.vidcodecl);
     list_init(&tag_baresip.vidsrcl);
     list_init(&tag_baresip.vidispl);
     list_init(&tag_baresip.vidfiltl);
     
     struct config *cfg = conf_config();
     error = net_alloc(&tag_baresip.net, &cfg->net,
     prefer_ipv6 ? AF_INET6 : AF_INET);
     if (error != 0) {
     return error;
     }
     error = contact_init(&tag_baresip.contacts);
     if (error)
     return error;
     error = cmd_init(&tag_baresip.commands);
     if (error)
     return error;
     error = play_init(&tag_baresip.player);
     if (error)
     return error;
     error = message_init(&tag_baresip.message);
     if (error) {
     return error;
     }
     error = cmd_register(tag_baresip.commands, corecmdv, ARRAY_SIZE(corecmdv));
     if (error)
     return error;

//    error = baresip_init(conf_config(), prefer_ipv6);
//    if (error != 0) {
//        return error;
//    }
    
    // Initialize the SIP stack.
    error = ua_init("SIP", true, true, true, prefer_ipv6);
    if (error != 0) {
        return error;
    }
    
    //    uag_set_exit_handler(ua_exit_handler, NULL);
    
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
    re_main(signal_handler);

    return 0;
}
*/
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
    int error = ua_connect(self.ua, &call, [uri cStringUsingEncoding:NSUTF8StringEncoding], nil, VIDMODE_OFF);
    if (error != 0) {
        return nil;
    } else {
        sipCall.call = call;
    }

    return sipCall;
}

-(void)_run {
    // Start the main loop.
    re_main(signal_handler);
}

@end
