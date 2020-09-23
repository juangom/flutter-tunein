


import 'dart:convert';
import 'dart:io';

import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/utils/MathUtils.dart';
import 'package:upnp/upnp.dart';
import 'package:Tunein/plugins/upnp.dart' as UPnPPlugin;
import 'package:path/path.dart';


class StandardIsolateFunctions{

  static searchForCastingDevices(Function(List<Device>) callback) async{
    try{
      UPnPPlugin.upnp instance = UPnPPlugin.upnp();
      List<Device> devices = await instance.getDevices();
      print("found ${devices.length} devices");
      callback(devices);
    }catch(e){
      print(e);
      print(e.stack);
    }

  }

  static readExtDir(Directory dir, Function(String) callback) async {
    Stream<FileSystemEntity> sdContents = dir.list(recursive: true);
    sdContents = sdContents.handleError((data) {});
    await for (var data in sdContents) {
      if (data.path.endsWith(".mp3")) {
        if(validateMusicFile(data.path)){
          callback(data.path);
        };
      }
    }
    callback("0001");
  }

  static bool validateMusicFile(String path){
    String filename = basename(path);
    if(filename.startsWith(new RegExp(r'([_.\-\!\?])'))){
      return false;
    }
    return true;
  }

  static saveSongsToPref(List<Tune> songs, Function(List<String>) callback) async{
    List<String> _encodedStrings = [];
    for (Tune song in songs) {
      _encodedStrings.add(_encodeSongToJson(song));
    }
    print("encoded ${_encodedStrings.length} songs");
    callback(_encodedStrings);
  }

  static String _encodeSongToJson(Tune song) {
    final _songMap = song.toMap();
    final data = json.encode(_songMap);
    return data;
  }


