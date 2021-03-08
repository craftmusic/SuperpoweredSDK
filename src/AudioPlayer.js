import { NativeModules } from 'react-native';

const { RNSuperpowered } = NativeModules;

class AudioPlayer {
  constructor() {
    RNSuperpowered.initializeAudio();
    // this._initialized = true;
  }

  static loadFile = filePath => {
    // console.log('calling loadFile', filePath);
    RNSuperpowered.audioPlayerLoadFile(filePath);
  };

  static getDuration = callback => {
    RNSuperpowered.audioPlayerGetDuration(callback);
  };

  static getProgress = callback => {
    RNSuperpowered.audioPlayerGetProgress(callback);
  };

  static getLatestEvent = callback => {
    RNSuperpowered.audioPlayerGetLatestEvent(callback);
  };

  static togglePlayback = () => {
    RNSuperpowered.audioPlayerTogglePlay();
  };

  static pause = () => {
    RNSuperpowered.audioPlayerPause();
  };

  static setPositionMs = ms => {
    RNSuperpowered.audioPlayerSetPositionMs(ms);
  };
}

export default AudioPlayer;
