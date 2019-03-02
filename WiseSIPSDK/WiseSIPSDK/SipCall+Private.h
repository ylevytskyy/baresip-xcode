//
//  SipCall+Private.h
//  WiseSIPSDK
//
//  Created by Yuriy Levytskyy on 3/2/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//
#import "SipCall.h"

#define HAVE__BOOL

#import "re.h"
#import "baresip.h"

#include <unordered_map>

struct call;

@interface SipCall ()
@property (nonatomic) struct call* call;
@end

extern std::unordered_map<call*, SipCall*> sipCallsCache;

void call_event(struct call *call, enum call_event ev, const char *str, void *arg);
void call_dtmf(struct call *call, char key, void *arg);

void clearCall(struct call *call);
