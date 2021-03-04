
#import "RNSuperpowered.h"
#import "SuperpoweredManager.h"
//#import "Recorder.h"
#import "Audio.h"
#import "AudioPlayer.h"

@implementation RNSuperpowered

static dispatch_queue_t RCTGetMethodQueue()
{
    // We want all instances to share the same queue since they will be reading/writing the same files.
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.craftmusic.analyze", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
    return RCTGetMethodQueue();
}
//
//RCT_EXPORT_METHOD(startRecord:(NSInteger)sampleRate minSeconds:(NSInteger)minSeconds numChannels:(NSInteger)numChannels applyFade:(BOOL)applyFade) {
//    Recorder *recorder = [Recorder createInstance: sampleRate minSeconds:minSeconds numChannels:numChannels applyFade:applyFade];
//
//    [recorder startRecord: @"audio"];
//}
//
//RCT_REMAP_METHOD(stopRecord,
//                 resolver:(RCTPromiseResolveBlock)resolve
//                 rejecter:(RCTPromiseRejectBlock)reject) {
//    Recorder *recorder = [Recorder getInstance];
//    NSString *destPath = [recorder stopRecord];
//
//    resolve(destPath);
//}

RCT_EXPORT_METHOD(initializeAudio) {
    [SuperpoweredManager createInstance];
    [Audio createInstance];
//    [audio loadFile:filePath];
}
//
RCT_EXPORT_METHOD(addAudioPlayer:(NSString *)trackId filePath:(NSString *)filePath :(RCTResponseSenderBlock)callback){
    dispatch_async(RCTGetMethodQueue(), ^{
        NSDictionary* trackAnalysis = [[Audio getInstance] addAudioPlayer:trackId filePath:filePath];
        callback(@[[NSNull null], trackAnalysis]);
    });
}
//
RCT_EXPORT_METHOD(audioPlayerLoadFile:(NSString *)filePath) {
    NSLog(@"yooo calling audioPlayerLoadFile");
    [SuperpoweredManager createInstance];
    [[AudioPlayer getInstance] audioLoadFile:filePath];


}

RCT_EXPORT_METHOD(deleteTrack:(NSString *)trackId) {
    [[Audio getInstance] deleteTrack:trackId];
}

RCT_EXPORT_METHOD(exportStudio) {
    [[Audio getInstance] exportStudio];
}

RCT_EXPORT_METHOD(split:(NSString *)trackId newId:(NSString *)newId position:(double)position :(RCTResponseSenderBlock)callback) {
    // split the audio track and return new clipA and clipB results payload to frontend
    NSDictionary *splitResults = [[Audio getInstance] split:trackId newId:newId position:position];

    callback(@[[NSNull null], splitResults]);
}

RCT_EXPORT_METHOD(audioPlayerGetProgress:(RCTResponseSenderBlock)callback) {
    float progress = [[AudioPlayer getInstance] getProgress];
    NSDictionary *progressD = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:progress], @"progress", nil];
    callback(@[[NSNull null], progressD]);
}

RCT_EXPORT_METHOD(audioPlayerGetDuration:(RCTResponseSenderBlock)callback) {
    unsigned int durationMs = [[AudioPlayer getInstance] getDuration];
    NSDictionary *duration = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:durationMs], @"durationMs", nil];
    callback(@[[NSNull null], duration]);
}

RCT_EXPORT_METHOD(audioPlayerGetLatestEvent:(RCTResponseSenderBlock)callback){
    NSString *latestEvent = [[AudioPlayer getInstance] getLatestEvent];
    callback(@[[NSNull null], latestEvent]);
//    dispatch_async(RCTGetMethodQueue(), ^{
//        NSDictionary* trackAnalysis = [[Audio getInstance] addAudioPlayer:trackId filePath:filePath];
//        callback(@[[NSNull null], trackAnalysis]);
//    });
}

RCT_EXPORT_METHOD(audioPlayerTogglePlay){
    [[AudioPlayer getInstance] play];
}

RCT_EXPORT_METHOD(audioPlayerPause){
    [[AudioPlayer getInstance] pause];
}

