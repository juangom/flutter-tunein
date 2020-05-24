import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playback.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/castService.dart';
import 'package:Tunein/services/http/requests.dart';
import 'package:Tunein/services/http/utilsRequests.dart';
import 'package:Tunein/services/musicMetricsService.dart';
import 'package:Tunein/services/musicServiceIsolate.dart';
import 'package:Tunein/services/queueService.dart';
import 'package:Tunein/services/settingService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_notification/media_notification.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'locator.dart';
final themeService = locator<ThemeService>();
final MusicServiceIsolate = locator<musicServiceIsolate>();
final RequestSettings = locator<Requests>();
final utilsRequests = locator<UtilsRequests>();
final queueService = locator<QueueService>();
final SettingsService = locator<settingService>();
final metricService = locator<MusicMetricsService>();
final castService = locator<CastService>();

class MusicService {
  BehaviorSubject<List<Tune>> _songs$;
  BehaviorSubject<List<Playlist>> _playlists$;
  BehaviorSubject<MapEntry<PlayerState,Playlist>> _currentPlayingPlaylist$;


  BehaviorSubject<List<Album>> _albums$;
  BehaviorSubject<List<Artist>> _artists$;
  BehaviorSubject<MapEntry<PlayerState, Tune>> _playerState$;
  BehaviorSubject<MapEntry<List<Tune>, List<Tune>>>
      _playlist$; //key is normal, value is shuffle
  BehaviorSubject<Duration> _position$;
  BehaviorSubject<List<Playback>> _playback$;
  BehaviorSubject<List<Tune>> _favorites$;
  BehaviorSubject<bool> _isAudioSeeking$;
  AudioPlayer _audioPlayer;
  Nano _nano;
  Tune _defaultSong;

  BehaviorSubject<List<Tune>> get songs$ => _songs$;

  BehaviorSubject<List<Album>> get albums$ => _albums$;

  BehaviorSubject<List<Artist>> get artists$ => _artists$;

  BehaviorSubject<MapEntry<PlayerState, Tune>> get playerState$ =>
      _playerState$;

  BehaviorSubject<Duration> get position$ => _position$;

  BehaviorSubject<List<Playback>> get playback$ => _playback$;

  BehaviorSubject<List<Tune>> get favorites$ => _favorites$;

  BehaviorSubject<MapEntry<List<Tune>, List<Tune>>> get playlist$ => _playlist$;
  BehaviorSubject<List<Playlist>> get playlists$ => _playlists$;
  BehaviorSubject<
      MapEntry<PlayerState, Playlist>> get currentPlayingPlaylist$ =>
      _currentPlayingPlaylist$;

  StreamSubscription _audioPositionSub;
  StreamSubscription _audioStateChangeSub;
  StreamSubscription _upnpPositionSubscription;
  StreamSubscription _upnpPlayerStateSubscription;
  StreamSubscription _upnpOnSongCompleteSubscription;


  MusicService() {
    _defaultSong = Tune(null, " ", " ", " ", null, null, null, [], null);
    _initStreams();
    _initAudioPlayer();
  }

  Future<void> fetchSongs() async {
    var data = await _nano.fetchSongs();
    for(int i = 0; i < data.length; i++) {
      data[i].colors = await themeService.getThemeColors(data[i]);
    }
    _songs$.add(data);
  }

  showUI() async {
    ByteData dibd = await rootBundle.load("images/cover.png");
    List<int> defaultImageBytes = dibd.buffer.asUint8List();
    //AudioService.connect();
    MediaNotification.show(
        title: 'No song',
        author: 'no Author',
        play: false,
        image: null,
        BitmapImage: defaultImageBytes,
        iconColor: Colors.white,
        titleColor: Colors.white,
        subtitleColor: Colors.white.withAlpha(50),
        bgColor: MyTheme.darkBlack);

    _playerState$.listen((data) async {
      List<int> SongColors = await themeService.getThemeColors(data.value);
      switch (data.key) {

        ///Playing status means that it is a new song and it needs to load its new content like colors and image
        ///in other cases it will be just stopping the player or pausing it requiring no change in content data
        case PlayerState.playing:
          MediaNotification.show(
              title: '${data.value.title}',
              author: '${data.value.artist}',
              play: true,
              image: data.value.albumArt,
              BitmapImage:
                  data.value.albumArt == null ? defaultImageBytes : null,
              titleColor: Color(SongColors[1]),
              subtitleColor: Color(SongColors[1]).withAlpha(50),
              iconColor: Color(SongColors[1]),
              bgColor: Color(SongColors[0]));
          break;
        case PlayerState.paused:
          MediaNotification.setTo(false);
          break;
        case PlayerState.stopped:
          MediaNotification.setTo(false);
          break;
      }
    });
    MediaNotification.setListener('play', () {
      if (_playerState$.value.value != null) {
        print("playing shoud slart");
        print("${_playerState$.value.key}");
        playMusic(_playerState$.value.value);
      }
    });

    MediaNotification.setListener('pause', () {
      if (_playerState$.value.value != null) {
        print("pausing shoud slart");
        print("${_playerState$.value.key}");
        pauseMusic(_playerState$.value.value);
      }
    });

    MediaNotification.setListener('next', () {
      print("next shoud slart");
      print("${_playerState$.value.key}");
      if (_playerState$.value.value != null) {
        playNextSong();
      }
    });

    MediaNotification.setListener('prev', () {
      if (_playerState$.value.value != null) {
        print("${_playerState$.value.key}");
        playPreviousSong();
      }
    });

    MediaNotification.setListener('select', () {
      print("selectedd");
    });
  }

