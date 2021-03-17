//
//  Audio.mm
//  RNSuperpowered
//
//  Created by Ivan Caceres on 10/11/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "Audio.h"
#import "AudioPlayerInstance.hpp"
#include <Superpowered.h>
#include <SuperpoweredSimple.h>
#include <SuperpoweredFlanger.h>
#import <SuperpoweredIOSAudioIO.h>
#include <SuperpoweredReverb.h>
#include <SuperpoweredRecorder.h>
#include <SuperpoweredFilter.h>
#include <SuperpoweredResampler.h>
#include <SuperpoweredTimeStretching.h>

@interface createFileResponse : NSObject
@property NSString *destinationPath;
@property FILE *fd;
@end
@implementation createFileResponse
@end

@implementation Audio {
    Superpowered::Flanger *flanger;
    SuperpoweredIOSAudioIO *output;
    Superpowered::Reverb *reverb;
    Superpowered::AdvancedAudioPlayer *masterPlayer;
    Superpowered::Recorder *recorder;
}
static Audio *instance = nil;

static unsigned int elapsedFrames = 0;

+ (instancetype) createInstance {
    NSLog(@"create Instance is running");
    static dispatch_once_t onceToken;
    

    
    dispatch_once(&onceToken, ^{
        if(!instance) {
            instance = [[Audio alloc] initPrivate];
            //always freshen the audio instance
            [instance setupFreshOutput];
        }

    });

    return instance;
}

+ (instancetype) getInstance {
    return instance;
}

- (instancetype) init {
    @throw [NSException exceptionWithName:@"Singleton Error" reason: @"" userInfo: nil];
}

- (instancetype) initPrivate {
    if (posix_memalign((void **)&_stereoBuffer, 16, 4096 + 128) != 0) abort(); // Allocating memory, aligned to 16.

//    if(posix_memalign((void **)&stereoBuffer, 16, 4096 + 128) != 0) abort();
    NSLog(@"running INIT PRIVATE");
    self = [super init];
    self.playing = false;
    self.currentPlayOffset = 0;
    self.audioPlayers = [NSMutableDictionary dictionary];
    self->flanger = new Superpowered::Flanger(48000);
    self->reverb = new Superpowered::Reverb(48000);
    reverb->roomSize = 0.5f;
    reverb->mix = 0.0f;

    
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

    self->recorder = new Superpowered::Recorder([tempFilePath UTF8String]);
    
    
    //
//    self->sampleRate = sampleRate;
//    
//    //
//    output = [[SuperpoweredIOSAudioIO alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredSamplerate:sampleRate audioSessionCategory:AVAudioSessionCategoryPlayback channels:2 audioProcessingCallback:audioProcessing clientdata:(__bridge void *)self];
//    
//    self->echo = new SuperpoweredEcho(sampleRate);
    
    return self;
}

- (NSDictionary*) addAudioPlayer:(NSString *)filePath {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    return [self addAudioPlayer:uuid filePath:filePath];
}

- (NSDictionary*) addAudioPlayer:(NSString *)trackId filePath:(NSString *)filePath {
    //    SuperpoweredAdvancedAudioPlayer *newPlayer = new SuperpoweredAdvancedAudioPlayer((__bridge void *)self, *pecbPointer, sampleRate, 0);
//    size_t position = self.audioPlayers.size();
//    ClientPayload *payload = new ClientPayload((__bridge void *)self, position);
    AudioPlayerInstance *audioPlayer = [[AudioPlayerInstance alloc] initWithTrackId:trackId fileRoute:filePath];
    [self.audioPlayers setObject:audioPlayer forKey:trackId];
    
    NSDictionary *setupResult = [audioPlayer setup:48000];
    
    return setupResult;
}

