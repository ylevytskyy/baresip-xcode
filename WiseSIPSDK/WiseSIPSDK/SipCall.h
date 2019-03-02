//
//  SipCall.h
//  WiseSIPSDK
//
//  Created by Yuriy Levytskyy on 3/2/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// SIP Call
@interface SipCall : NSObject
@property (nonatomic, readonly) NSString* peerUri;
@property (nonatomic, readonly) unsigned duration;
@property (nonatomic, readonly) unsigned short statusCode;

- (void)answer;
- (void)hangup:(unsigned short)statusCode reason:(NSString*)reason;
- (void)holdAnswer;
- (int)hold:(bool)hold;
- (int)sendDigit:(char)key;
@end

NS_ASSUME_NONNULL_END
