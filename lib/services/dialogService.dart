import 'package:Tunein/services/themeService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'locator.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/services/layout.dart';
import 'package:flushbar/flushbar.dart';

final themeService = locator<ThemeService>();
final layoutService = locator<LayoutService>();

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

  static showToast(context, {String message, Color color, Widget content}){
    layoutService.scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: content!=null?
        content:
        Text(
            message,
            style: TextStyle(
              color: color!=null?color:Colors.white
            ),
        ),
      )
    );
  }

  static showFlushbar(context, {String message, String title, Color color, Widget titleText, Widget messageText, Duration showDuration, Icon leftIcon}){
    Flushbar(
      icon: leftIcon,
      title:  title,
      titleText: titleText,
      message:  message,
      messageText: messageText,
      borderRadius: 2,
      backgroundColor: color,
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: Duration(milliseconds: 200),
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      flushbarStyle: FlushbarStyle.FLOATING,
      reverseAnimationCurve: Curves.linearToEaseOut,
      duration:  showDuration??Duration(milliseconds: 1000),
    )..show(context);
  }

  static Future<bool> showConfirmDialog(context, {String message, Color titleColor, Color messageColor ,String title, String confirmButtonText, String cancelButtonText}){
    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: MyTheme.darkBlack,
            title: Text(
              title,
              style: TextStyle(
                  color: titleColor!=null?titleColor:Colors.white70
              ),
            ),
            content: Text(
              message!=null?message:"Confirm?",
              style: TextStyle(
                color: messageColor!=null?messageColor:Colors.white
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  confirmButtonText??"CONFIRM",
                  style: TextStyle(
                      color: MyTheme.darkRed
                  ),
                ),
                onPressed: (){
                  Navigator.of(context, rootNavigator: true).pop(true);
                },
              ),
              FlatButton(
                  child: Text(
                    cancelButtonText??"Cancel",
                    style: TextStyle(
                        color: Colors.white
                    ),
                  ),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(false))
            ],
          );
        });
  }
  static Future<bool> showAlertDialog(context, {String message, Color titleColor, Color messageColor ,String title}){
    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: MyTheme.darkBlack,
            title: Text(
              title,
              style: TextStyle(
                  color: titleColor!=null?titleColor:Colors.white70
              ),
            ),
            content: Text(
              message!=null?message:"Alert",
              style: TextStyle(
                color: messageColor!=null?messageColor:Colors.white
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  "OK",
                  style: TextStyle(
                      color: MyTheme.darkRed
                  ),
                ),
                onPressed: (){
                  Navigator.of(context, rootNavigator: true).pop(true);
                },
              ),
            ],
          );
        });
  }

}

class YYDialogType extends YYDialog{}
