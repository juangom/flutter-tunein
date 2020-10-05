


import 'dart:isolate';

import 'package:Tunein/services/isolates/musicServiceIsolate.dart';
import 'package:Tunein/services/locator.dart';
import 'package:flutter/cupertino.dart';

class MessagingUtils {


  static Future sendNewIsolateCommand({@required String command,  message=""}){
    musicServiceIsolate MusicServiceIsolate = locator<musicServiceIsolate>();
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossPluginIsolatesMessage(CrossIsolatesMessage<dynamic>(
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

  static Future sendNewStandardIsolateCommand({@required String command,  message=""}){
    musicServiceIsolate MusicServiceIsolate = locator<musicServiceIsolate>();
    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage<dynamic>(
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
}