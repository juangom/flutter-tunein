


import 'dart:io';

import 'package:Tunein/services/fileService.dart';
import 'package:Tunein/services/locator.dart';

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
}