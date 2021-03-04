//
//  AudioPlayerInstance.h
//  RNSuperpowered
//
//  Created by Ivan Caceres on 10/12/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

#ifndef AudioPlayerInstance_h
#define AudioPlayerInstance_h

#import <Foundation/Foundation.h>
#include <SuperpoweredAdvancedAudioPlayer.h>
#include <SuperpoweredEcho.h>
#include <SuperpoweredFlanger.h>
#include <SuperpoweredReverb.h>

@interface AudioPlayerInstance : NSObject
    @property Superpowered::AdvancedAudioPlayer *player;
    @property size_t position;
    @property NSString *filePath;
    @property NSString *trackId;
    @property float *stereoBuffer;
    @property float bpm;
    @property float beatgridStartMs;
    @property bool ready;
    @property float volume;
    @property float echoMix;
    @property float reverbMix;
    @property Superpowered::Echo *echo;
    @property bool flangerEnabled;
    @property Superpowered::Flanger *flanger;
    @property Superpowered::Reverb *reverb;
    @property bool finished;

-(NSDictionary *)setup:(unsigned int)sampleRate;
-(NSDictionary *)prepareAudio;
-(id)initWithTrackId:(NSString *)trackIdPtr fileRoute:(NSString *)fileResourcePath;
@end

#endif /* AudioPlayerInstance_h */
