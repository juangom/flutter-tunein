import 'package:Tunein/components/selectableTile.dart';
import 'package:Tunein/plugins/upnp.dart';
import 'package:Tunein/services/castService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:upnp/upnp.dart' as upnp;
import 'locator.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/services/layout.dart';
import 'package:flushbar/flushbar.dart';

final themeService = locator<ThemeService>();
final layoutService = locator<LayoutService>();
final castService = locator<CastService>();

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

  static Future<upnp.Device> openDevicePickingDialog(context, List<upnp.Device> devices){
    Widget ShallowWidget = Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: MyTheme.darkgrey.withOpacity(.01),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(MyTheme.darkRed),
            ),
            Container(
              margin: EdgeInsets.only(top: 8),
              child: Text("No devices registered",
                style: TextStyle(
                    color: MyTheme.grey300,
                    fontSize: 18
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 8),
              child: Text("Searching for devices",
                style: TextStyle(
                    color: MyTheme.grey300,
                    fontSize: 17
                ),
              ),
            )
          ],
        ),
      ),
    );
    Widget devicesNotSent = StreamBuilder(
      stream: castService.searchForDevices().asStream(),
      builder: (context, AsyncSnapshot<List<upnp.Device>> snapshot){
        devices=snapshot.data;
        Widget animtableChild;
        if(!snapshot.hasData){
          animtableChild=ShallowWidget;
        }else{
          if(devices.length!=0){
            animtableChild = ListView.builder(
              padding: EdgeInsets.all(3),
              itemBuilder: (context, index){
                upnp.Device device = devices[index];
                return SelectableTile(
                  imageUri:null,
                  title: device.friendlyName,
                  isSelected: false,
                  selectedBackgroundColor: MyTheme.darkRed,
                  onTap: (willItBeSelected){
                    Navigator.of(context, rootNavigator: true).pop(device);
                  },
                  placeHolderAssetUri: "images/blackbgUpnp.png",
                );
              },
              semanticChildCount: devices.length,
              cacheExtent: 60,
              itemCount: devices.length,
            );
          }else{
            animtableChild= Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    child: Text("No Devices Found",
                      style: TextStyle(
                          color: MyTheme.grey300,
                          fontSize: 17
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        }
        return AnimatedSwitcher(
          reverseDuration: Duration(milliseconds: 300),
          duration: Duration(milliseconds: 300),
          switchInCurve: Curves.easeInToLinear,
          child:animtableChild,
        );
      },
    );
    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: MyTheme.darkBlack,
            title: Text(
              "Choosing Cast Devices",
              style: TextStyle(
                  color: Colors.white70
              ),
            ),
            content: Container(
              height: MediaQuery.of(context).size.height/2.5,
              width: MediaQuery.of(context).size.width/1.2,
              child: devices==null?devicesNotSent:ListView.builder(
                padding: EdgeInsets.all(3),
                itemBuilder: (context, index){
                  upnp.Device device = devices[index];
                  return SelectableTile(
                    imageUri:null,
                    title: device.friendlyName,
                    isSelected: false,
                    selectedBackgroundColor: MyTheme.darkRed,
                    onTap: (willItBeSelected){
                      Navigator.of(context, rootNavigator: true).pop(device);
                    },
                    placeHolderAssetUri: "images/blackbgUpnp.png",
                  );
                },
                semanticChildCount: devices.length,
                cacheExtent: 60,
                itemCount: devices.length,
              ),
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: MyTheme.darkRed
                    ),
                  ),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop())
            ],
          );
        });

    /* Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => EditPlaylist(playlist: playlist),
          fullscreenDialog: true
      ),
    );*/
  }
}

class YYDialogType extends YYDialog{}