- (void) setupFreshOutput {
    output = NULL;
//    self->output = NULL;
//    output = nil;
//    delete output;
    elapsedFrames = 0;
    [self deleteAudioPlayers];
    output = [[SuperpoweredIOSAudioIO alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredSamplerate:48000 audioSessionCategory:AVAudioSessionCategoryPlayAndRecord channels:2 audioProcessingCallback:audioProcessing clientdata:(__bridge void *)self];
}

- (void) exportStudio {
    unsigned int outputSampleRate = 48000;
    unsigned int silenceDuration = 5;
    unsigned int framesPerChunk = 1152;
    bool resampleNeeded = false;
    
    createFileResponse *destinationFile = createDestinationFile([[NSString stringWithFormat:@"%@%@", @"testnew", @".wav"] UTF8String], outputSampleRate);
    
    short int numberOfBytes = framesPerChunk * 2 * sizeof(short int) + 16384;
    // Create a buffer for the 16-bit integer audio output of the decoder.
    short int *intBuffer = (short int *)malloc(numberOfBytes);

//  set to 0 for a buffer filled with silent audio
    memset(intBuffer, 0, framesPerChunk * 2 * sizeof(intBuffer[0]));
    
    FILE *outputFile = destinationFile.fd;

    bool finished = false;
        
    unsigned int chunksCounter = 1;
    
    // Processing.
    while (!finished) {
        Superpowered::writeWAV(outputFile, intBuffer, framesPerChunk * 4);
        chunksCounter++;
        
//      check if enough silence time was written to audio file
        if(chunksCounter > 192){
//            finished = true;
//            begin writing audio file
            for (NSString* key in self.audioPlayers) {
                AudioPlayerInstance *audioPlayer = self.audioPlayers[key];
                // decode all audio from this track and write to file
                Superpowered::Decoder *decoder = openSourceFile([audioPlayer.filePath UTF8String]);
                unsigned int sampleRate = decoder->getSamplerate();
                //if sample rate is different than target rate then resample this file
                if(outputSampleRate != sampleRate){
                    resampleNeeded = true;
                }

                
                // Create a buffer to store 16-bit integer audio up to 1 seconds, which is a safe limit.
                short int *audioIntBuffer = (short int *)malloc(decoder->getSamplerate() * 2 * sizeof(short int) + 16384);
                // Create a buffer to store 32-bit floating point audio up to 1 seconds, which is a safe limit.
                float *floatBuffer = (float *)malloc(decoder->getSamplerate() * 2 * sizeof(float));
                
                // Create a buffer for the 16-bit integer audio output of the decoder.
                short int *trackAudioIntBuffer = (short int *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(short int) + 16384);
                while (true) {
                    int audioTrackFramesDecoded = decoder->decodeAudio(audioIntBuffer, decoder->getFramesPerChunk());
                    if (audioTrackFramesDecoded == Superpowered::Decoder::BufferingTryAgainLater) { // May happen for progressive downloads.
                         usleep(100000); // Wait 100 ms for the network to load more data.
                         continue;
                     } else if (audioTrackFramesDecoded < 1) break;
                    if(resampleNeeded) {
                        
                        // Create the time stretcher.
                        Superpowered::TimeStretching *timeStretch = new Superpowered::TimeStretching(outputSampleRate);
                        timeStretch->rate = 1;
                        timeStretch->pitchShiftCents = 0;
                        // Submit the decoded audio to the time stretcher.
                        Superpowered::ShortIntToFloat(audioIntBuffer, floatBuffer, audioTrackFramesDecoded);
                        timeStretch->addInput(floatBuffer, audioTrackFramesDecoded);
                        // The time stretcher may have 0 or more audio at this point. Write to disk if it has some.
                        unsigned int outputFramesAvailable = timeStretch->getOutputLengthFrames();
                        if ((outputFramesAvailable > 0) && timeStretch->getOutput(floatBuffer, outputFramesAvailable)) {
                            Superpowered::FloatToShortInt(floatBuffer, audioIntBuffer, outputFramesAvailable);
                            Superpowered::writeWAV(outputFile, audioIntBuffer, outputFramesAvailable * 4);
                        }
                    } else {
                        Superpowered::writeWAV(outputFile, audioIntBuffer, audioTrackFramesDecoded * 4);
                    }
                    
                }
                    delete decoder;
                    free(trackAudioIntBuffer);
            }
            finished = true;
        }
    };
    // Close the file and clean up.
    Superpowered::closeWAV(outputFile);
    NSLog(@"finished writing file %@", destinationFile.destinationPath);

    free(intBuffer);
}

static bool audioProcessing(void *clientdata, float **inputBuffers, unsigned int inputChannels, float **outputBuffers, unsigned int outputChannels, unsigned int numberOfFrames, unsigned int samplerate, uint64_t hostTime) {
    __unsafe_unretained Audio *self = (__bridge Audio *)clientdata;
    return [self audioProcessing:outputBuffers[0] right:outputBuffers[1] inputBuffers:inputBuffers numFrames:numberOfFrames samplerate:samplerate];
}

// This is where the Superpowered magic happens.
- (bool)audioProcessing:(float *)leftOutput right:(float *)rightOutput inputBuffers:(float **)inputBuffers numFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate {
//    playerA->outputSamplerate = playerB->outputSamplerate = roll->samplerate = filter->samplerate = flanger->samplerate = samplerate;
    bool silence = false;
    bool audioPlayerProcessResult = false;
    bool hasThereBeenAnyOutput = false;
    float outputBuffer[numberOfFrames * 2];
    unsigned int counter = 0;
    elapsedFrames += numberOfFrames;
    float elapsedMs = (((float)elapsedFrames / (float)samplerate) * 1000) + self.currentPlayOffset;
    
    recorder->recordNonInterleaved(inputBuffers[0], inputBuffers[1], numberOfFrames);
    
    for (NSString* key in self.audioPlayers) {
        AudioPlayerInstance *audioPlayer = self.audioPlayers[key];
        //TODO try setting a property when its done completely playing file EOF
        // try to fix recording??short track?? as first audio player
        Superpowered::AdvancedAudioPlayer::PlayerEvent latestEvent = audioPlayer.player->getLatestEvent();
        if(latestEvent == Superpowered::AdvancedAudioPlayer::PlayerEvent_Opened){
            NSLog(@"player %@ opened", key);
            audioPlayer.player->firstBeatMs = audioPlayer.beatgridStartMs;
            audioPlayer.player->originalBPM = audioPlayer.bpm;
            audioPlayer.player->syncMode = Superpowered::AdvancedAudioPlayer::SyncMode_None;
            self->flanger->bpm = audioPlayer.echo->bpm = audioPlayer.bpm;
            audioPlayer.player->syncToBpm = audioPlayer.bpm;
            audioPlayer.player->syncToMsElapsedSinceLastBeat = audioPlayer.player->getMsElapsedSinceLastBeat();
//            audioPlayer.player->setPosition(0, true, false);
            audioPlayer.ready = true;
        }
        
//        if(!audioPlayerProcessResult) {
//            audioPlayer.player->syncToBpm = audioPlayer.bpm;
//        }
//        if(counter == 0) {
//            masterPlayer = audioPlayer.player;
//            // Everything will sync to the master player's tempo.
//            masterPlayer->syncToBpm = audioPlayer.bpm;
//            silence = false;
//        } else {
//            masterPlayer->syncToMsElapsedSinceLastBeat = audioPlayer.player->getMsElapsedSinceLastBeat();
//            audioPlayer.player->syncToMsElapsedSinceLastBeat = masterPlayer->getMsElapsedSinceLastBeat();
//            silence = true;
//        }
        if(audioPlayer.ready) {
            NSDictionary *trackPos = self.positions[audioPlayer.trackId];
            NSNumber *start = trackPos[@"startPositionMs"];
    //            NSLog(@"show start position %f", start);
            NSComparisonResult startCompare = [start compare:[NSNumber numberWithInt:elapsedMs]];
    //            NSLog(@"Show elapsedMs: %f", elapsedMs);
            // check start time
                if(!audioPlayer.finished && (startCompare == NSOrderedAscending || startCompare == NSOrderedSame)) {
    //                NSLog(@"time to start this player %@", key);
                    if(audioPlayer.player->eofRecently()){
                        audioPlayer.player->togglePlayback();
                        audioPlayer.finished = true;
                    } else {
            //            silence = audioPlayer.player->process(self->stereoBuffer, false, numberOfSamples, 1.0f, masterBpm, nextPlayerElapsedSecondsSinceLastBeat);
    //                    if(counter == 0){
    ////                        NSLog(@"counter was 0");
    //                        audioPlayer.player->play();
    //                    } else {
    //                        NSLog(@"NON ZERO COUNTER NOT FIRST");
                            audioPlayer.player->play();
    //                    }
                        
                        audioPlayer.echo->bpm = audioPlayer.bpm;
                        if(audioPlayer.echoMix > 0){

                            audioPlayer.echo->enabled = true;
                            audioPlayer.echo->setMix(audioPlayer.echoMix);
                        } else {
                            audioPlayer.echo->enabled = false;
                        }
                        if(audioPlayer.reverbMix > 0.0f){
                            audioPlayer.reverb->enabled = true;
                            audioPlayer.reverb->mix = audioPlayer.reverbMix;
                        } else {
                            audioPlayer.reverb->enabled = false;
                            audioPlayer.reverb->mix = 0.0f;
                        }
                        audioPlayer.flanger->enabled = audioPlayer.flangerEnabled;
                    }
                } else {
                    audioPlayer.player->pause();
                }
            
            }
        
            audioPlayerProcessResult = audioPlayer.player->processStereo(outputBuffer, hasThereBeenAnyOutput, numberOfFrames, audioPlayer.volume);
            if(audioPlayerProcessResult){
                hasThereBeenAnyOutput = true;
            }
            silence = !audioPlayerProcessResult;
        
    //        NSLog(@"player %@ silence: %u", key, silence);
        
        
            float *fxOutputBuffer = silence ? NULL : outputBuffer;
            audioPlayer.flanger->process(fxOutputBuffer, outputBuffer, numberOfFrames);
            audioPlayer.echo->process(fxOutputBuffer, outputBuffer, numberOfFrames);
            audioPlayer.reverb->process(fxOutputBuffer, outputBuffer, numberOfFrames);
        
            // this audioPlayer was silent
            // reset silence to false so next player in loop has processStereo() mix set to false
    //        if(audioPlayer.finished) {
    //            silence = false;
    //            continue;
    //        }

            counter++;
        }
    
    //only output if theres tracks
//    NSLog(@"show the counter value %i", counter);
//    if(counter == 0) {
//        silence = true;
//    }
    
    if (hasThereBeenAnyOutput) {
        Superpowered::DeInterleave(outputBuffer, leftOutput, rightOutput, numberOfFrames);
    }
    return hasThereBeenAnyOutput;
}

-(void) deleteAudioPlayers {
    for (NSString* key in self.audioPlayers) {
        AudioPlayerInstance *audioPlayer = self.audioPlayers[key];
        // access position values for this track
        delete audioPlayer.player;
    }
    
    self.audioPlayers = [NSMutableDictionary dictionary];
}

- (void) dealloc {
    NSLog(@"calling DEALLOC");
}

- (void) resetProjectPosition {
    [self setProjectPosition:0];
}

- (void) toggleProject:(NSDictionary *)positions {
    if (self.playing) {
        [self->output stop];
    }
    
    if(!self.playing) {
        [self playProject:positions];
    } else {
        [self stopProject];
    }
}

- (void) playProject:(NSDictionary *)positions {
    unsigned int counter = 0;
    
//    [self->output stop];

    if (positions.allKeys.count == 0) {
        self.currentPlayOffset = 0;
        [self setProjectPosition:0];
        self.playing = true;
        elapsedFrames = 0;
        [self->output start];
    } else {
        self.positions = positions[@"positions"];
        NSNumber *current = positions[@"current"];
        self.currentPlayOffset = current.doubleValue;
        [self setProjectPosition:current.doubleValue];
        self.playing = true;
        elapsedFrames = 0;
        [self->output start];
    }
    
//    for (NSString* key in self.audioPlayers) {
//        AudioPlayerInstance *audioPlayer = self.audioPlayers[key];
//        // access position values for this track
//        if(counter==0){
//            NSLog(@"counter was 0 this player getting played");
//            audioPlayer.player->play();
//        } else {
//            audioPlayer.player->playSynchronized();
//        }
//        counter++;
//    }
}

- (void) stopProject {
    [self setProjectPosition:0];
    self.playing = false;
    [self->output stop];
//    self.positions = positions;

    for (NSString* key in self.audioPlayers) {
        AudioPlayerInstance *audioPlayer = self.audioPlayers[key];
        // access position values for this track
        audioPlayer.player->pause();
    }
}

-(void) toggleRecorder:(NSString *)trackId positions:(NSDictionary *)positions callback:(void(^)(NSArray *))callback {
    if(!self.recording) {
        self.recordedFile = [self setupRecording];
        if(!self.playing){
            [self playProject:positions];
        }
    } else {
        recorder->stop();
        [self stopProject];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            NSTimer *timer = [NSTimer timerWithTimeInterval:1 repeats:true block:^(NSTimer *time) {
                if(recorder->isFinished()){
                    [time invalidate];
                    // set up audio player
                    NSDictionary *setupResult = [self addAudioPlayer:trackId filePath:[self.recordedFile stringByAppendingString:@".wav"]];
                    callback(@[[NSNull null], setupResult]);
                }
                
            }];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        });
    }
    self.recording = !self.recording;
}


