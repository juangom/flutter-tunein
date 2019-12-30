import 'package:Tunein/services/themeService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'locator.dart';
import 'package:Tunein/globals.dart';

final themeService = locator<ThemeService>();
class DialogService{

  static showBasicDialog(context,{message}){
    return YYDialog().build(context)
      ..width = 220
      ..height = 500
      ..barrierColor =MyTheme.bgdivider.withOpacity(.3)
      ..animatedFunc = (child, animation) {
        return ScaleTransition(
          child: Text(message),
          scale: Tween(begin: 0.0, end: 1.0).animate(animation),
        );
      }
      ..borderRadius = 4.0
      ..show();
  }
}

class YYDialogType extends YYDialog{}
