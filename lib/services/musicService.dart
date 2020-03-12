import 'dart:async';
import 'dart:io';

import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playback.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/themeService.dart';
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

class MusicService {
  BehaviorSubject<List<Tune>> _songs$;
  BehaviorSubject<List<Playlist>> _playlists$;
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

  StreamSubscription _audioPositionSub;
  StreamSubscription _audioStateChangeSub;

  MusicService() {
    _defaultSong = Tune(null, " ", " ", " ", null, null, null, []);
    _initStreams();
    _initAudioPlayer();
  }

  Future<void> fetchSongs() async {
    await _nano.fetchSongs().then(
      (data) {
        _songs$.add(data);
      },
    );
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
      print(data.value.albumArt);
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
          print("shoudl pause");
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
    Map<String, Album> albums = {};
    int currentIndex = 0;
    List<Tune> ItemsList = _songs$.value;
    ItemsList.forEach((Tune tune) {
      if (albums["${tune.album}${tune.artist}"] != null) {
        albums["${tune.album}${tune.artist}"].songs.add(tune);
      } else {
        albums["${tune.album}${tune.artist}"] =
            new Album(currentIndex, tune.album, tune.artist, tune.albumArt);
        albums["${tune.album}${tune.artist}"].songs.add(tune);
        currentIndex++;
      }
    });
    List<Album> newAlbumList = albums.values.toList();
    newAlbumList.sort((a, b) {
      if (a.title == null || b.title == null) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    _albums$.add(newAlbumList);
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

  Future<void> fetchArtists() async {
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

  void playMusic(Tune song) async {
    _audioPlayer.play(song.uri);
    updatePlayerState(PlayerState.playing, song);
  }

  void pauseMusic(Tune song) async {
    _audioPlayer.pause();
    updatePlayerState(PlayerState.paused, song);
  }

  void stopMusic() {
    _audioPlayer.stop();
  }

  void updatePlayerState(PlayerState state, Tune song) async {
    _playerState$.add(MapEntry(state, song));
    themeService.updateTheme(song);
  }

  void updatePosition(Duration duration) {
    _position$.add(duration);
  }

  void updatePlaylist(List<Tune> normalPlaylist) {
    List<Tune> _shufflePlaylist = []..addAll(normalPlaylist);
    _shufflePlaylist.shuffle();
    _playlist$.add(MapEntry(normalPlaylist, _shufflePlaylist));
  }

  void playNextSong() {
    if (_playerState$.value.key == PlayerState.stopped) {
      return;
    }
    final Tune _currentSong = _playerState$.value.value;
    final bool _isShuffle = _playback$.value.contains(Playback.shuffle);
    final List<Tune> _playlist =
        _isShuffle ? _playlist$.value.value : _playlist$.value.key;
    int _index = _playlist.indexOf(_currentSong);
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
    return _playlist.indexOf(song);
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

  MapEntry<Tune, Tune> getNextPrevSong(Tune _currentSong) {
    final bool _isShuffle = _playback$.value.contains(Playback.shuffle);
    final List<Tune> _playlist =
        _isShuffle ? _playlist$.value.value : _playlist$.value.key;
    int _index = _playlist.indexOf(_currentSong);
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
    int _index = _playlist.indexOf(_currentSong);
    if (_index == 0) {
      _index = _playlist.length - 1;
    } else {
      _index--;
    }
    stopMusic();
    playMusic(_playlist[_index]);
  }

  void _playSameSong() {
    final Tune _currentSong = _playerState$.value.value;
    stopMusic();
    playMusic(_currentSong);
  }

  void _onSongComplete() {
    final List<Playback> _playback = _playback$.value;
    print(_playback);
    if (_playback.contains(Playback.repeatSong)) {
      _playSameSong();
      return;
    }
    playNextSong();
  }

  void audioSeek(double seconds) {
    _audioPlayer.seek(seconds);
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

  void updatePlayback(Playback playback) {
    List<Playback> _value = playback$.value;
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
    List<String> _encodedStrings = [];
    for (Tune song in _songs) {
      _encodedStrings.add(_encodeSongToJson(song));
    }
    _prefs.setStringList("tunes", _encodedStrings);
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
    print("favorites : ${_favorites}");
    _favorites$.add(_favorites);
  }

  String _encodeSongToJson(Tune song) {
    final _songMap = songToMap(song);
    final data = json.encode(_songMap);
    return data;
  }

  Tune _decodeSongFromJson(String ecodedSong) {
    final _songMap = json.decode(ecodedSong);
    final Tune _song = Tune.fromMap(_songMap);
    return _song;
  }

  Playlist _decodePlaylistFromJson(String ecodedSong) {
    final _playlistMap = json.decode(ecodedSong);
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
        updatePosition(duration);
      }
    });

    //This will synchronize the playing states of
    _audioStateChangeSub =
        _audioPlayer.onPlayerStateChanged.listen((AudioPlayerState state) {
      if (state == AudioPlayerState.COMPLETED) {
        _onSongComplete();
        print("stopp state out should go to next song");
      }
      if (state == AudioPlayerState.PAUSED) {
        print("paused");
        //MediaNotification.setTo(false);
        updatePlayerState(PlayerState.paused, _playerState$.value.value);
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
    _position$.close();
    _playback$.close();
    _favorites$.close();
    _audioPositionSub.cancel();
    _audioStateChangeSub.cancel();
  }
}