-(NSString *) setupRecording {
    
    NSString *destinationPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithUTF8String:"SuperpoweredRecordingTest"]];
    NSLog(@"show recording destination path: %@", destinationPath);
    // Start a new recording.
    self->recorder->prepare(
                            [destinationPath UTF8String],                     // destination path
                            48000, // sample rate in Hz
                            true,                     // apply fade in/fade out
                            1                         // minimum length of the recording in seconds
                            );
    return destinationPath;
}

- (void) setProjectPosition:(double)position {
    // seconds * sampleRate = elapsedFrames
    elapsedFrames = (position * 1000) * 48000;
    for (NSString* key in self.audioPlayers) {
        AudioPlayerInstance *audioPlayer = self.audioPlayers[key];
        // access position values for this track
        audioPlayer.finished = false;
        NSDictionary *trackPos = self.positions[key];
        NSNumber *start = trackPos[@"startPositionMs"];
        NSNumber *end = trackPos[@"endPositionMs"];
        double difference = self.currentPlayOffset - start.doubleValue;
        NSComparisonResult endCompare = [end compare:[NSNumber numberWithInt:position]];
        if(endCompare == NSOrderedAscending || endCompare == NSOrderedSame) {
            audioPlayer.finished = true;
        }
        if(difference < 0) {
            difference = 0;
            audioPlayer.player->pause();
        }
        audioPlayer.player->setPosition(difference, false, false);
    }
}