  static fetchAlbumFromsongs(List<Tune> songs, Function(List<Album>) callback) async{
    Map<String, Album> albums = {};
    int currentIndex = 0;
    songs.forEach((Tune tune) {
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
    newAlbumList.forEach((album){
      album.songs.sort((a,b){
        if(a.numberInAlbum ==null || b.numberInAlbum==null) return 1;
        if(a.numberInAlbum < b.numberInAlbum) return -1;
        else return 1;
      });
    });
    newAlbumList.sort((a, b) {
      if (a.title == null || b.title == null) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    callback(newAlbumList);
  }

  //encoding artists to save in prefs in the main isolate

  static saveArtiststoPref(List<Artist> artists, Function(List<String>) callback) async{
    List<String> _encodedStrings = [];
    for (Artist artist in artists) {
      _encodedStrings.add(_encodeArtistToJson(artist));
    }
    print("encoded ${_encodedStrings.length} artist");
    callback(_encodedStrings);
  }

  static String _encodeArtistToJson(Artist artist) {
    final _ArtistMap = artist.toMap(artist);
    final data = json.encode(_ArtistMap);
    return data;
  }


  //Landing page methods

  /// Will return a list of TopAlbums sorted from top to bottom
  static Map getTopAlbum(Map<String,dynamic> GlobalSongPlayTime, Map<int, Album> albums, Map<String,Tune> songs, Function(Map) callback){

    Map<String,dynamic> newValue = GlobalSongPlayTime;
    if(GlobalSongPlayTime.length==0){
      return null;
    }
    Map<String,int> playTime = Map();
    var sortedKeys = newValue.keys.toList(growable:false)
      ..sort((k1, k2) => int.parse(newValue[k2]).compareTo(int.parse(newValue[k1])));
    Map<String,String> sortedMap = new Map
        .fromIterable(sortedKeys, key: (k) => k, value: (k) => newValue[k]);

    Map<Tune,int> newSongMap = sortedMap.map((key, value) {
      Tune newKey = songs[key];
      return MapEntry(newKey, int.tryParse(value));
    });
    List<Album> topAlbums = newSongMap.keys.map((e) {
      if(e==null) return null;

      Album albumFound = albums.values.firstWhere((element) => (element.title==e.album && element.artist==e.artist));
      if(newSongMap[e]!=0){
        if(playTime[albumFound.id.toString()]==null){
          playTime[albumFound.id.toString()] = newSongMap[e];
        }else{
          playTime[albumFound.id.toString()] +=newSongMap[e];
        }

      };
      return albumFound;
    }).toList();

    topAlbums = topAlbums.toSet().toList();
    topAlbums.removeWhere((element) => element==null || element.title==null);
    Map<String, Duration> playDuration = playTime.map((k1,V1){
      return MapEntry(k1,Duration(seconds: V1));
    });
    if(callback !=null){
      callback({
        "topAlbums":topAlbums,
        "playDuration":playDuration
      });
    }
  }

  ///
  static Map<String,dynamic> getMostPlayedSongs(Map<String,dynamic> metricValues, Map<int, Artist> artists, Map<String,Tune> songs, Function(Map) callback){

    Map<String,dynamic> newValue = metricValues;
    if(newValue.length==0){
      return null;
    }
    var sortedKeys = newValue.keys.toList(growable:false)
      ..sort((k1, k2) => int.parse(newValue[k2]).compareTo(int.parse(newValue[k1])));
    Map<String,String> sortedMap = new Map
        .fromIterable(sortedKeys, key: (k) => k, value: (k) => newValue[k]);
    Map<String, int> playDuration = Map();
    Map<Tune,int> newSongMap = sortedMap.map((key, value) {
      Tune newKey = songs[key];
      return MapEntry(newKey, int.tryParse(value));
    });

    Map<String, int> artistsAndTheirPresenceInMostPlayed = Map();
    List<Artist> topArtists=List();
    newSongMap.keys.toList().forEach((element) {
      if(element!=null)
        artistsAndTheirPresenceInMostPlayed[element.artist]=artistsAndTheirPresenceInMostPlayed[element.artist]!=null?artistsAndTheirPresenceInMostPlayed[element.artist]++:1;

      playDuration[element.artist] =newSongMap[element];
    });
    if(newSongMap.length<10){
      //picking a random song to add to fill the 10 songs mark
      //picking will be done from the artists in the existing songs with a coefficient based on the number of songs in the most played
      for(int i=0; i < 10-newSongMap.length; i++){

        //Sorting the presenceMap
        var sortedPresenceKeys = newValue.keys.toList(growable:false)
          ..sort((v1, v2) => newValue[v2].compareTo(newValue[v1]));
        Map<String,int> sortedPresenceMap = new Map
            .fromIterable(sortedPresenceKeys, key: (k) => k, value: (k) => int.parse(newValue[k]));

        //Picking the artist with the lowest priority without having too many songs from same artist
        int indexOfArtistWithPriority =0;
        String nameOfArtistsToPickFrom = sortedPresenceMap.keys.toList()[indexOfArtistWithPriority];
        while(sortedPresenceMap[nameOfArtistsToPickFrom]<2 && indexOfArtistWithPriority< sortedPresenceMap.keys.toList().length){
          nameOfArtistsToPickFrom = sortedPresenceMap.keys.toList()[indexOfArtistWithPriority];
          indexOfArtistWithPriority++;
        }
        Artist artistToPickFrom = artists.values.firstWhere((element) => element.name==nameOfArtistsToPickFrom, orElse: ()=>null);
        if(artistToPickFrom==null){
          continue;
        }

        //Tis will pick random numbers from the albums length and then from the songs length and add them use them as indexes to get random songs to add.
        int albumIndex = MathUtils.getRandomFromRange(0, artistToPickFrom.albums.length);
        int songIndex = MathUtils.getRandomFromRange(0, artistToPickFrom.albums[albumIndex].songs.length);
        while(newSongMap.keys.toList().firstWhere((element) => element.id==artistToPickFrom.albums[albumIndex].songs[songIndex].id, orElse: ()=>null)!=null){
          songIndex = MathUtils.getRandomFromRange(0, artistToPickFrom.albums[albumIndex].songs.length);
        }

        newSongMap[artistToPickFrom.albums[albumIndex].songs[songIndex]] = newSongMap.values.toList().last;
        artistsAndTheirPresenceInMostPlayed[artistToPickFrom.name]++;
        playDuration[artistToPickFrom.name] =0;
        topArtists.add(artistToPickFrom);
      }
    }

    List<Artist> notTopArtists = artists.entries.where((element) {
      return !topArtists.map((e) => e.id).contains(element.key);
    }).map((e) => e.value).toList();
    List<int> randomIndexList = List();
    for(int i=0; i<4; i++){
      randomIndexList.add(MathUtils.getRandomFromRange(0, notTopArtists.length));
    }
    List<Artist> discoverableArtists = randomIndexList.map((e) => notTopArtists[e]).toList();

    //Deleting null objects if found
    List<Tune> mostPlayedSongsToReturn = newSongMap.keys.toList();
    mostPlayedSongsToReturn.removeWhere((element) => element==null);



    if(callback!=null){
      callback( {
        "artistsPresence" : artistsAndTheirPresenceInMostPlayed,
        "mostPlayedSongs" : mostPlayedSongsToReturn,
        "discoverableArtists" : discoverableArtists,
        "playDuration" : playDuration,
      });
    }

  }

  }