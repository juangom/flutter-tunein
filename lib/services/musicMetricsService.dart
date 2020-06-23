import 'dart:convert';

import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum MetricIds{
  MET_GLOBAL_PLAY_TIME,
  MET_GLOBAL_SONG_PLAY_TIME,
  MET_GLOBAL_ARTIST_PLAY_TIME,
  MET_GLOBAL_LAST_PLAYED_SONGS,
  MET_GLOBAL_LAST_PLAYED_PLAYLIST,
  MET_GLOBAL_PLAYLIST_PLAY_TIME
}



class MusicMetricsService {

  BehaviorSubject<Map<MetricIds,dynamic>> _metrics;


  BehaviorSubject<Map<MetricIds, dynamic>> get metrics => _metrics;

  MusicMetricsService(){
    _initStreams();
  }

  _initStreams(){
    _metrics = BehaviorSubject<Map<MetricIds,dynamic>>.seeded(Map());
  }


  setLastPlayedPlaylist(Playlist playlist){
    //A null Last played playlist means that the last song that was played was not part of a playlist
    updateSingleSetting(MetricIds.MET_GLOBAL_LAST_PLAYED_PLAYLIST,
        playlist!=null?Playlist.toMap(playlist):null);
  }


  incrementPlaylistPlaytimeOnSinglePlaylist(Playlist playlist, Duration durationToAdd)async {
    if(durationToAdd!=null){
      return;
    }
    Map<String,dynamic> PlayedTimeOnAllPlaylists = getCurrentMemoryMetric(MetricIds.MET_GLOBAL_PLAYLIST_PLAY_TIME);
    if(PlayedTimeOnAllPlaylists[playlist.id]!=null){
      int numericValueOfSong = int.parse(PlayedTimeOnAllPlaylists[playlist.id]);
      numericValueOfSong+=durationToAdd.inSeconds;
      PlayedTimeOnAllPlaylists[playlist.id]=numericValueOfSong.toString();
      updateSingleSetting(MetricIds.MET_GLOBAL_PLAYLIST_PLAY_TIME, PlayedTimeOnAllPlaylists);
    }else{
      PlayedTimeOnAllPlaylists[playlist.id]= durationToAdd.inSeconds.toString();
      updateSingleSetting(MetricIds.MET_GLOBAL_PLAYLIST_PLAY_TIME, PlayedTimeOnAllPlaylists);
    }
  }

  void addSongToLatestPlayedSongs(Tune song){
    List<Tune> existingList = getCurrentMemoryMetric(MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS);
    if(existingList.length==10){
      existingList.removeLast();
    }
    existingList.add(song);
    updateSingleSetting(MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS, existingList);
  }


  void incrementPlayTimeOnSingleSong(Tune song, Duration durationToAdd) async{
    if(song!=null && durationToAdd!=null){
      String currentGlobalTimeValue= getCurrentMemoryMetric(MetricIds.MET_GLOBAL_PLAY_TIME).toString();
      int numericValueOfGlobalPlayTime = int.parse(currentGlobalTimeValue);
      numericValueOfGlobalPlayTime+= durationToAdd.inSeconds;
      updateSingleSetting(MetricIds.MET_GLOBAL_PLAY_TIME,numericValueOfGlobalPlayTime);

      Map<String,dynamic> PlayedTimeOnAllSongs = getCurrentMemoryMetric(MetricIds.MET_GLOBAL_SONG_PLAY_TIME);
      if(PlayedTimeOnAllSongs[song.id]!=null){
        int numericValueOfSong = int.parse(PlayedTimeOnAllSongs[song.id]);
        numericValueOfSong+=durationToAdd.inSeconds;
        PlayedTimeOnAllSongs[song.id]=numericValueOfSong.toString();
        updateSingleSetting(MetricIds.MET_GLOBAL_SONG_PLAY_TIME, PlayedTimeOnAllSongs);
      }else{
        PlayedTimeOnAllSongs[song.id]= durationToAdd.inSeconds.toString();
        updateSingleSetting(MetricIds.MET_GLOBAL_SONG_PLAY_TIME, PlayedTimeOnAllSongs);
      }
    }
  }


  void incrementPlayTimeOnSingleArtist(Artist artist, Duration durationToAdd) async{
    if(artist!=null && durationToAdd!=null){
      Map<String,dynamic> PlayedTimeOnAllArtists = getCurrentMemoryMetric(MetricIds.MET_GLOBAL_ARTIST_PLAY_TIME);
      if(PlayedTimeOnAllArtists[artist.id]!=null){
        int numericValueOfSong = int.parse(PlayedTimeOnAllArtists[artist.id]);
        numericValueOfSong+=durationToAdd.inSeconds;
        PlayedTimeOnAllArtists[artist.id.toString()]=numericValueOfSong.toString();
        updateSingleSetting(MetricIds.MET_GLOBAL_ARTIST_PLAY_TIME, PlayedTimeOnAllArtists);
      }else{
        PlayedTimeOnAllArtists[artist.id.toString()]= durationToAdd.inSeconds.toString();
        updateSingleSetting(MetricIds.MET_GLOBAL_ARTIST_PLAY_TIME, PlayedTimeOnAllArtists);
      }
    }
  }

  void incrementGlobalPlayTime(Duration durationToAdd) async{
    if(durationToAdd!=null){
      String currentGlobalTimeValue= getCurrentMemoryMetric(MetricIds.MET_GLOBAL_PLAY_TIME).toString();
      int numericValueOfGlobalPlayTime = int.parse(currentGlobalTimeValue);
      numericValueOfGlobalPlayTime+= durationToAdd.inSeconds;
      updateSingleSetting(MetricIds.MET_GLOBAL_PLAY_TIME,
          numericValueOfGlobalPlayTime);

    }
  }