- (void) updateTrackId:(NSString *)oldId newId:(NSString *)newId {
    AudioPlayerInstance *player = self.audioPlayers[oldId];
    player.trackId = newId;
    // clone track under new id
    [self.audioPlayers setObject: player forKey:newId];
    // remove old track at old id
    [self.audioPlayers removeObjectForKey: oldId];
}

// Creates a Superpowered Decoder and tries to open a file.
static Superpowered::Decoder *openSourceFile(const char *path) {
    Superpowered::Decoder *decoder = new Superpowered::Decoder();
    
    while (true) {
        int openReturn = decoder->open(path);
    
        switch (openReturn) {
            case Superpowered::Decoder::OpenSuccess: return decoder;
            case Superpowered::Decoder::BufferingTryAgainLater: usleep(100000); break; // May happen for progressive downloads. Wait 100 ms for the network to load more data.
            default:
                delete decoder;
                NSLog(@"Open error %i: %s", openReturn, Superpowered::Decoder::statusCodeToString(openReturn));
                return NULL;
        }
    }
}

- (void) deleteTrack:(NSString *)trackId {
    AudioPlayerInstance *audioPlayerInstance = self.audioPlayers[trackId];
    delete audioPlayerInstance.player;
    [self.audioPlayers removeObjectForKey:trackId];
}

