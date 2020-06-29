


import 'dart:io';

import 'package:path_provider/path_provider.dart';

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





  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }
}