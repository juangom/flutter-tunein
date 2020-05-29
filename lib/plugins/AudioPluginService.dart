

import 'dart:isolate';

import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicServiceIsolate.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

class AudioPluginService{
  final MusicServiceIsolate = locator<musicServiceIsolate>();


  Future sendNewIsolateCommand({@required String command, String message=""}){
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossPluginIsolatesMessage(CrossIsolatesMessage<String>(
        sender: tempPort.sendPort,
        command: command,
        message: message
    ));
    return tempPort.forEach((data){
      if(data!="OK"){
        tempPort.close();
        return data;
      }
    });
  }


  Future playSong(String uri){
    return sendNewIsolateCommand(command: "playMusic",message: uri);
  }

  Future pauseSong(){
    return sendNewIsolateCommand(command: "pauseMusic");
  }

  Future stopSong(){
    return sendNewIsolateCommand(command: "stopMusic");
  }


  Future seek(double seconds){
    return sendNewIsolateCommand(command: "seekMusic",message: seconds.toString());
  }


  BehaviorSubject<Duration> subscribeToPositionChanges(){
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossPluginIsolatesMessage(CrossIsolatesMessage<String>(
        sender: tempPort.sendPort,
        command: "subscribeToPosition",
        message: ""
    ));

    BehaviorSubject<Duration> returnedSubject= new BehaviorSubject<Duration>.seeded(Duration(milliseconds: 0));
    tempPort.forEach((data){
      if(data!=null && data!="OK"){
        returnedSubject.add(data);
      }
    });

    return returnedSubject;
  }

  BehaviorSubject<AudioPlayerState> subscribeToStateChanges(){
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossPluginIsolatesMessage(CrossIsolatesMessage<String>(
      sender: tempPort.sendPort,
      command: "subscribeToState",
      message: ""
    ));

    BehaviorSubject<AudioPlayerState> returnedSubject= new BehaviorSubject<AudioPlayerState>.seeded(null);
    tempPort.forEach((data){
      if(data!=null && data!="OK"){
        print(data);
        returnedSubject.add(data);
      }
    });

    return returnedSubject;
  }

  BehaviorSubject<PlayBackKeys> subscribeToPlaybackKeys(){
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossPluginIsolatesMessage(CrossIsolatesMessage<String>(
      sender: tempPort.sendPort,
      command: "subscribeToplaybackKeys",
      message: ""
    ));

    BehaviorSubject<PlayBackKeys> returnedSubject= new BehaviorSubject<PlayBackKeys>.seeded(null);
    tempPort.forEach((data){
      if(data!=null && data!="OK"){
        print(data);
        returnedSubject.add(data);
      }
    });

    return returnedSubject;
  }

}