// Creates the output WAV file. The destination is accessible in iTunes File Sharing. https://support.apple.com/en-gb/HT201301
static createFileResponse *createDestinationFile(const char *filename, unsigned int samplerate) {
    NSString *destinationPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithUTF8String:filename]];
    FILE *fd = Superpowered::createWAV([destinationPath fileSystemRepresentation], samplerate, 2);
    if (fd) NSLog(@"File created at %@.", destinationPath); else NSLog(@"File creation error.");
    createFileResponse *response = [[createFileResponse alloc] init];
    response.destinationPath = destinationPath;
    response.fd = fd;
    return response;
}

- (NSDictionary *) split:(NSString *)trackId newId:(NSString *)newId position:(long double)position {
    AudioPlayerInstance *audioPlayerInstance = self.audioPlayers[trackId];
    Superpowered::Decoder *decoder = openSourceFile([audioPlayerInstance.filePath UTF8String]);
//    if (!decoder) return;
    
    
    unsigned int sampleRate = decoder->getSamplerate();
    
    
    createFileResponse *destinationFile = createDestinationFile([[NSString stringWithFormat:@"%@%@", trackId, @".wav"] UTF8String], decoder->getSamplerate());
    createFileResponse *destinationFileB = createDestinationFile([[NSString stringWithFormat:@"%@%@", newId, @".wav"] UTF8String], decoder->getSamplerate());
    FILE *outputFile = destinationFile.fd;
    FILE *outputFileB = destinationFileB.fd;
    if (!destinationFile) {
        delete decoder;
        @throw [NSException exceptionWithName:@"Unable to createDestinationFile." reason: @"" userInfo: nil];
//        return;
    }
    
    // Create the low-pass filter.
//    Superpowered::Filter *filter = new Superpowered::Filter(Superpowered::Resonant_Lowpass, decoder->getSamplerate());
//    filter->frequency = 1000.0f;
//    filter->resonance = 0.1f;
//    filter->enabled = true;

    // Create a buffer for the 16-bit integer audio output of the decoder.
    short int *intBuffer = (short int *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(short int) + 16384);
    // Create a buffer for the 32-bit floating point audio required by the effect.
    float *floatBuffer = (float *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(float) + 16384);
    
    short int *silenceBuffer = (short int *)malloc(1152 * 2 * sizeof(short int) + 16384);
    
//    
//    short int *secondIntBuffer = (short int *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(short int) + 16384);
//    float *secondFloatBuffer = (float *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(float) + 16384);
    
    long double elapsedMs = 0;
    int64_t elapsedSeconds = 0;
    int64_t elapsedMsNew = 0;
    
    long double positionSeconds = position / 1000;
//    unsigned int targetFrame = sampleRate * positionSeconds;
    
    // Processing.
    while (true) {
        int framesDecoded = decoder->decodeAudio(intBuffer, decoder->getFramesPerChunk());
        int64_t currentFrame = decoder->getPositionFrames();

        Superpowered::ShortIntToFloat(intBuffer, floatBuffer, framesDecoded);
        Superpowered::FloatToShortInt(floatBuffer, intBuffer, framesDecoded);
        // if next chunk frames decode overshoots target cut then grab those frames and write them to file now
//        currentFramePosition = decoder->getPositionFrames();
//        if(currentFramePosition + framesPerChunk > targetFrame) {
//            framesPerChunk = targetFrame - currentFramePosition;
//            framesDecoded = decoder->decodeAudio(intBuffer, framesPerChunk);
//            elapsedMs += ((float)framesDecoded / (float)44100) * 1000;
//            Superpowered::ShortIntToFloat(intBuffer, floatBuffer, framesDecoded);
//            Superpowered::FloatToShortInt(floatBuffer, intBuffer, framesDecoded);
//        }
        
        if (framesDecoded == Superpowered::Decoder::BufferingTryAgainLater) { // May happen for progressive downloads.
            usleep(100000); // Wait 100 ms for the network to load more data.
            continue;
        } else if (framesDecoded < 1) break;
        
        elapsedMs += ((float)framesDecoded / (float)48000) * 1000;
//        Superpowered::ShortIntToFloat(intBuffer, floatBuffer, framesDecoded);
//        Superpowered::FloatToShortInt(floatBuffer, intBuffer, framesDecoded);
        
        elapsedSeconds = currentFrame / sampleRate;
        if(elapsedSeconds > positionSeconds) {
            // Write the audio to disk and update the progress indicator.
            Superpowered::writeWAV(outputFileB, intBuffer, framesDecoded * 4);
            
        } else {
            // Write the audio to disk and update the progress indicator.
            Superpowered::writeWAV(outputFile, intBuffer, framesDecoded * 4);
        }
//        elapsedMsNew += (currentFramePosition / sampleRate) * 1000;
//        elapsedMs += ((double)framesDecoded / (double)44100) * 1000;
        
        // Apply the effect.

//        progress = (double)decoder->getPositionFrames() / (double)decoder->getDurationFrames();
    };
    NSLog(@"finished writing files");
    // Close the file and clean up.
    Superpowered::closeWAV(outputFile);
    Superpowered::closeWAV(outputFileB);
//    update existing audioPlayerInstance
    audioPlayerInstance.filePath = destinationFile.destinationPath;
    NSLog(@"going to set up clipB");
    NSString *clipBId = newId;
    NSDictionary *clipBSetupResults = [self addAudioPlayer:clipBId filePath:destinationFileB.destinationPath];
    NSLog(@"preparing clipA");
//    [audioPlayerInstance pause;]
    NSDictionary *clipASetupResults = [audioPlayerInstance setup:48000];
    
    NSDictionary *clipA = [NSDictionary dictionaryWithObjectsAndKeys: trackId, @"id", destinationFile.destinationPath, @"filepath", clipASetupResults[@"waveform"], @"waveform", clipASetupResults[@"durationSeconds"], @"durationSeconds", nil];
    
    NSDictionary *clipB = [NSDictionary dictionaryWithObjectsAndKeys: clipBId, @"id", destinationFileB.destinationPath, @"filepath", clipBSetupResults[@"waveform"], @"waveform", clipBSetupResults[@"durationSeconds"], @"durationSeconds", nil];

    delete decoder;
//    delete filter;
    free(intBuffer);
    free(floatBuffer);
    
    // return BPM and waveform data
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: trackId, @"id", clipA, @"clipA", clipB, @"clipB", nil];
    return dictionary;
}


