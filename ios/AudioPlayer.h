//
//  AudioPlayer.h
//  RNSuperpowered
//
//  Created by Ivan Caceres on 11/20/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

#ifndef AudioPlayer_h
#define AudioPlayer_h

#import <Foundation/Foundation.h>
@interface AudioPlayer : NSObject
+ (instancetype)getInstance;
- (void)audioLoadFile:(NSString *)filePath;
- (NSString *)getLatestEvent;
- (unsigned int)getDuration;
- (float)getProgress;
- (void)setPositionMs:(float)ms;
- (void)play;
- (void)pause;
@end
#endif /* AudioPlayer_h */