  //Basic Functions
  Future fetchAllMetrics() async{
    Map<MetricIds, dynamic> metricsMap = new Map();
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    try{
      MetricIds.values.toList().forEach((setting){
        dynamic storedSettingValue;
        switch(getMetricStorageTye(setting)){
          case String:{
            storedSettingValue = _prefs.getString(getEnumValue(setting).toString());
            break;
          }
          case List:{
            storedSettingValue = _prefs.getStringList(getEnumValue(setting).toString());
            break;
          }
        }
        if(storedSettingValue==null){
          metricsMap[setting] = getDefaultSetting(setting);
        }else{
          metricsMap[setting] = convertFromStorage(setting,storedSettingValue);
        }

      });
      _metrics.add(metricsMap);
    }catch (e){
      print(e);
      return false;
    }

  }


  fetchSingleMetric(MetricIds metricId)async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    try{
      Map<MetricIds, dynamic> metricsMap = _metrics.value;
      metricsMap[metricId]= convertFromStorage(metricId,_prefs.getString(getEnumValue(metricId).toString()));
      _metrics.add(metricsMap);
    }catch (e){
      print("Error in fetching metric ${e}");
      return false;
    }
  }


  getCurrentMemoryMetric(MetricIds setting){
    return _metrics.value[setting];
  }



  Future updateSingleSetting(MetricIds metricId, dynamic value) async{
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    try{
      Map<MetricIds, dynamic> metricssMap = _metrics.value;
      dynamic valueToAdd = convertToStorage(metricId,value);
      if(valueToAdd is List){
        await _prefs.setStringList(getEnumValue(metricId).toString(),convertToStorage(metricId,value));
      }else{
        await _prefs.setString(getEnumValue(metricId).toString(),convertToStorage(metricId,value));
      }
      metricssMap[metricId]= value;
      _metrics.add(metricssMap);
      return true;
    }catch (e){
      print(e.stackTrace);
      print("Error in saving setting ${e}");
      return false;
    }
  }


  //Utils

  //will return the default setting for each settingID
  getDefaultSetting(MetricIds metricId){
    switch(metricId){
      case MetricIds.MET_GLOBAL_PLAY_TIME:
        return "0";
        break;
      case MetricIds.MET_GLOBAL_SONG_PLAY_TIME:
        return Map<String,String>();
        break;
      case MetricIds.MET_GLOBAL_ARTIST_PLAY_TIME:
        return Map<String,String>();
        break;
      case MetricIds.MET_GLOBAL_PLAYLIST_PLAY_TIME:
        return Map<String,String>();
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS:
        return List<Tune>();
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_PLAYLIST:
        return null;
        break;
      default:
        return null;
        break;
    }
  }


  getMetricStorageTye(MetricIds metricId){
    switch(metricId){
      case MetricIds.MET_GLOBAL_PLAY_TIME:
        return String;
        break;
      case MetricIds.MET_GLOBAL_SONG_PLAY_TIME:
        return String;
        break;
      case MetricIds.MET_GLOBAL_ARTIST_PLAY_TIME:
        return String;
        break;
      case MetricIds.MET_GLOBAL_PLAYLIST_PLAY_TIME:
        return String;
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS:
        return List;
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_PLAYLIST:
        return String;
        break;
      default:
        return String;
        break;
    }
  }


  convertFromStorage(MetricIds metricId, dynamic value){
    if(value==null){
      return null;
    }
    switch(metricId){
      case MetricIds.MET_GLOBAL_PLAY_TIME:
        return value.toString();
        break;
      case MetricIds.MET_GLOBAL_SONG_PLAY_TIME:
        return json.decode(value);
        break;
      case MetricIds.MET_GLOBAL_ARTIST_PLAY_TIME:
        return json.decode(value);
        break;
      case MetricIds.MET_GLOBAL_PLAYLIST_PLAY_TIME:
        return json.decode(value);
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS:
        return decodeSongListFromJson(value);
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_PLAYLIST:
        return Playlist.fromMap(json.decode(value));
        break;
      default:
        return value.toString();
        break;
    }
  }


  convertToStorage(MetricIds metricId, dynamic value){
    if(value==null){
      return null;
    }
    switch(metricId){
      case MetricIds.MET_GLOBAL_PLAY_TIME:
        return value.toString();
        break;
      case MetricIds.MET_GLOBAL_SONG_PLAY_TIME:
        return json.encode(value);
        break;
      case MetricIds.MET_GLOBAL_ARTIST_PLAY_TIME:
        return json.encode(value);
        break;
      case MetricIds.MET_GLOBAL_PLAYLIST_PLAY_TIME:
        return json.encode(value);
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS:
        return encodeSongListToJson(value);
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_PLAYLIST:
        return json.encode(value);
        break;
      default:
        return value.toString();
        break;
    }
  }

  String getEnumValue(MetricIds set){
    return set.toString().split('.').last;
  }
  ///TODO This should be changed in a lot of cases to a isolate call
  ///It is Already set up to be used multiple times;
  decodeSongListFromJson(List<String> jsonStringList){
      List<Tune> finalList=List();

      jsonStringList.forEach((elem){
        finalList.add(Tune.fromMap(json.decode(elem)));
      });

      return finalList;
  }


  ///TODO This should be changed in a lot of cases to a isolate call
  ///It is Already set up to be used multiple times;
  List<String> encodeSongListToJson(List<Tune> songList){
    List<String> JSONString=List();

    songList.forEach((elem){
      JSONString.add(json.encode(elem.toMap()));
    });

    return JSONString;
  }

  void dispose() {
    _metrics.close();
  }
}