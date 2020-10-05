import 'dart:convert';
import 'dart:io';

import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/utils/MathUtils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_meta_data/flutter_file_meta_data.dart';
import 'package:media_notification/media_notification.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upnp/upnp.dart';
import 'package:Tunein/plugins/upnp.dart' as UPnPPlugin;
import 'package:path/path.dart';


class PluginIsolateFunctions {

  // Temporary attributes

  static Map mapMetaData = Map();


  static fetchMetadataOfAllTracks(List tracks, Function(List) callback) async{
    List _metaData=[];
    for (var track in tracks) {
      var data = await getFileMetaData(track);
      if (data!=null && data[2] != null) {
        if (data[2] is List<int>) {
          var digest = sha1.convert(data[2]).toString();
          writeImage(digest, data[2]);
          data[2] = digest;
          _metaData.add(data);
        } else {
          _metaData.add(data);
        }
      } else {
        _metaData.add(data);
      }
    }
    callback(_metaData);
  }

  static Future getFileMetaData(track) async {

    var value;
    try {
      if (mapMetaData[track] == null) {
        var metaValue = await FlutterFileMetaData.getFileMetaData(track);
        return metaValue;
      } else {
        value = mapMetaData[track];
        return value;
      }
    } catch (e, stack) {

    }

  }


  static Future<String> getLocalPath() async {
    Directory dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<File> getLocalFile() async {
    String path = await getLocalPath();
    return File('$path/filesmetadata.json');
  }

  static Future<File> writeImage(var hash, List<int> image) async {
    String path = await getLocalPath();
    if(hash==null){
      hash = sha1.convert(image).toString();
    }
    File imagefile = File('$path/$hash');
    return imagefile.writeAsBytes(image);
  }



  //Custom Notification controls

  static show({String title, String author, bool play, String image, List<int> BitmapImage, Color titleColor, Color subtitleColor, Color iconColor, Color bigLayoutIconColor, Color bgColor, String bgImage, List<int> bgBitmapImage, Color bgImageBackgroundColor, Function(dynamic) callback}) async{
    MediaNotification.show(
        title: title??"title",
        author: author??"author",
        play: play??true,
        image: image,
        BitmapImage:
        image == null ? BitmapImage : null,
        titleColor: titleColor,
        subtitleColor: subtitleColor,
        iconColor: iconColor,
        bgImage: bgImage,
        bgBitmapImage: bgBitmapImage,
        bgImageBackgroundColor: bgImageBackgroundColor,
        bigLayoutIconColor: bigLayoutIconColor,
        bgColor:bgColor).then((s){
      callback!=null?callback(s):null;
    });
  }

  static Future hide(){
    try{
      return MediaNotification.hide();
    }on PlatformException{
      //
    }
  }
  static setNotificationTimeStamp(String timeStamp) async{
    MediaNotification.setTimestamp(timeStamp);
  }

  static subscribeToPlayButton(Function(dynamic) callback) async{
    MediaNotification.setListener('play', (){
      callback(true);
    });
  }

  static subscribeToNextButton(Function(dynamic) callback) async{
    MediaNotification.setListener('next', (){
      callback(true);
    });
  }

  static subscribeToPrevButton(Function(dynamic) callback) async{
    MediaNotification.setListener('prev', (){
      callback(true);
    });
  }

  static subscribeToSelectButton(Function(dynamic) callback) async{
    MediaNotification.setListener('select', (){
      callback(true);
    });
  }

  static subscribeToPauseButton(Function(dynamic) callback) async{
    MediaNotification.setListener('pause', (){
      callback(true);
    });
  }

  static setNotificationTo(bool value, Function(dynamic) callback) async {
    MediaNotification.setTo(value).then(
            (data){
          callback(data);
        }
    );
  }

  static setNotificationTitle(String value, Function(dynamic) callback) async{
    MediaNotification.setTitle(value).then(
            (data){
          callback(data);
        }
    );
  }

  static setNotificationSubTitle(String value, Function(dynamic) callback) async{
    MediaNotification.setSubtitle(value).then(
            (data){
          callback(data);
        }
    );
  }

  static setNotificationStatusIcon(String value, Function(dynamic) callback) async{
    MediaNotification.setStatusIcon(value).then(
            (data){
          callback(data);
        }
    );
  }

  static toggleNotificationPlayPause(Function(dynamic) callback) async{
    MediaNotification.togglePlayPause().then(
            (data){
          callback(data);
        }
    );
  }


  //SDCARD PERMISSION ACQUIRING


  static getSDCardAndPermissions(Function(dynamic) callback)async{
    MethodChannel platform = MethodChannel('android_app_retain');
    platform.setMethodCallHandler((call) {
      switch(call.method){
        case "resolveWithSDCardUri":{
          if(callback!=null){
            callback(call.arguments);
          }
        }
      }
      return null;
    });
    platform.invokeMethod("getSDCardPermission");

  }


}