RCT_EXPORT_METHOD(audioPlayerSetPositionMs:(float)ms) {
    [[AudioPlayer getInstance] setPositionMs:ms];
}

//
//RCT_EXPORT_METHOD(playAudio:(NSInteger)position) {
//    [[Audio getInstance] play:position];
//}
//

RCT_EXPORT_METHOD(playProject:(NSDictionary *)positions) {
    [[Audio getInstance] playProject:positions];
}

RCT_EXPORT_METHOD(toggleProject:(NSDictionary *)positions) {
    [[Audio getInstance] toggleProject:positions];
}

RCT_EXPORT_METHOD(updateTrackId:(NSString *)oldId newId:(NSString *)newId) {
    [[Audio getInstance] updateTrackId:oldId newId:newId];
}

RCT_EXPORT_METHOD(toggleRecorder:(NSString *)trackId positions:(NSDictionary *)positions callback:(RCTResponseSenderBlock)callback) {
    [[Audio getInstance] toggleRecorder:trackId positions:positions callback:callback];
}

RCT_EXPORT_METHOD(setPlayerVolume:(NSString *)trackId volume:(float)volume) {
    [[Audio getInstance] setPlayerVolume:trackId volume:volume];
}

RCT_EXPORT_METHOD(setPlayerPitchShift:(NSString *)trackId pitchShiftCents:(float)pitchShiftCents) {
    [[Audio getInstance] setPlayerPitchShift:trackId pitchShiftCents:pitchShiftCents];
}

RCT_EXPORT_METHOD(setPlayerEcho:(NSString *)trackId mix:(float)mix) {
    [[Audio getInstance] setPlayerEcho:trackId mix:mix];
}

RCT_EXPORT_METHOD(setPlayerReverb:(NSString *)trackId mix:(float)mix) {
    [[Audio getInstance] setPlayerReverb:trackId mix:mix];
}

RCT_EXPORT_METHOD(setPlayerFlanger:(NSString *)trackId enabled:(BOOL)enabled) {
    [[Audio getInstance] setPlayerFlanger:trackId enabled:enabled];
}

RCT_EXPORT_METHOD(setPlayerPlaybackRate:(NSString *)trackId playbackRate:(double)playbackRate) {
    [[Audio getInstance] setPlayerPlaybackRate:trackId playbackRate:playbackRate];
}

//RCT_EXPORT_METHOD(pauseProject) {
//    [[Audio getInstance] pauseProject];
//}
//
//RCT_EXPORT_METHOD(pauseAudio) {
//    [[Audio getInstance] pause];
//}
//
//RCT_EXPORT_METHOD(getPosition:(RCTResponseSenderBlock)callback) {
//    int pos = [[Audio getInstance] getPosition];
//    callback(@[[NSNull null], [NSNumber numberWithInt:pos]]);
//}
//
//RCT_EXPORT_METHOD(setEcho:(float)mix) {
//    [[Audio getInstance] setEcho:mix];
//}
//
//RCT_EXPORT_METHOD(setPitchShift:(int)pitchShift) {
//    [[Audio getInstance] setPitchShift:pitchShift];
//}
//
//RCT_EXPORT_METHOD(setTempo:(double)tempo masterTempo:(BOOL)masterTempo) {
//    [[Audio getInstance] setTempo:tempo masterTempo:masterTempo];
//}
//
//RCT_EXPORT_METHOD(detectBpm:(NSString *)filePath) {
//    [[Audio getInstance] detectBpm:filePath];
//}
//
//RCT_REMAP_METHOD(process,
//                 filePath:(NSString *)fileName
//                 resolver:(RCTPromiseResolveBlock)resolve
//                 rejecter:(RCTPromiseRejectBlock)reject) {
//    Audio *audio = [Audio getInstance];
//
//    @try {
//        NSString *filePath = [audio process:fileName];
//
//        NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
//        response[@"uri"] = filePath;
//        response[@"isSuccess"] = @YES;
//
//        resolve(response);
//
//    } @catch (NSException *exception) {
//        reject(exception.name, exception.reason, nil);
//    }
//}

@end
