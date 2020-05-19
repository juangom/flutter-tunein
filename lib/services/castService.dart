import 'dart:async';
import 'dart:isolate';

import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicServiceIsolate.dart';
import 'package:Tunein/services/platformService.dart';
import 'package:rxdart/rxdart.dart';
import 'package:upnp/upnp.dart';
import 'package:uuid/uuid.dart';
import 'package:Tunein/plugins/upnp.dart' as UpnpPlugin;

enum CastState{
  CASTING,
  NOT_CASTING,
}






class CastService {

  BehaviorSubject<CastState> _castingState;
  BehaviorSubject<PlayerState> _castingPlayerState;
  BehaviorSubject<CastItem> _castItem;
  BehaviorSubject<Duration> _currentPosition;
  BehaviorSubject<Device> _currentDeviceToBeUsed;
  Timer positionTimer;
  Timer castingPlayerStateTimer;
  UpnpPlugin.upnp UpnPPlugin;
  final MusicServiceIsolate = locator<musicServiceIsolate>();
  final platformService = locator<PlatformService>();



  BehaviorSubject<CastItem> get castItem => _castItem;

  BehaviorSubject<CastState> get castingState => _castingState;


  BehaviorSubject<Duration> get currentPosition => _currentPosition;


  BehaviorSubject<Device> get currentDeviceToBeUsed => _currentDeviceToBeUsed;


  BehaviorSubject<PlayerState> get castingPlayerState => _castingPlayerState;

  CastService(){
    _initStreams();
  }


  Future feedCurrentPosition({bool perpetual=true, bool feedState=true}){
    if(perpetual){
      if(positionTimer==null){
        if(_currentDeviceToBeUsed.value!=null){
          positionTimer = Timer.periodic(Duration(seconds: 1), (Timer) async{
            UpnPPlugin.getPositionInfo(service: await UpnPPlugin.getAVTTransportServiceFromDevice(_currentDeviceToBeUsed.value)).then(
                (positionData){
                  String position = positionData["RelTime"];
                  Duration positionInDuration = FormatPositionToDuration(position);
                  if(_currentPosition.value==null || positionInDuration.inSeconds!=_currentPosition.value.inMilliseconds){
                    _currentPosition.add(positionInDuration);
                  }
                }
            );
          });
        }
      }

      if(feedState){
        if(castingPlayerStateTimer==null){
          if(_currentDeviceToBeUsed.value!=null){
            castingPlayerStateTimer = Timer.periodic(Duration(seconds: 1), (Timer) async{
              UpnPPlugin.getTransportInfo(service: await UpnPPlugin.getAVTTransportServiceFromDevice(_currentDeviceToBeUsed.value)).then(
                      (positionData){
                    String state = positionData["CurrentTransportState"];
                    switch(state){
                      case "PLAYING":{
                        _castingPlayerState.value!=PlayerState.playing?_castingPlayerState.add(PlayerState.playing):null;
                        break;
                      }
                      case "PAUSED_PLAYBACK":{
                        _castingPlayerState.value!=PlayerState.paused?_castingPlayerState.add(PlayerState.paused):null;
                        break;
                      }
                      case "STOPPED":{
                        _castingPlayerState.value!=PlayerState.paused?_castingPlayerState.add(PlayerState.paused):null;
                        break;
                      }
                      default:
                        break;
                    }
                  }
              );
            });
          }
        }
      }
    }
  }

  stopFeedingCurrentPosition(){
    if(positionTimer!=null){
      positionTimer.cancel();
      positionTimer=null;
    }
    if(castingPlayerStateTimer!=null){
      castingPlayerStateTimer.cancel();
      castingPlayerStateTimer=null;
    }
  }

  Future<List<Device>> searchForDevices() async{
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage(
        sender: tempPort.sendPort,
        command: "searchForCastDevices",
        message: ""
    ));

    List<Device> deviceList =[];
    await  tempPort.forEach((data){
      print(data);
      if(data!="OK"){
        tempPort.close();
        deviceList =data;
      }
    });

