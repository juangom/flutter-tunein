import 'dart:convert';

import 'package:Tunein/globals.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';





class TrackListDeckItem extends StatefulWidget {
  final Key globalWidgetKey;
  final Icon icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final bool withBadge;
  final Color badgeColor;
  final Widget badgeContent;
  final TrackListDeckItemState initialState;
  final dynamic Function() onTap;
  final dynamic Function() onBuild;
  final dynamic Function() onLongPress;
  TrackListDeckItem({this.icon, this.title, this.subtitle, this.iconColor, this.badgeContent,
    this.titleColor, this.subtitleColor, this.withBadge, this.badgeColor, this.initialState, this.onLongPress, this.onTap, this.onBuild, this.globalWidgetKey});

  @override
  _TrackListDeckItemState createState() => _TrackListDeckItemState();
}

class _TrackListDeckItemState extends State<TrackListDeckItem> {
   Icon icon;
   String title;
   String subtitle;
   Color iconColor;
   Color titleColor;
   Color subtitleColor;
   Color badgeColor;
   bool withBadge=false;
   Widget currentBadge;
   TrackListDeckItemState initialState;
   dynamic Function() onTap;
   dynamic Function() onLongPress;
  @override
  void initState() {

    icon=widget.icon;
    title=widget.title;
    subtitle=widget.subtitle;
    iconColor=widget.iconColor;
    titleColor=widget.titleColor;
    titleColor=widget.titleColor;
    subtitleColor=widget.subtitleColor;
    onTap=widget.onTap;
    onLongPress=widget.onLongPress;
    badgeColor= widget.badgeColor;
    initialState=widget.initialState;
    currentBadge= widget.badgeContent;
    if(initialState.extraData!=null){
      withBadge??initialState.extraData["withBadge"]!=null?withBadge=initialState.extraData["withBadge"]:null;
      title??(initialState.extraData["title"]!=null?title=initialState.extraData["title"]:null);
      subtitle??(initialState.extraData["subtitle"]!=null?subtitle=initialState.extraData["subtitle"]:null);
      iconColor??(initialState.extraData["iconColor"]!=null?iconColor=Color(int.parse(initialState.extraData["iconColor"])):null);
      titleColor??(initialState.extraData["titleColor"]!=null?titleColor=Color(int.parse(initialState.extraData["titleColor"])):null);
      subtitleColor??(initialState.extraData["subtitleColor"]!=null?subtitleColor=Color(int.parse(initialState.extraData["subtitleColor"])):null);
      badgeColor??(initialState.extraData["badgeColor"]!=null?badgeColor=Color(int.parse(initialState.extraData["badgeColor"])):null);
    }
    if(widget.onBuild!=null){
      Future.value(widget.onBuild()).then((data){
        Map ret = data;
        if(ret!=null){
          ret["withBadge"]!=null?withBadge=ret["withBadge"]:null;
          ret["badgeContent"]!=null?currentBadge=ret["badgeContent"]:null;
          ret["icon"]!=null?icon=ret["icon"]:null;
          ret["title"]!=null?title=ret["title"]:null;
          ret["subtitle"]!=null?subtitle=ret["subtitle"]:null;
          ret["iconColor"]!=null?iconColor=ret["iconColor"]:null;
          ret["titleColor"]!=null?titleColor=ret["titleColor"]:null;
          ret["subtitleColor"]!=null?subtitleColor=ret["subtitleColor"]:null;
          ret["badgeColor"]!=null?badgeColor=ret["badgeColor"]:null;
          setState(() {

          });
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: widget.globalWidgetKey??GlobalKey(),
      color: Colors.transparent,
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(left: 5),
          child: Container(
            height: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  // color: Colors.red,
                  alignment: Alignment.bottomCenter,
                  width: 50,
                  child: withBadge?Badge(
                    child: Icon(
                      this.icon.icon,
                      color: this.iconColor??Colors.white,
                      size: 28,
                    ),
                    badgeContent: currentBadge??Text("*"),
                    badgeColor: badgeColor??MyTheme.darkRed,
                  ):Icon(
                    this.icon.icon,
                    color: this.iconColor??Colors.white,
                    size: 28,
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, top: 3),
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: MyTheme.grey700,
                          ),
                        ),
                      ),
                      /*Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white54,
                    ),
                  ),*/
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: (){
          if(onTap!=null){
            Future.value(onTap()).then((data){
              Map ret = data;
              if(ret!=null){
                ret["withBadge"]!=null?withBadge=ret["withBadge"]:null;
                ret["badgeContent"]!=null?currentBadge=ret["badgeContent"]:null;
                ret["icon"]!=null?icon=ret["icon"]:null;
                ret["title"]!=null?title=ret["title"]:null;
                ret["subtitle"]!=null?subtitle=ret["subtitle"]:null;
                ret["iconColor"]!=null?iconColor=ret["iconColor"]:null;
                ret["titleColor"]!=null?titleColor=ret["titleColor"]:null;
                ret["subtitleColor"]!=null?subtitleColor=ret["subtitleColor"]:null;
                ret["badgeColor"]!=null?badgeColor=ret["badgeColor"]:null;
                setState(() {

                });
              }
            });
          }
        },
        onLongPress: (){
          if(onLongPress!=null){
            Future.value(onLongPress()).then((data){
              Map ret = data;
              if(ret!=null){
                ret["withBadge"]!=null?withBadge=ret["withBadge"]:null;
                ret["badgeContent"]!=null?currentBadge=ret["badgeContent"]:null;
                ret["icon"]!=null?icon=ret["icon"]:null;
                ret["title"]!=null?title=ret["title"]:null;
                ret["subtitle"]!=null?subtitle=ret["subtitle"]:null;
                ret["iconColor"]!=null?iconColor=ret["iconColor"]:null;
                ret["titleColor"]!=null?titleColor=ret["titleColor"]:null;
                ret["subtitleColor"]!=null?subtitleColor=ret["subtitleColor"]:null;
                ret["badgeColor"]!=null?badgeColor=ret["badgeColor"]:null;
                setState(() {

                });
              }
            });
          }
        },
      ),
    );
  }



  setBadgeContent(Widget content){
    if(withBadge){
      //Set badge content
      setState(() {
        currentBadge=content;
      });
    }
  }
}


class TrackListDeckItemState{
  bool isActive;
  String activeNature;
  String natureKey;
  ///[extraData] is a map that holds the item's configuration of color and text
  Map<String, dynamic> extraData;
  TrackListDeckItemState({this.isActive=false, this.activeNature, this.natureKey, this.extraData});

  Map toMap(){
    Map<String,String> map = Map();
    map["isActive"]= this.isActive.toString();
    map["activeNature"]= this.activeNature.toString();
    map["natureKey"]= this.natureKey.toString();
    Map<String,String> newMap=Map();
    this.extraData!=null?this.extraData.keys.forEach((elem){
      if(extraData[elem] is Color){
        newMap[elem]= (extraData[elem] as Color).value.toString();
      }else{
        newMap[elem] = extraData[elem];
      }
    }):null;
    map["extraData"] = json.encode(newMap);
    return map;
  }

  TrackListDeckItemState.fromMap(Map _m){
    isActive=_m["isActive"]=="true";
    activeNature=_m["activeNature"];
    natureKey=_m["natureKey"];
    extraData=json.decode(_m["extraData"]);
  }
}