- (bool) setPlayerVolume:(NSString *)trackId volume:(float)volume {
    AudioPlayerInstance *audioPlayerInstance = self.audioPlayers[trackId];
    
    audioPlayerInstance.volume = volume;
    return true;
}

- (bool) setPlayerPitchShift:(NSString *)trackId pitchShiftCents:(int)pitchShiftCents {
    AudioPlayerInstance *audioPlayerInstance = self.audioPlayers[trackId];
    
    audioPlayerInstance.player->pitchShiftCents = pitchShiftCents;
    return true;
}

- (bool) setPlayerEcho:(NSString *)trackId mix:(float)mix {
    AudioPlayerInstance *audioPlayerInstance = self.audioPlayers[trackId];
    audioPlayerInstance.echoMix = mix;
    return true;
}

- (bool) setPlayerReverb:(NSString *)trackId mix:(float)mix {
    AudioPlayerInstance *audioPlayerInstance = self.audioPlayers[trackId];
    audioPlayerInstance.reverbMix = mix;
    return true;
}

- (bool) setPlayerFlanger:(NSString *)trackId enabled:(bool)enabled {
    AudioPlayerInstance *audioPlayerInstance = self.audioPlayers[trackId];
    audioPlayerInstance.flangerEnabled = enabled;
    return true;
}

- (bool) setPlayerPlaybackRate:(NSString *)trackId playbackRate:(double)playbackRate{
    
    AudioPlayerInstance *audioPlayerInstance = self.audioPlayers[trackId];
    masterPlayer->playbackRate = playbackRate;
//    audioPlayerInstance.player->playbackRate = playbackRate;
    NSLog(@"update playback rate for player: %f", playbackRate);
    return true;
}

@end