    return deviceList;
  }

  Future castAndPlay(Tune songToCast)async {
    if(_castingState.value==CastState.CASTING){
      await registerSongForServing(songToCast);
      if(songToCast.albumArt!=null){
        await registerArtForService("art${songToCast.id}",songToCast.albumArt);
      }
      String currentIP = await platformService.getCurrentIP();
      String newURI = "http://${currentIP}:8089/file/?fileID=${songToCast.id}.mp3";
      print(newURI);
      String newArtURI = "http://${currentIP}:8089/file/?fileID=art${songToCast.id}.jpg";
      CastItem newItemToCast = CastItem(uri: newURI, name: songToCast.title.toString(), coverArtUri: songToCast.albumArt!=null?newArtURI:null, id: songToCast.id);

      Device currentDev = _currentDeviceToBeUsed.value;
      UpnPPlugin.setCurrentURI(service: await currentDev.getService("urn:schemas-upnp-org:service:AVTransport:1"),
          uri: newItemToCast.uri,
          Objectclass: "object.item.audioItem",
          creator: songToCast.artist,
          title: newItemToCast.name,
          coverArt: songToCast.albumArt!=null?newArtURI:null,
          ID: songToCast.id,
          parentID: "Parent${songToCast.id}"
      ).then((data){
        play();
        _castItem.add(newItemToCast);
        return;
      });

    }
  }


  Future stopCasting() async{
     await UpnPPlugin.stopCurrentMedia(service: await UpnPPlugin.getAVTTransportServiceFromDevice(_currentDeviceToBeUsed.value));
     _castingState.add(CastState.NOT_CASTING);
     stopFeedingCurrentPosition();
     return;
  }


  Future stopCurrentMedia() async{
    await UpnPPlugin.stopCurrentMedia(service: await UpnPPlugin.getAVTTransportServiceFromDevice(_currentDeviceToBeUsed.value));
    return;
  }


  Future<dynamic> registerSongForServing(Tune song)async{
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage(
        sender: tempPort.sendPort,
        command: "registerAFileToBeServed",
        message: MapEntry(song.id,MapEntry(song.uri, "audio/mpeg"))
    ));

    return tempPort.forEach((dataAlbums){
      if(dataAlbums==true){
        tempPort.close();
        return true;
      }
    });
  }

  Future<dynamic> registerArtForService(String id, String uri)async{
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage(
        sender: tempPort.sendPort,
        command: "registerAFileToBeServed",
        message: MapEntry(id,MapEntry(uri,"image/jpeg"))
    ));

    return tempPort.forEach((dataAlbums){
      if(dataAlbums==true){
        tempPort.close();
        return true;
      }
    });
  }

  Future pauseCasting() async{
    await UpnPPlugin.pauseCurrentMedia(service: await UpnPPlugin.getAVTTransportServiceFromDevice(_currentDeviceToBeUsed.value));
    return;
  }

  Future play()async {
    await UpnPPlugin.playCurrentMedia(service: await UpnPPlugin.getAVTTransportServiceFromDevice(_currentDeviceToBeUsed.value));
    return;
  }

  Future seek(Duration durationToSeekTo) async{
    await UpnPPlugin.seekPostion(service: await UpnPPlugin.getAVTTransportServiceFromDevice(_currentDeviceToBeUsed.value), position: DurationToFormatPosition(durationToSeekTo));
    return;
  }


  void resumePlay(Tune songToBeCasted) async{
    if(_castingState.value==CastState.CASTING){
      play();
    }else{
      castAndPlay(songToBeCasted);
    }
  }


  setCastingState(CastState state){
    _castingState.add(state);
  }

  void setDeviceToBeUsed(Device dev){
    _currentDeviceToBeUsed.add(dev);
  }


  ///[position] must be in format hh:mm:ss
  FormatPositionToDuration(String position){
    List<String> splitChronos = position.split(":");
    int seconds = (int.parse(splitChronos[0])*(60*60))+(int.parse(splitChronos[1])*60)+(int.parse(splitChronos[2]));
    return Duration(seconds: seconds);
  }


  String DurationToFormatPosition(Duration duration){
    return duration.toString().split('.')[0];
  }


  _initStreams(){
    UpnPPlugin= UpnpPlugin.upnp();
    _castingState = BehaviorSubject<CastState>.seeded(CastState.NOT_CASTING);
    _castItem = BehaviorSubject<CastItem>.seeded(null);
    _currentPosition = BehaviorSubject<Duration>.seeded(null);
    _castingPlayerState= BehaviorSubject<PlayerState>.seeded(null);
    _currentDeviceToBeUsed = BehaviorSubject<Device>.seeded(null);
  }



  void dispose() {
    _castItem.close();
    _castingState.close();
  }
}




class CastItem {
  String name;
  String id;
  String uri;
  String coverArtUri;
  Duration duration;

  CastItem({this.name="Unnamed", this.id, this.uri, this.coverArtUri}){
   if(this.id==null){
     this.id = Uuid().v1();
   }
  }


}