







import 'dart:async';

import 'package:audioplayer/audioplayer.dart';

class AudioReceiverService{
  AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription _audioPositionSub;
  StreamSubscription _audioStateChangeSub;
  StreamSubscription _audioPlaybkacKeysSub;


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
    if(_audioPositionSub==null){
      _audioPositionSub =
          _audioPlayer.onAudioPositionChanged.listen((Duration duration) {
            callback(duration);
          });
    }
  }

  onStateChanges(Function(String) callback){
   if(_audioStateChangeSub==null){
     _audioStateChangeSub =
         _audioPlayer.onPlayerStateChanged.listen((AudioPlayerState state) {
           callback(serializeEnums(state));
         });
   }
  }

  onPlaybackKeys(Function(String) callback){
    if(_audioPlaybkacKeysSub==null){
      _audioPlaybkacKeysSub =
          _audioPlayer.onPlaybackKeyEvent.listen((PlayBackKeys data) {
            callback(serializeEnums(data));
          });
    }
  }


  closeAllSubs(){
    if(_audioPlaybkacKeysSub!=null)_audioPlaybkacKeysSub.cancel();
    if(_audioPositionSub!=null)_audioPositionSub.cancel();
    if(_audioStateChangeSub!=null)_audioStateChangeSub.cancel();
  }

  serializeEnums(entry){
    return entry.toString();
  }

}