


import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/fileService.dart';
import 'package:Tunein/services/locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class ConversionUtils{

  static final FileService = locator<fileService>();
  static String DurationToFancyText(Duration duration, {showHours=true, showMinutes=true, showSeconds=true}){
    assert(duration!=null, "duration argument can't be null");
    String finalText ="";
    if(showHours && duration.inHours!=0){
      finalText+="${duration.inHours} hours";
    }
    if(showMinutes && duration.inMinutes.remainder(60)!=0){
      finalText+="${duration.inMinutes.remainder(60)} min ";
    }
    if(showSeconds && duration.inSeconds.remainder(60)!=0){
      finalText+="${duration.inSeconds.remainder(60)} sec";
    }

    return finalText;
  }


  static Future<List<int>> FileUriTo8Bit(String uri, {File fileInstead}) async{
    assert(uri!=null || fileInstead!=null, "one of uri and file needs to be supplied");
    if(fileInstead!=null){
      assert(fileInstead.existsSync(),"File Not Found");
      return fileInstead.readAsBytesSync();
    }else{
     return await FileService.readFile(uri,readAsBytes: true);
    }
  }


  static Future<Uint8List> fromWidgetGlobalKeyToImageByteList(GlobalKey widgetlobalKey) async{
    assert(widgetlobalKey!=null,"You can't pass a null global key");
    RenderRepaintBoundary boundary = widgetlobalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  }


  static double songListToDuration(List<Tune> songs){
    double FinalDuration = 0;

    songs.forEach((elem) {
      FinalDuration += elem.duration;
    });

    return FinalDuration;
  }
}