import 'dart:convert';

import 'package:Tunein/plugins/nano.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum MetricIds{
  MET_GLOBAL_PLAY_TIME,
  MET_GLOBAL_SONG_PLAY_TIME,
  MET_GLOBAL_LAST_PLAYED_SONGS
}



class MusicMetricsService {

  BehaviorSubject<Map<MetricIds,dynamic>> _metrics;

  MusicMetricsService(){
    _initStreams();
  }

  _initStreams(){
    _metrics = BehaviorSubject<Map<MetricIds,dynamic>>.seeded(Map());
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
  fetchAllMetrics() async{
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
      print(metricsMap);
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
      print(metricsMap);
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
      case MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS:
        return List<Tune>();
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
      case MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS:
        return List;
        break;
      default:
        return String;
        break;
    }
  }


  convertFromStorage(MetricIds metricId, dynamic value){
    switch(metricId){
      case MetricIds.MET_GLOBAL_PLAY_TIME:
        return value.toString();
        break;
      case MetricIds.MET_GLOBAL_SONG_PLAY_TIME:
        return json.decode(value);
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS:
        return decodeSongListFromJson(value);
        break;
      default:
        return value.toString();
        break;
    }
  }


  convertToStorage(MetricIds metricId, dynamic value){
    switch(metricId){
      case MetricIds.MET_GLOBAL_PLAY_TIME:
        return value.toString();
        break;
      case MetricIds.MET_GLOBAL_SONG_PLAY_TIME:
        return json.encode(value);
        break;
      case MetricIds.MET_GLOBAL_LAST_PLAYED_SONGS:
        return encodeSongListToJson(value);
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