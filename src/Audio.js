import { NativeModules } from 'react-native';

const { RNSuperpowered } = NativeModules;

class Audio {
  constructor() {
    RNSuperpowered.initializeAudio();
    this._initialized = true;
  }

  addAudioPlayer = (id, filePath, callback) => {
    return RNSuperpowered.addAudioPlayer(id, filePath, callback);
  };

  loadFile = (filePath) => RNSuperpowered.loadFile(filePath);

  playProject = (positions) => RNSuperpowered.playProject(positions);

  toggleProject = (current, positions) => RNSuperpowered.toggleProject({ current, positions });

  // pauseProject = () => RNSuperpowered.pauseProject();

  // play = position => RNSuperpowered.playAudio(position);

  // pause = () => RNSuperpowered.pauseAudio();

  // stop = () => RNSuperpowered.stopAudio();

  toggleRecorder = (trackId, positions, callback) =>
    RNSuperpowered.toggleRecorder(trackId, positions, callback);

  updateTrackId = (id, newId) => RNSuperpowered.updateTrackId(id, newId);

  // setPosition = ms => RNSuperpowered.setPosition(ms);

  // getPosition = callback => RNSuperpowered.getPosition(callback);

  // // setBpm = (bpm) => RNSuperpowered.setBpm(bpm)
  // setEcho = mix => RNSuperpowered.setEcho(mix);
  // pitch shift cents value from -1200 to 1200
  setPlayerVolume = (trackId, volume) => {
    RNSuperpowered.setPlayerVolume(trackId, volume);
  };

  setPlayerPitchShift = (trackId, pitchShift) =>
    RNSuperpowered.setPlayerPitchShift(trackId, pitchShift);

  // wet dry mix method 0 => 1
  setPlayerEcho = (trackId, mix) => RNSuperpowered.setPlayerEcho(trackId, mix);

  setPlayerReverb = (trackId, mix) => RNSuperpowered.setPlayerReverb(trackId, mix);

  setPlayerFlanger = (trackId, enabled) => RNSuperpowered.setPlayerFlanger(trackId, enabled);

  setPlayerPlaybackRate = (trackId, playbackRate) =>
    RNSuperpowered.setPlayerPlaybackRate(trackId, playbackRate);

  static split = (trackId, newId, position, callback) =>
    RNSuperpowered.split(trackId, newId, position, callback);

  static deleteTrack = (id) => RNSuperpowered.deleteTrack(id);

  static export = () => RNSuperpowered.exportStudio();

  // // setTempo = (tempo, masterTempo) => RNSuperpowered.setTempo(tempo, masterTempo)
  // // detectBpm = (filePath) => RNSuperpowered.detectBpm(filePath)

  // process = (filePath = '') => {
  //   if (!filePath) {
  //     filePath = (Math.random() + 1).toString(36).substr(2, 10);
  //   }

  //   return RNSuperpowered.process(filePath);
  // };
}

export default Audio;
