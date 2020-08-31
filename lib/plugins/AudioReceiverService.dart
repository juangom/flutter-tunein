







import 'dart:async';

import 'package:audioplayer/audioplayer.dart';

class AudioReceiverService{
  AudioPlayer _audioPlayer = AudioPlayer();
  List<StreamSubscription> _audioPositionSub = new List();
  List<StreamSubscription> _audioStateChangeSub = new List();
  List<StreamSubscription> _audioPlaybkacKeysSub = new List();


  AudioReceiverService();

  Future playSong(String uri){
   return  _audioPlayer.play(uri);
  }

  Future pauseSong(){
    return _audioPlayer.pause();
  }

  Future stopSong(){
    return _audioPlayer.stop();
  }


  Future seek(double seconds){
    return _audioPlayer.seek(seconds);
  }


  onPositionChanges(Function(Duration) callback){
    _audioPositionSub.add(_audioPlayer.onAudioPositionChanged.listen((Duration duration) {
      callback(duration);
    }));
  }

  onStateChanges(Function(String) callback){
    _audioStateChangeSub.add(_audioPlayer.onPlayerStateChanged.listen((AudioPlayerState state) {
      callback(serializeEnums(state));
    }));
  }

  onPlaybackKeys(Function(String) callback){
    _audioPlaybkacKeysSub.add(_audioPlayer.onPlaybackKeyEvent.listen((PlayBackKeys data) {
      callback(serializeEnums(data));
    }));
  }


  closeAllSubs(){
    if(_audioPlaybkacKeysSub!=null)_audioPlaybkacKeysSub.forEach((element) {element.cancel();});
    if(_audioPositionSub!=null)_audioPositionSub.forEach((element) {element.cancel();});
    if(_audioStateChangeSub!=null)_audioStateChangeSub.forEach((element) {element.cancel();});
  }

  serializeEnums(entry){
    return entry.toString();
  }

}