  hideUI() {
    //AudioService.disconnect();
    MediaNotification.hide();
  }

  Future<void> fetchAlbums() async {
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage(
        sender: tempPort.sendPort,
        command: "fetchAlbumsFromSongs",
        message: _songs$.value
    ));
    return tempPort.forEach((dataAlbums){
      if(dataAlbums!="OK"){
        _albums$.add(dataAlbums);
        tempPort.close();
        return true;
      }
    });

  }

  BehaviorSubject<List<Album>> fetchAlbum(
      {String title, int id, String artist}) {
    if (artist == null && id == null && title == null) {
      return BehaviorSubject<List<Album>>();
    } else {
      List<Album> albums = _albums$.value.toList();

      List<Album> finalAlbums = albums.where((elem) {
        bool finalDecision = true;
        if (title != null) {
          finalDecision = finalDecision && (elem.title == title);
        }
        if (id != null) {
          finalDecision = finalDecision && (elem.id == id);
        }
        if (artist != null) {
          finalDecision = finalDecision && (elem.artist == artist);
        }
        return finalDecision;
      }).toList();
      return BehaviorSubject<List<Album>>.seeded(finalAlbums);
    }
  }

  Future<List> fetchArtists() async {
    Map<String, Artist> artists = {};
    int currentIndex = 0;
    List<Album> ItemsList = _albums$.value;
    ItemsList.forEach((Album album) {
      if (artists["${album.artist}"] != null) {
        artists["${album.artist}"].albums.add(album);
      } else {
        artists["${album.artist}"] =
            new Artist(currentIndex, album.artist, null);
        artists["${album.artist}"].albums.add(album);
        currentIndex++;
      }
    });
    List<Artist> newAlbumList = artists.values.toList();
    newAlbumList.sort((a, b) {
      if (a.name == null || b.name == null) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    _artists$.add(newAlbumList);
  }


  ///This will initialize the playing stream like position and playerState
  ///
  /// This is used after a cast is stopped by the user
  void initializePlayStreams(){
    if(_upnpPositionSubscription!=null){
      _upnpPositionSubscription.cancel();
      _upnpPositionSubscription=null;
      //Initialize the local duration too
      _position$.add(Duration(milliseconds: 0));
    }

    if(_upnpPlayerStateSubscription!=null){
      _upnpPlayerStateSubscription.cancel();
      _upnpPlayerStateSubscription=null;
      //Initialize the local duration too
      _position$.add(Duration(milliseconds: 0));
      playerState$.add(MapEntry(PlayerState.paused,playerState$.value.value));
    }

    if(_upnpOnSongCompleteSubscription!=null){
      _upnpOnSongCompleteSubscription.cancel();
      _upnpOnSongCompleteSubscription=null;
    }

    if(_upnpOnSongCompleteSubscription!=null){
      _upnpOnSongCompleteSubscription.cancel();
      _upnpOnSongCompleteSubscription=null;
    }
  }

  ///This will be called when a playing is already going and needs to stop playing
  ///And reset the duration and player state
  void reInitializePlayStreams(){
    _position$.add(Duration(milliseconds: 0));
    playerState$.add(MapEntry(PlayerState.paused,playerState$.value.value));

    if(_upnpPositionSubscription==null){
      //This will tie the current position on the casting device to the local position so
      //that the ui updates correctly
      _upnpPositionSubscription = castService.currentPosition.listen((data){
        updatePosition(data);
      });
    }

    if(_upnpPlayerStateSubscription ==null){
      _upnpPlayerStateSubscription= castService.castingPlayerState.listen((data){
        MapEntry<PlayerState,Tune> playerstate =playerState$.value;
        if(playerstate!=null){
          if(playerstate.value.id!=null){
            if(playerstate.key!=data){
              if(data!=null && data==PlayerState.stopped){
                playerState$.add(MapEntry(PlayerState.paused,playerstate.value));
              }else{
                playerState$.add(MapEntry(data,playerstate.value));
              }

            }
          }
        }
      });
    }

    if(_upnpOnSongCompleteSubscription==null){
      _upnpOnSongCompleteSubscription = Rx.combineLatest2(castService.castingPlayerState, castService.currentPosition, (a,b)=>MapEntry<PlayerState,Duration>(a,b))
          .listen(( data){
            print(data);
        if(data!=null){
          if(data.key!=null && data.value!=null){
            if((data.key==PlayerState.stopped) && (data.value.inMilliseconds==playerState$.value.value.duration)){
              if(castService.castingState.value==CastState.CASTING){
                print("must call songComplete now");
                //The player is paused and the song has ended
                //If we are still casting
                //we need to call the onSongComplete method
                //_onSongComplete();
              }
            }
          }
        }
      });
    }
  }



  void playMusic(Tune song, {bool isPartOfAPlaylist=false, Playlist playlist}) async {

    if(castService.castingState.value==CastState.CASTING){
      //If this is true the play should play on the cast device
      //get the current casting item
      CastItem currentCastingItem = castService.castItem.value;
      if(currentCastingItem!=null){
        if(currentCastingItem.id == song.id){
          castService.play();
        }else{
          castService.castAndPlay(song);
        }
      }else{
        castService.castAndPlay(song);
      }
      castService.feedCurrentPosition();
    }else{
      //The stream subscription for the position should be initialized here and canceled if it is running since we will
      //refresh it everytime we play to the casting device
      initializePlayStreams();
      //playing the song if it is a local play
      _audioPlayer.play(song.uri);
    }




    //********************************************************************************************************//
    //********************// ON PLAY METRICS // **************************************************************//
    //********************************************************************************************************//

    //If this song is part of a playlist and it is going to play that, we need to set it as the last Played Playlist

    if(isPartOfAPlaylist){
      metricService.setLastPlayedPlaylist(playlist);
    }

    //before switching the playState to the new song we need to save the metrics of the previous song
    //Metrics are counted when casting to other devices for convenience (for now)
    //May change TODO Add a setting options for Metrics to be counted when casting or Not
    MapEntry<PlayerState, Tune> playerstate= playerState$.value;
    if(playerstate!=null){
      if(playerstate.value!=null && playerstate.value.id!=null){
        metricService.incrementPlayTimeOnSingleSong(playerstate.value, position$.value);
        //Setting the playlist Time
        if(_currentPlayingPlaylist$.value.value!=null && _currentPlayingPlaylist$.value.value.songs.indexWhere((elem){
          return elem.id==playerstate.value.id;
        })!=-1){
          metricService.incrementPlaylistPlaytimeOnSinglePlaylist(_currentPlayingPlaylist$.value.value, position$.value);
        }
      }
    }


    //adding the toBePlayedSong to the latestPlayed songs
    metricService.addSongToLatestPlayedSongs(song);


    if(_currentPlayingPlaylist$.value.value!=null && _currentPlayingPlaylist$.value.value.songs.indexWhere((elem){
      return elem.id==song.id;
    })==-1){
      updatePlaylistState(PlayerState.stopped, null);
      metricService.setLastPlayedPlaylist(null);
    }else{
      //If the song is part of a playlist and a current playlist is being played
    }
    print("dsds");
    print(song.id);
    updatePlayerState(PlayerState.playing, song);

  }

  void pauseMusic(Tune song) async {
    if(castService.castingState.value==CastState.CASTING){
      //If this is true the pause command should be issued to the casting device
      castService.pauseCasting();

    }else{
      //pause the song if it is a local play
      _audioPlayer.pause();
    }


    if(_currentPlayingPlaylist$.value.value!=null && _currentPlayingPlaylist$.value.value.songs.indexWhere((elem){
      return elem.id==song.id;
    })==-1){
      updatePlaylistState(PlayerState.stopped, null);
    }
    updatePlayerState(PlayerState.paused, song);
  }

  void stopMusic() {
    if(castService.castingState.value==CastState.CASTING){
      //stop the current media running on the cast device
      castService.stopCurrentMedia();
      updatePlayerState(PlayerState.paused, playerState$.value.value);
    }else{
      //pause the song if it is a local play
      _audioPlayer.stop();
      updatePlayerState(PlayerState.paused, playerState$.value.value);
    }

  }

  //This was introduced to eliminate useless subscriptions to the playerState stream
  void playOrPause(Tune song) async {
    PlayerState _state = _playerState$.value.key;
    final Tune _currentSong = _playerState$.value.value;
    final bool _isSelectedSong =
        _currentSong.id == song.id;
    switch (_state) {
      case PlayerState.playing:
        if (_isSelectedSong) {
          pauseMusic(_currentSong);
        } else {
          stopMusic();
          playMusic(
            song,
          );
        }
        break;
      case PlayerState.paused:
        if (_isSelectedSong) {
          playMusic(song);
        } else {
          stopMusic();
          playMusic(
            song,
          );
        }
        break;
      case PlayerState.stopped:
        playMusic(song);
        break;
      default:
        break;
    }
  }

  void updatePlayerState(PlayerState state, Tune song) async {
 /*   CrossIsolatesMessage newMessage = new CrossIsolatesMessage<MapEntry<PlayerState,Tune>>(
      message: MapEntry(state,song),
      sender: null,
      command: "UPlayerstate"
    );
    MusicServiceIsolate.sendCrossIsolateMessage(newMessage).then((data){
      print(data);
    });*/
    if(!(_playerState$.value.key== state && playerState$.value.value.id == song.id)){
      _playerState$.add(MapEntry(state, song));
      themeService.updateTheme(song);
    }
  }

  void updatePosition(Duration duration) {
    _position$.add(duration);
  }

  void updatePlaylist(List<Tune> normalPlaylist) {
    List<Tune> _shufflePlaylist = []..addAll(normalPlaylist);
    _shufflePlaylist.shuffle();
    _playlist$.add(MapEntry(normalPlaylist, _shufflePlaylist));
  }

  void updatePlaylistState(PlayerState state, Playlist playlist){
    _currentPlayingPlaylist$.add(MapEntry(state,playlist));
  }

  void playNextSong() {
    if (_playerState$.value.key == PlayerState.stopped) {
      return;
    }
    final Tune _currentSong = _playerState$.value.value;
    final bool _isShuffle = _playback$.value.contains(Playback.shuffle);
    final List<Tune> _playlist =
        _isShuffle ? _playlist$.value.value : _playlist$.value.key;
    int _index = _playlist.indexWhere((elem)=>elem.id ==_currentSong.id);
    if (_index == _playlist.length - 1) {
      _index = 0;
    } else {
      _index++;
    }
    stopMusic();
    playMusic(_playlist[_index]);
  }

  int getSongIndex(song) {
    final bool _isShuffle = _playback$.value.contains(Playback.shuffle);
    final List<Tune> _playlist =
        _isShuffle ? _playlist$.value.value : _playlist$.value.key;
    return _playlist.indexWhere((elem)=>elem.id==song.id);
  }

  /// specific song card actions
  ///
  ///

  void playOne(Tune song) {
    stopMusic();
    playMusic(song);
    updatePlaylist([song]);
  }

  void startWithAndShuffleQueue(Tune song, List<Tune> queue) {
    stopMusic();
    updatePlaylist(queue);
    updatePlayback(Playback.shuffle);
    List<Tune> newqueue = _playlist$.value.value;
    newqueue.remove(song);
    newqueue.insert(0, song);
    _playlist$.add(MapEntry(_playlist$.value.key, newqueue));
    Future.delayed(Duration(milliseconds: 100), () {
      playMusic(song);
    });
  }

  void startWithAndShuffleAlbum(Tune song) {
    stopMusic();
    playMusic(song);
    Album album;
    album = _albums$.value.where((elem) {
      return ((song.album == elem.title) && (song.artist == elem.artist));
    }).toList()[0];
    updatePlaylist(album.songs);
    updatePlayback(Playback.shuffle);
    List<Tune> newqueue = _playlist$.value.value;
    newqueue.remove(song);
    newqueue.insert(0, song);
    _playlist$.add(MapEntry(_playlist$.value.key, newqueue));
  }

  void playAlbum(Tune song) {
    Album album;
    album = _albums$.value.where((elem) {
      return ((song.album == elem.title) && (song.artist == elem.artist));
    }).toList()[0];
    updatePlaylist(album.songs);
    stopMusic();
    playMusic(song);
  }



  ///Specific artist context menu functions
  ///
  ///

  void playAllArtistAlbums(Artist artist){
    List<Tune> artistAlbumsSongs = [];

    artist.albums.forEach((album){
      artistAlbumsSongs.addAll(album.songs);
    });

    if(artistAlbumsSongs.length!=0){
      stopMusic();
      updatePlaylist(artistAlbumsSongs);
      playMusic(artistAlbumsSongs[0]);
    }
  }
  void suffleAllArtistAlbums(Artist artist){
    List<Tune> artistAlbumsSongs = [];

    artist.albums.forEach((album){
      artistAlbumsSongs.addAll(album.songs);
    });

    if(artistAlbumsSongs.length!=0){
      stopMusic();
      updatePlaylist(artistAlbumsSongs);
      updatePlayback(Playback.shuffle);
      List<Tune> newqueue = _playlist$.value.value;
      playMusic(newqueue[0]);
    }
  }


  ///Artist More choices functions
  ///

  void playMostPlayedOfArtist(Artist artist, {shuffle=false}){
    List<Tune> finalList=getMostPlayedOfArtist(artist);

    if(finalList.length>0){

      if(shuffle){
        updatePlaylist(finalList);
        updatePlayback(Playback.shuffle);
        List<Tune> newqueue = _playlist$.value.value;
        playMusic(newqueue[0]);
      }else{
        updatePlaylist(finalList);
        stopMusic();
        playMusic(finalList[0]);
      }

    }

  }


  List<Tune> getMostPlayedOfArtist(Artist artist, {maxSongNumber=11}){
    Map<String,dynamic> mostPlayedSongs = metricService.getCurrentMemoryMetric(MetricIds.MET_GLOBAL_SONG_PLAY_TIME);
    List<MapEntry<Tune,String>> playlistSongs =[];
    List<Tune> finalList=[];
    artist.albums.forEach((album){
      album.songs.forEach((song){
        String songMetric = mostPlayedSongs[song.id];
        if(songMetric!=null){
          playlistSongs.add(MapEntry(song,songMetric));
        }
      });
    });

    playlistSongs.sort((a,b){
      return int.parse(a.value.toString()).compareTo(int.parse(b.value.toString()));
    });

    if(playlistSongs.length>maxSongNumber){
      playlistSongs.removeRange(maxSongNumber, playlistSongs.length);
    }

    playlistSongs.forEach((elem){
      finalList.add(elem.key);
    });

    return finalList;
  }

  void playMostPlayedOfAlbum(Album album, {shuffle=false}){
    List<Tune> finalList=getMostPlayedOfAlbum(album);
    if(finalList.length>0){

      if(shuffle){
        updatePlaylist(finalList);
        updatePlayback(Playback.shuffle);
        List<Tune> newqueue = _playlist$.value.value;
        playMusic(newqueue[0]);
      }else{
        updatePlaylist(finalList);
        stopMusic();
        playMusic(finalList[0]);
      }

    }

  }


  List<Tune> getMostPlayedOfAlbum(Album album, {maxSongNumber=11}){
    Map<String,dynamic> mostPlayedSongs = metricService.getCurrentMemoryMetric(MetricIds.MET_GLOBAL_SONG_PLAY_TIME);
    List<MapEntry<Tune,String>> playlistSongs =[];
    List<Tune> finalList=[];
    album.songs.forEach((song){
      String songMetric = mostPlayedSongs[song.id];
      if(songMetric!=null){
        playlistSongs.add(MapEntry(song,songMetric));
      }
    });
    playlistSongs.sort((a,b){
      return int.parse(a.value.toString()).compareTo(int.parse(b.value.toString()));
    });

    if(playlistSongs.length>11){
      playlistSongs.removeRange(11, playlistSongs.length);
    }

    playlistSongs.forEach((elem){
      finalList.add(elem.key);
    });

    return finalList;
  }


  MapEntry<Tune, Tune> getNextPrevSong(Tune _currentSong) {
    final bool _isShuffle = _playback$.value.contains(Playback.shuffle);

    final List<Tune> _playlist =
        _isShuffle ? _playlist$.value.value : _playlist$.value.key;
    int _index = _playlist.indexWhere((elem){
      return elem.id==_currentSong.id;
    });
    int nextSongIndex = _index + 1;
    int prevSongIndex = _index - 1;

    if (_index == _playlist.length - 1) {
      nextSongIndex = 0;
    }
    if (_index == 0) {
      prevSongIndex = _playlist.length - 1;
    }
    Tune nextSong = _playlist[nextSongIndex];
    Tune prevSong = _playlist[prevSongIndex];
    return MapEntry(nextSong, prevSong);
  }

  void playPreviousSong() {
    if (_playerState$.value.key == PlayerState.stopped) {
      return;
    }
    final Tune _currentSong = _playerState$.value.value;
    final bool _isShuffle = _playback$.value.contains(Playback.shuffle);
    final List<Tune> _playlist =
        _isShuffle ? _playlist$.value.value : _playlist$.value.key;
    int _index = _playlist.indexWhere((elem)=>elem.id ==_currentSong.id);
    if (_index == 0) {
      _index = _playlist.length - 1;
    } else {
      _index--;
    }
    stopMusic();
    playMusic(_playlist[_index]);
  }



  void cycleBetweenPlaybackStates(){
    List<Playback> _playbackList= _playback$.value;
    if(_playbackList.contains(Playback.repeatQueue)){
      _playbackList.remove(Playback.repeatQueue);
      _playbackList.add(Playback.repeatSong);
      updatePlaybackList(_playbackList);
      return;
    }

    if(_playback$.value.contains(Playback.repeatSong)){
      _playbackList.remove(Playback.repeatSong);
      updatePlaybackList(_playbackList);
      return;
    }

    if((!_playback$.value.contains(Playback.repeatSong)) && (!_playback$.value.contains(Playback.repeatQueue))){
      _playbackList.add(Playback.repeatQueue);
      updatePlaybackList(_playbackList);
      return;
    }
  }

  void _playSameSong() {
    final Tune _currentSong = _playerState$.value.value;
    stopMusic();
    playMusic(_currentSong);
  }

  void _onSongComplete() {
    final List<Playback> _playback = _playback$.value;
    if (_playback.contains(Playback.repeatSong)) {
      _playSameSong();
      return;
    }
    if(_playback.contains(Playback.repeatQueue)){
      //PlayNextSong will check for the queue ending and would repeat it automatically
      playNextSong();
      return;
    }
    if(!_playback.contains(Playback.repeatQueue) && !_playback.contains(Playback.repeatSong)){
      final Tune _currentSong = _playerState$.value.value;
      final bool _isShuffle = _playback$.value.contains(Playback.shuffle);
      final List<Tune> _playlist =
      _isShuffle ? _playlist$.value.value : _playlist$.value.key;
      int _index = _playlist.indexWhere((elem)=>elem.id ==_currentSong.id);
      if (_index == _playlist.length - 1) {
        stopMusic();
        updatePlayerState(playerState$.value.key, _playlist[0]);
        updatePosition(Duration(milliseconds: 0));
        return;
      }
    }
    playNextSong();
  }

  void audioSeek(double seconds) {
    if(castService.castingState.value==CastState.CASTING){
      //If this is true the seeking command should be issued to the casting device
      castService.seek(Duration(seconds: seconds.floor()));

    }else{
      //seek the song if it is a local play
      _audioPlayer.seek(seconds);
    }

  }

  void addToFavorites(Tune song) async {
    List<Tune> _favorites = _favorites$.value;
    _favorites.add(song);
    _favorites$.add(_favorites);
    await saveFavorites();
  }

  void removeFromFavorites(Tune _song) async {
    List<Tune> _favorites = _favorites$.value;
    final int index = _favorites.indexWhere((song) => song.id == _song.id);
    _favorites.removeAt(index);
    _favorites$.add(_favorites);
    await saveFavorites();
  }

  void invertSeekingState() {
    final _value = _isAudioSeeking$.value;
    _isAudioSeeking$.add(!_value);
  }

  void updatePlayback(Playback playback, {bool removeIfExistent=false}) {
    List<Playback> _value = playback$.value;
    if(_value.contains(playback)){
      if(removeIfExistent){
        removePlayback(playback);
      }
      return;
    }
    if (playback == Playback.shuffle) {
      final List<Tune> _normalPlaylist = _playlist$.value.key;
      updatePlaylist(_normalPlaylist);
    }
    _value.add(playback);
    _playback$.add(_value);
  }

  void removePlayback(Playback playback) {
    List<Playback> _value = playback$.value;
    _value.remove(playback);
    _playback$.add(_value);
  }

  updatePlaybackList(List<Playback> playbacks){
    _playback$.add(playbacks);
  }


  Future<void> saveFavorites() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final List<Tune> _favorites = _favorites$.value;
    List<String> _encodedStrings = [];
    for (Tune song in _favorites) {
      _encodedStrings.add(_encodeSongToJson(song));
    }
    _prefs.setStringList("favoritetunes", _encodedStrings);
  }

  Future<void> saveFiles() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final List<Tune> _songs = _songs$.value;
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage(
        sender: tempPort.sendPort,
        command: "encodeSongsToStringList",
        message: _songs
    ));
    /*List<String> _encodedStrings = [];
    for (Tune song in _songs) {
      _encodedStrings.add(_encodeSongToJson(song));
    }*/
    return tempPort.forEach((data){
      if(data!="OK"){
        _prefs.setStringList("tunes", data);
        tempPort.close();
      }
    });

  }

  Future<void> saveArtists() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final List<Artist> _artists = _artists$.value;
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage(
        sender: tempPort.sendPort,
        command: "encodeArtistsToStringList",
        message: _artists
    ));
    /*List<String> _encodedStrings = [];
    for (Tune song in _artists) {
      _encodedStrings.add(_encodeSongToJson(song));
    }*/
    return tempPort.forEach((data){
      if(data!="OK"){
        _prefs.setStringList("artists", data);
        tempPort.close();
      }
    });

  }

  Future<bool> getArtistDataAndSaveIt() async{
    if(SettingsService.settings$.value[SettingsIds.SET_ARTIST_THUMB_UPDATE]=="true"){
      if(_artists$.value.length!=0){
        List<Artist> artists = _artists$.value;
        artists.forEach((elem){
          if(elem.coverArt==null){
            queueService.addItemsToQueue(QueueItem(
                name: "item ${elem.id}",
                execute: () async{
                  //If the settings are changed after the queu is started this condition would account for that
                  if(SettingsService.settings$.value[SettingsIds.SET_ARTIST_THUMB_UPDATE]=="true"){
                    Artist artist = await artistThumbRetreival(elem);
                    List<int> colors = await themeService.getArtistColors(artist);
                    elem.colors=colors;
                    _artists$.add(artists);
                    await saveArtists();
                  }else{
                    //Stop the queue
                    queueService.stopQueue();
                  }
                  return true;
                }
            ));
          }
        });
        return queueService.startQueue();
      }else{
        print("artist list is empty");
        return false;
      }
    }else{
      print("artist Thumb fetch is disabled");
    }

  }

  Future<Artist> artistThumbRetreival(Artist artist) async{
    //print("gone get thumb for artist ${artist.name}");
    Map data = await RequestSettings.getDiscogArtistData(artist);
    //This condition means that the artist doesn't have a discogID set up already,
    // here we should save the Discog ID with the artist, this should be done elsewhere !!
    if(data !=null && data["id"]!=null && artist.apiData["discogID"]==null){
      artist.apiData["discogID"]= data["id"].toString();
    }

    if(data !=null && data["images"]!=null && data["images"].length!=0){
      //print(data["images"]);
      List<dynamic> dataImages = (data["images"]);
      Map imagetOUserMap = dataImages.firstWhere((item){
        return item["type"]=="primary";
      },
        orElse: (){
          print("can't find thumb");
        }
      );
      if(imagetOUserMap!=null){
        String imagetOUser="";
        String ThumbQualitySetting = SettingsService.getCurrentMemorySetting(SettingsIds.SET_DISCOG_THUMB_QUALITY);

        switch(ThumbQualitySetting){
          case "Low":{
            imagetOUser= imagetOUserMap["uri150"];
            break;
          }
          case "Medium":{
            imagetOUser= imagetOUserMap["uri150"];
            break;
          }
          case "High":{
            imagetOUser= imagetOUserMap["uri"];
            break;
          }
        }

        List<int> imageBytes = await utilsRequests.getNetworkImage(imagetOUser);
        var digest = sha1.convert(imageBytes).toString();
        await _nano.writeImage(digest, imageBytes);
        var albumArt = _nano.getImage(await _nano.getLocalPath(),digest);
        artist.coverArt =  albumArt;
      }
    }
    return artist;
  }

  Future<List<Artist>> retrieveArtists() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<String> _savedStrings = _prefs.getStringList("artists") ?? [];
    List<Artist> _artists = [];

    for (String data in _savedStrings) {
      final Artist artist = _decodeArtistFromJson(data);
      _artists.add(artist);
    }
    _artists$.add(_artists);
    return _artists$.value;
  }

  Future<List<Tune>> retrieveFiles() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<String> _savedStrings = _prefs.getStringList("tunes") ?? [];
    List<Tune> _songs = [];

    for (String data in _savedStrings) {
      final Tune song = _decodeSongFromJson(data);
      _songs.add(song);
    }
    _songs$.add(_songs);
    return _songs$.value;
  }

  Future<List<Playlist>> retrievePlaylists() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<String> _savedStrings = _prefs.getStringList("playlists") ?? [];
    List<Playlist> _playLists = [];

    for (String data in _savedStrings) {
      final Playlist song = _decodePlaylistFromJson(data);
      _playLists.add(song);
    }
    _playlists$.add(_playLists);
    return _playlists$.value;
  }


  Future<bool> addPlaylist(Playlist playlist) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<Playlist> _playlists = _playlists$.value;
    _playlists.add(playlist);
    _playlists$.add(_playlists);
    List<String> _encodedStrings = [];
    for (Playlist pl in _playlists) {
      _encodedStrings.add(_encodePlaylistToJson(pl));
    }
    try{
      await _prefs.setStringList("playlists", _encodedStrings);
    }catch (e){
      return false;
    }
    return true;
  }

  Future<bool> updateSongPlaylist(Playlist playlist) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    int _singlePlaylistIndex = _playlists$.value.indexWhere((pl){
      return pl.id==playlist.id;
    });
    List<Playlist> newPlaylist = _playlists$.value;
    newPlaylist[_singlePlaylistIndex]= playlist;
    _playlists$.add(newPlaylist);
    List<String> _encodedStrings = [];
    for (Playlist pl in newPlaylist) {
      _encodedStrings.add(_encodePlaylistToJson(pl));
    }
    try{
      await _prefs.setStringList("playlists", _encodedStrings);
    }catch (e){
      return false;
    }
    return true;
  }

  Future<bool> deleteAPlaylist(Playlist playlist) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    int _singlePlaylistIndex = _playlists$.value.indexWhere((pl){
      return pl.id==playlist.id;
    });
    List<Playlist> newPlaylist = _playlists$.value;
    newPlaylist.removeAt(_singlePlaylistIndex);
    _playlists$.add(newPlaylist);
    List<String> _encodedStrings = [];
    for (Playlist pl in newPlaylist) {
      _encodedStrings.add(_encodePlaylistToJson(pl));
    }
    try{
      await _prefs.setStringList("playlists", _encodedStrings);
    }catch (e){
      return false;
    }
    return true;
  }

  void retrieveFavorites() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final List<Tune> _fetchedSongs = _songs$.value;
    List<String> _savedStrings = _prefs.getStringList("favoritetunes") ?? [];
    List<Tune> _favorites = [];
    for (String data in _savedStrings) {
      final Tune song = _decodeSongPlusFromJson(data);
      for (var fetchedSong in _fetchedSongs) {
        if (song.id == fetchedSong.id) {
          _favorites.add(song);
        }
      }
    }
    _favorites$.add(_favorites);
  }

  static String _encodeSongToJson(Tune song) {
    final _songMap = song.toMap();
    final data = json.encode(_songMap);
    return data;
  }

  Tune _decodeSongFromJson(String ecodedSong) {
    final _songMap = json.decode(ecodedSong);
    final Tune _song = Tune.fromMap(_songMap);
    return _song;
  }

  Artist _decodeArtistFromJson(String ecodedSong) {
    final _artistMap = json.decode(ecodedSong);
    final Artist _artist = Artist.fromMap(_artistMap);
    return _artist;
  }

  Playlist _decodePlaylistFromJson(String ecodedPlaylist) {
    final _playlistMap = json.decode(ecodedPlaylist);
    final Playlist _playlist = Playlist.fromMap(_playlistMap);
    return _playlist;
  }

  String _encodePlaylistToJson(Playlist playlist) {
    final _songMap = Playlist.toMap(playlist);
    final data = json.encode(_songMap);
    return data;
  }

  Tune _decodeSongPlusFromJson(String ecodedSong) {
    final _songMap = json.decode(ecodedSong);
    final Tune _song = Tune.fromMap(_songMap);
    return _song;
  }

  Map<String, dynamic> songToMap(Tune song) {
    Map<String, dynamic> _map = {};
    _map["album"] = song.album;
    _map["id"] = song.id;
    _map["artist"] = song.artist;
    _map["title"] = song.title;
    _map["duration"] = song.duration;
    _map["uri"] = song.uri;
    _map["albumArt"] = song.albumArt;
    _map["colors"] = song.colors;
    return _map;
  }


  void _initStreams() {
    _nano = Nano();
    _isAudioSeeking$ = BehaviorSubject<bool>.seeded(false);
    _songs$ = BehaviorSubject<List<Tune>>();
    _albums$ = BehaviorSubject<List<Album>>();
    _artists$ = BehaviorSubject<List<Artist>>();
    _position$ = BehaviorSubject<Duration>();
    _playlist$ = BehaviorSubject<MapEntry<List<Tune>, List<Tune>>>();
    _playlists$ = BehaviorSubject<List<Playlist>>();
    _currentPlayingPlaylist$ = BehaviorSubject<MapEntry<PlayerState, Playlist>>.seeded(MapEntry(PlayerState.stopped,null));
    _playback$ = BehaviorSubject<List<Playback>>.seeded([]);
    _favorites$ = BehaviorSubject<List<Tune>>.seeded([]);
    _playerState$ = BehaviorSubject<MapEntry<PlayerState, Tune>>.seeded(
      MapEntry(
        PlayerState.stopped,
        _defaultSong,
      ),
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _audioPositionSub =
        _audioPlayer.onAudioPositionChanged.listen((Duration duration) {
      final bool _isAudioSeeking = _isAudioSeeking$.value;
      if (!_isAudioSeeking) {
        if(!(castService.castingState.value==CastState.CASTING)){
          updatePosition(duration);
        }
      }
    });

    //This will synchronize the playing states of
    _audioStateChangeSub =
        _audioPlayer.onPlayerStateChanged.listen((AudioPlayerState state) {
     if(castService.castingState.value==CastState.NOT_CASTING){
       if (state == AudioPlayerState.COMPLETED) {
         _onSongComplete();
       }
       if (state == AudioPlayerState.PAUSED) {
         //MediaNotification.setTo(false);
         updatePlayerState(PlayerState.paused, _playerState$.value.value);
       }
     }else{
       //if it is casting do nothing for now as everything is being handeled elsewhere
       //TODO This can be the place to handle the position and duration initialisation

     }

    });

    _audioPlayer.onPlaybackKeyEvent.listen((data) {
      print(data);
      switch (data) {
        case PlayBackKeys.PAUSE_KEY:
          updatePlayerState(PlayerState.paused, _playerState$.value.value);
          break;
        case PlayBackKeys.NEXT_KEY:
          playNextSong();
          break;
        case PlayBackKeys.PREV_KEY:
          playPreviousSong();
          break;
        case PlayBackKeys.REWIND_KEY:
          _playSameSong();
          break;
        case PlayBackKeys.STOP_KEY:
          updatePlayerState(PlayerState.stopped, _playerState$.value.value);
          break;
        case PlayBackKeys.SEEK_KEY:
          //Not implemented on part of the plugin yet
          // TODO: Handle this case.
          break;
        case PlayBackKeys.FAST_FORWARD_KEY:
          //Not implemented on part of the plugin yet
          // TODO: Handle this case.
          break;
        case PlayBackKeys.PLAY_KEY:
          updatePlayerState(PlayerState.playing, _playerState$.value.value);
          break;
      }
    });
  }

  void dispose() {
    stopMusic();
    _isAudioSeeking$.close();
    _songs$.close();
    _playerState$.close();
    _playlist$.close();
    _playlists$.close();
    _currentPlayingPlaylist$.close();
    _position$.close();
    _playback$.close();
    _favorites$.close();
    _audioPositionSub.cancel();
    _audioStateChangeSub.cancel();
  }
}
