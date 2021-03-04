//
//  Audio.h
//  RNSuperpowered
//
//  Created by Ivan Caceres on 10/11/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

#ifndef Audio_h
#define Audio_h

#import <Foundation/Foundation.h>
@interface Audio : NSObject

@property NSDictionary *positions;
@property NSMutableDictionary *audioPlayers;
@property float *stereoBuffer;
@property bool playing;
@property bool recording;
@property NSString *recordedFile;
@property double currentPlayOffset;

+ (instancetype)createInstance;
+ (instancetype)getInstance;
- (NSDictionary *)addAudioPlayer:(NSString *)trackId filePath:(NSString *)filePath;
- (void)updateTrackId:(NSString *)oldId newId:(NSString *)newId;
- (void)playProject:(NSDictionary *)positions;
- (void)toggleProject:(NSDictionary *)positions;
- (bool)setPlayerVolume:(NSString *)trackId volume:(float)volume;
- (bool)setPlayerPitchShift:(NSString *)trackId pitchShiftCents:(int)pitchShiftCents;
- (bool)setPlayerEcho:(NSString *)trackId mix:(float)mix;
- (bool)setPlayerReverb:(NSString *)trackId mix:(float)mix;
- (bool)setPlayerFlanger:(NSString *)trackId enabled:(bool)enabled;
- (bool)setPlayerPlaybackRate:(NSString *)trackId playbackRate:(double)playbackRate;
- (void)toggleRecorder:(NSString *)trackId positions:(NSDictionary *)positions callback:(void (^)(NSArray *))callback;
- (void)deleteTrack:(NSString *)trackId;
- (void)exportStudio;
- (NSDictionary *)split:(NSString *)trackId newId:(NSString *)newId position:(long double)position;
@end

#endif /* Audio_h */
