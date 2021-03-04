//
//  SuperpoweredManager.m
//  RNSuperpowered
//
//  Created by Ivan Caceres on 10/11/19.
//  Copyright © 2019 Ivan Caceres. All rights reserved.
//

#import "SuperpoweredManager.h"
#import "Superpowered.h"

@implementation SuperpoweredManager

static SuperpoweredManager *instance = nil;

+ (instancetype) createInstance {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if(!instance) {
            instance = [[SuperpoweredManager alloc] initPrivate];
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
//    if(posix_memalign((void **)&stereoBuffer, 16, 4096 + 128) != 0) abort();
    
        self = [super init];
    
        //
//        self->sampleRate = sampleRate;
//
//        //
//        output = [[SuperpoweredIOSAudioIO alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredSamplerate:sampleRate audioSessionCategory:AVAudioSessionCategoryPlayback channels:2 audioProcessingCallback:audioProcessing clientdata:(__bridge void *)self];
//
//        self->echo = new SuperpoweredEcho(sampleRate);
    
    
    Superpowered::Initialize( "UGZZdFpxVHM0L0ZJdmY4YjM2ZjRlOTNiMzFkZGI4ZWQ4ODNkZWJiMWQ5YTcwYmVjYTBkYTViZ3djMUw1UmYualNUazFIY2F2",
                             true, // enableAudioAnalysis (using SuperpoweredAnalyzer, SuperpoweredLiveAnalyzer, SuperpoweredWaveform or SuperpoweredBandpassFilterbank)
                             false, // enableFFTAndFrequencyDomain (using SuperpoweredFrequencyDomain, SuperpoweredFFTComplex, SuperpoweredFFTReal or SuperpoweredPolarFFT)
                             true, // enableAudioTimeStretching (using SuperpoweredTimeStretching)
                             true, // enableAudioEffects (using any SuperpoweredFX class)
                             true, // enableAudioPlayerAndDecoder (using SuperpoweredAdvancedAudioPlayer or SuperpoweredDecoder)
                             false, // enableCryptographics (using Superpowered::RSAPublicKey, Superpowered::RSAPrivateKey, Superpowered::hasher or Superpowered::AES)
                             false  // enableNetworking (using Superpowered::httpRequest)
                             );
    
    NSLog(@"Initialized superowered");
    
        return self;
}
@end
