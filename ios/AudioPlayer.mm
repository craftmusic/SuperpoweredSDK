//
//  AudioPlayer.mm
//  RNSuperpowered
//
//  Created by Ivan Caceres on 11/20/19.
//  Copyright © 2019 Facebook. All rights reserved.
//
#import "AudioPlayer.h"
#include <Superpowered.h>
#include <SuperpoweredSimple.h>
#import <SuperpoweredIOSAudioIO.h>
#include <SuperpoweredAdvancedAudioPlayer.h>

@implementation AudioPlayer {
    Superpowered::AdvancedAudioPlayer *player;
    SuperpoweredIOSAudioIO *audioIO;
    id eventCallback;
}

static AudioPlayer *instance = nil;

+ (instancetype) createInstance {
    NSLog(@"audio player create Instance is running");
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        if(!instance) {
            instance = [[AudioPlayer alloc] init];
        }

    });

    return instance;
}

+ (instancetype) getInstance {
    if(!instance){
        [self createInstance];
    }
    return instance;
}

- (id) init {
    self = [super init];
    Superpowered::AdvancedAudioPlayer::setTempFolder([NSTemporaryDirectory() fileSystemRepresentation]);
    self->player = new Superpowered::AdvancedAudioPlayer(48000, 0);
    self->audioIO = [[SuperpoweredIOSAudioIO alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredSamplerate:48000 audioSessionCategory:AVAudioSessionCategoryPlayback channels:2 audioProcessingCallback:audioProcessing clientdata:(__bridge void *)self];
    [audioIO start];
    return self;
}

// Called periodically by the operating system's audio stack to provide audio output.
static bool audioProcessing(void *clientdata, float **inputBuffers, unsigned int inputChannels, float **outputBuffers, unsigned int outputChannels, unsigned int numberOfFrames, unsigned int samplerate, uint64_t hostTime) {
    __unsafe_unretained AudioPlayer *self = (__bridge AudioPlayer *)clientdata;
    self->player->outputSamplerate = samplerate;

    float interleavedBuffer[numberOfFrames * 2];

//    Superpowered::PlayerEvent latestEvent = self->player->getLatestEvent();
//    if(latestEvent == Superpowered::PlayerEvent_Opened){
////        self->player->setPosition(60000, true, false);
//        NSLog(@"PLAYER WAS OPENED");
//        self->player->play();
//    }
//    if(latestEvent == Superpowered::PlayerEvent_OpenFailed){
//        int code = self->player->getOpenErrorCode();
//        const char *humanCode = self->player->statusCodeToString(code);
//        NSLog(@"%s", humanCode);
//    }

    bool notSilence = self->player->processStereo(interleavedBuffer, false, numberOfFrames);
    if (notSilence) Superpowered::DeInterleave(interleavedBuffer, outputBuffers[0], outputBuffers[1], numberOfFrames);
    return notSilence;
}

- (void) audioLoadFile:(NSString *)filePath {
    NSLog(@"calling audio player loadFile");
    NSLog(@"%s", [filePath UTF8String]);

    self->player->setPosition(0, true, false);
    self->player->open([filePath UTF8String]);
}

- (void) setPositionMs:(float)ms {
    self->player->setPosition(ms, false, false);
}

- (unsigned int) getDuration {
    return self->player->getDurationMs();
}

- (float) getProgress {
    return self->player->getDisplayPositionPercent();
}

- (void) play {
    self->player->togglePlayback();
}

- (void) pause {
    self->player->pause();
}

- (NSString *) getLatestEvent {
    if(!self->player){
        return @"NothingLoaded";
    }
    if(self->player->eofRecently()){
        return @"Finished";
    }
    Superpowered::AdvancedAudioPlayer::PlayerEvent latestEvent = self->player->getLatestEvent();
    if(latestEvent == Superpowered::AdvancedAudioPlayer::PlayerEvent_Opened) {
        return @"Opened";
    }
    if(latestEvent == Superpowered::AdvancedAudioPlayer::PlayerEvent_OpenFailed) {
        return @"OpenFailed";
    }
    if(latestEvent == Superpowered::AdvancedAudioPlayer::PlayerEvent_ConnectionLost) {
        return @"ConnectionLost";
    }
    if(latestEvent == Superpowered::AdvancedAudioPlayer::PlayerEvent_ProgressiveDownloadFinished) {
        return @"ProgressiveDownloadFinished";
    }
    if(latestEvent == Superpowered::AdvancedAudioPlayer::PlayerEvent_Opening) {
        return @"Opening";
    }
    return @"None";
}

@end
