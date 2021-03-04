//
//  AudioPlayerInstance.m
//  RNSuperpowered
//
//  Created by Ivan Caceres on 10/12/19.
//  Copyright © 2019 Facebook. All rights reserved.
//
#import "AudioPlayerInstance.hpp"
#include <SuperpoweredAdvancedAudioPlayer.h>
#include <SuperpoweredAnalyzer.h>
#include <SuperpoweredSimple.h>
#include <SuperpoweredFlanger.h>

@implementation AudioPlayerInstance

-(id)initWithTrackId:(NSString *)trackIdPtr fileRoute:(NSString *)fileResourcePath {
    self= [super init];
    self.bpm = 0;
    self.beatgridStartMs=0;
    self.ready = false;
    self.trackId=trackIdPtr;
    self.filePath = fileResourcePath;
    self.volume = 0.5f;
    self.echo = new Superpowered::Echo(48000);
    self.flanger = new Superpowered::Flanger(48000);
    self.reverb = new Superpowered::Reverb(48000);
    self.echoMix = 0;
    self.flangerEnabled = false;
//    ClientPayload *payloadPtr = (ClientPayload *)clientDataPayload;
//    self.audioContainer = payloadPtr->clientData;
    return self;
}
-(NSDictionary*) setup:(unsigned int)sampleRate {
    NSLog(@"setup being called %@", self.filePath);
    delete self.player;
    self.player = new Superpowered::AdvancedAudioPlayer(sampleRate, 0);
    return [self prepareAudio];
}

-(NSDictionary *) prepareAudio {
    NSLog(@"calling prepareAudio %@", self.filePath);
    NSDictionary* analysis = [self analyze:self.filePath];
    [self loadFile:self.filePath];
    NSLog(@"FINISHED LOADING %@", self.filePath);
    return analysis;
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

-(NSDictionary *) analyze:(NSString *)fileRoute {
    Superpowered::Decoder *decoder = openSourceFile([fileRoute UTF8String]);
    if (!decoder) {
        @throw [NSException exceptionWithName:@"Unable to decode file." reason: @"" userInfo: nil];
    }
    
    // Create the analyzer.
    Superpowered::Analyzer *analyzer = new Superpowered::Analyzer(decoder->getSamplerate(), decoder->getDurationSeconds());
    
    // Create a buffer for the 16-bit integer audio output of the decoder.
    short int *intBuffer = (short int *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(short int) + 16384);
    // Create a buffer for the 32-bit floating point audio required by the effect.
    float *floatBuffer = (float *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(float) + 16384);
    
    // Processing.
    while (true) {
        int framesDecoded = decoder->decodeAudio(intBuffer, decoder->getFramesPerChunk());
        if (framesDecoded == Superpowered::Decoder::BufferingTryAgainLater) { // May happen for progressive downloads.
            usleep(100000); // Wait 100 ms for the network to load more data.
            continue;
        } else if (framesDecoded < 1) break;
        
        // Submit the decoded audio to the analyzer.
        Superpowered::ShortIntToFloat(intBuffer, floatBuffer, framesDecoded);
        analyzer->process(floatBuffer, framesDecoded);
        
//        progress = (double)decoder->getPositionFrames() / (double)decoder->getDurationFrames();
    };
    
    analyzer->makeResults(60, 200, 0, 0, true, false, true, true, false);
    NSLog(@"Bpm is %f, average loudness is %f db, peak volume is %f db.", analyzer->bpm, analyzer->loudpartsAverageDb, analyzer->peakDb);
    
    self.beatgridStartMs = analyzer->beatgridStartMs;
    self.bpm = analyzer->bpm;
    
    NSMutableArray *waveformPoints = [[NSMutableArray alloc]init];
    
    for (int i=0;i<analyzer->waveformSize;i++) {
        // waveformPoint must be added as Number/float
        [waveformPoints addObject:[NSNumber numberWithFloat:analyzer->averageWaveform[i]]];
    }
    // return BPM and waveform data
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:analyzer->bpm], @"bpm", waveformPoints, @"waveform", [NSNumber numberWithFloat:decoder->getDurationSeconds()], @"durationSeconds", nil];
    
    // Cleanup.
    delete decoder;
    delete analyzer;
    free(intBuffer);
    free(floatBuffer);
    
    return dictionary;
}

-(void)loadFile:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSLog(@"loading File: %@", filePath);
    if(![fileManager fileExistsAtPath:filePath]) {
        NSLog(@"the file doesnt exist!!");
        @throw [NSException exceptionWithName:@"Audio file not exists" reason: @"" userInfo: nil];
    }
    NSLog(@"wowwww running player open");
    self.player->pause();
    self.player->open([filePath UTF8String]);
    NSLog(@"finished running player open");
    return;
}
@end
