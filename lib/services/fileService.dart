


import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:Tunein/services/locator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Tunein/services/musicServiceIsolate.dart';
import 'package:rxdart/rxdart.dart';
class fileService{



  Future<File> getFileFromURI(String uri, {bool mustExist}) async{
    if(uri==null) return null;
    File newFile = File(uri);
    if(mustExist){
      if(newFile.existsSync()){
        return newFile;
      }else{
        return null;
      }
    }

    return newFile;
  }

  deleteFile(String uri) async{
    File fileToBeDeleted = await getFileFromURI(uri,mustExist: true);
    if(fileToBeDeleted!=null){
      fileToBeDeleted.deleteSync();
    }
    return;
  }

  createFile(String fileName) async{
    final path = await _localPath;
    return File('$path/$fileName}');
  }

  saveFile(File fileToBeSaved, String data, {bool writeBytes, List<int> bytesToWrite}) async{
    if(fileToBeSaved!=null){
      if(fileToBeSaved.existsSync()){
        if(writeBytes){
          fileToBeSaved.writeAsBytesSync(bytesToWrite);
        }else{
          fileToBeSaved.writeAsStringSync(data);
        }
      }
    }
  }


  dynamic readFile(uri, {bool readAsBytes}) async{
    File fileToBeRead = await getFileFromURI(uri,mustExist: true);
    if(fileToBeRead!=null){
      if(readAsBytes){
        return fileToBeRead.readAsBytesSync();
      }else{
        return fileToBeRead.readAsStringSync();
      }
    }else{
      return null;
    }
  }


  Future<dynamic> saveBytesToFile(Uint8List FileBytes) async {
    ReceivePort tempPort = ReceivePort();
    var MusicServiceIsolate = locator<musicServiceIsolate>();
    MusicServiceIsolate.sendCrossPluginIsolatesMessage(CrossIsolatesMessage<List>(
        sender: tempPort.sendPort,
        command: "writeImage",
        message: FileBytes
    ));


    BehaviorSubject<dynamic> stream = new BehaviorSubject<dynamic>();
    tempPort.forEach((fileURI){
      if(fileURI!="OK"){
        print("file got from the isolate : ${fileURI}");
        stream.add(fileURI);
        tempPort.close();
      }else{
        //wait
      }
    });
    return stream.first;
  }




  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }
}