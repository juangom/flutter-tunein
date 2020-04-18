import 'dart:io';
import 'dart:math';
import 'package:Tunein/components/threeDotPopupMenu.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:marquee/marquee.dart';
import 'package:rxdart/rxdart.dart';

class MyCard extends StatelessWidget {
  final Tune _song;
  final VoidCallback onTap;
  final VoidCallback onContextTap;
  final musicService = locator<MusicService>();
  final List<Color>colors;
  final Size ScreenSize;
  final double StaticContextMenuFromBottom;
  List<ContextMenuOptions> choices;
  final void Function(ContextMenuOptions) onContextSelect;
  final void Function(ContextMenuOptions) onContextCancel;
  MyCard({Key key, @required Tune song, VoidCallback onTap, VoidCallback onContextTap, this.colors, @required this.choices, @required this.onContextCancel, @required this.onContextSelect, this.ScreenSize, this.StaticContextMenuFromBottom})
      : _song = song,
        onTap=onTap,
        onContextTap=onContextTap,
        super(key: key);


  Widget previousInstance;
  PlayerState previousState;
  @override
  Widget build(BuildContext context) {
    Stream<MapEntry<PlayerState,Tune>> newStream = musicService.playerState$;
    return StreamBuilder(
      stream: newStream,
      builder: (BuildContext context,
          AsyncSnapshot<MapEntry<PlayerState, Tune>> snapshot) {

        if (!snapshot.hasData) {
          return Container();
        }
        final Tune _currentSong = snapshot.data.value;
        final bool _isSelectedSong = _song == _currentSong;
        final _textColor = _isSelectedSong ? colors!=null?colors[1]:Colors.white : colors!=null?colors[1].withAlpha(65):Colors.white54;
        final _fontWeight = _isSelectedSong ? FontWeight.w900 : FontWeight.w400;

        /*if(!_isSelectedSong && previousInstance!=null){
          return previousInstance;
        }else{

          if(!_isSelectedSong){
            Widget newInstance = Container(
              color: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: MyTheme.darkgrey,
                          child:Container(
                            constraints: BoxConstraints.expand(),
                            child:  Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 15),
                                  child: SizedBox(
                                    height: 62,
                                    width: 62,
                                    child: FadeInImage(
                                      placeholder: AssetImage('images/track.png'),
                                      fadeInDuration: Duration(milliseconds: 200),
                                      fadeOutDuration: Duration(milliseconds: 100),
                                      image: _song.albumArt != null
                                          ? FileImage(
                                        new File(_song.albumArt),
                                      )
                                          : AssetImage('images/track.png'),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 8,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: (!_isSelectedSong || _song.title.length<25)?Text(
                                          (_song.title == null)
                                              ? "Unknon Title"
                                              : _song.title,
                                          overflow: TextOverflow.fade,
                                          maxLines: 1,
                                          textWidthBasis: TextWidthBasis.parent,
                                          softWrap: false,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: _fontWeight,
                                            color: colors!=null?colors[1].withAlpha(200):Colors.white,
                                          ),
                                        ): Container(
                                          height: 14,
                                          child: Marquee(
                                            text: (_song.title == null)
                                                ? "Unknon Title"
                                                : _song.title,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: _fontWeight,
                                              color: colors!=null?colors[1]:Colors.white,
                                            ),
                                            scrollAxis: Axis.horizontal,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            blankSpace: _song.title.length*2.0,
                                            velocity: (_song.title == null)?30.0:_song.title.length*1.2,
                                            pauseAfterRound: Duration(seconds: (1+_song.title.length*0.110).floor()),
                                            startPadding: 0.0,
                                            accelerationDuration: Duration(milliseconds: (_song.title == null)?500:_song.title.length*40),
                                            accelerationCurve: Curves.linear,
                                            decelerationDuration: Duration(milliseconds: (_song.title == null)?500:_song.title.length*30),
                                            decelerationCurve: Curves.easeOut,
                                          ),
                                        ),

                                      ),
                                      Text(
                                        (_song.artist == null)
                                            ? "Unknown Artist"
                                            : _song.artist,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: _fontWeight,
                                          color: _textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: (){
                            onTap();
                          },
                        ),
                      ),
                    ),
                    flex: 12,
                  ),
                  choices!=null?Expanded(
                    flex: 2,
                    child: Material(
                      child: PopupMenuButton<ContextMenuOptions>(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor: MyTheme.darkgrey,
                            radius: 30.0,
                            child: Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child:Icon(
                                  IconData(0xea7c, fontFamily: 'boxicons'),
                                  size: 22,
                                  color: Colors.white70,
                                )
                            ),
                          ),
                        ),
                        elevation: 3.2,
                        onCanceled: () {
                          print('You have not chosen anything');
                        },
                        tooltip: 'Playing options',
                        onSelected: (ContextMenuOptions choice){
                          onContextSelect(choice);
                        },
                        itemBuilder: (BuildContext context) {
                          return choices.map((ContextMenuOptions choice) {
                            return PopupMenuItem<ContextMenuOptions>(
                              value: choice,
                              child: Text(choice.title),
                            );
                          }).toList();
                        },
                      ),
                      color: Colors.transparent,
                    ),
                  ):Container()
                ],
              ),
            );
            previousInstance = newInstance;
          }else{
            if(snapshot.data.key!=previousState && previousState!=null){
              return previousInstance;
            }else{
              Widget newInstance = Container(
                color: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor: MyTheme.darkgrey,
                            child:Container(
                              constraints: BoxConstraints.expand(),
                              child:  Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(right: 15),
                                    child: SizedBox(
                                      height: 62,
                                      width: 62,
                                      child: FadeInImage(
                                        placeholder: AssetImage('images/track.png'),
                                        fadeInDuration: Duration(milliseconds: 200),
                                        fadeOutDuration: Duration(milliseconds: 100),
                                        image: _song.albumArt != null
                                            ? FileImage(
                                          new File(_song.albumArt),
                                        )
                                            : AssetImage('images/track.png'),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: (!_isSelectedSong || _song.title.length<25)?Text(
                                            (_song.title == null)
                                                ? "Unknon Title"
                                                : _song.title,
                                            overflow: TextOverflow.fade,
                                            maxLines: 1,
                                            textWidthBasis: TextWidthBasis.parent,
                                            softWrap: false,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: _fontWeight,
                                              color: colors!=null?colors[1].withAlpha(200):Colors.white,
                                            ),
                                          ): Container(
                                            height: 14,
                                            child: Marquee(
                                              text: (_song.title == null)
                                                  ? "Unknon Title"
                                                  : _song.title,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: _fontWeight,
                                                color: colors!=null?colors[1]:Colors.white,
                                              ),
                                              scrollAxis: Axis.horizontal,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              blankSpace: _song.title.length*2.0,
                                              velocity: (_song.title == null)?30.0:_song.title.length*1.2,
                                              pauseAfterRound: Duration(seconds: (1+_song.title.length*0.110).floor()),
                                              startPadding: 0.0,
                                              accelerationDuration: Duration(milliseconds: (_song.title == null)?500:_song.title.length*40),
                                              accelerationCurve: Curves.linear,
                                              decelerationDuration: Duration(milliseconds: (_song.title == null)?500:_song.title.length*30),
                                              decelerationCurve: Curves.easeOut,
                                            ),
                                          ),

                                        ),
                                        Text(
                                          (_song.artist == null)
                                              ? "Unknown Artist"
                                              : _song.artist,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: _fontWeight,
                                            color: _textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: (){
                              onTap();
                            },
                          ),
                        ),
                      ),
                      flex: 12,
                    ),
                    choices!=null?Expanded(
                      flex: 2,
                      child: Material(
                        child: PopupMenuButton<ContextMenuOptions>(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor: MyTheme.darkgrey,
                              radius: 30.0,
                              child: Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child:Icon(
                                    IconData(0xea7c, fontFamily: 'boxicons'),
                                    size: 22,
                                    color: Colors.white70,
                                  )
                              ),
                            ),
                          ),
                          elevation: 3.2,
                          onCanceled: () {
                            print('You have not chosen anything');
                          },
                          tooltip: 'Playing options',
                          onSelected: (ContextMenuOptions choice){
                            onContextSelect(choice);
                          },
                          itemBuilder: (BuildContext context) {
                            return choices.map((ContextMenuOptions choice) {
                              return PopupMenuItem<ContextMenuOptions>(
                                value: choice,
                                child: Text(choice.title),
                              );
                            }).toList();
                          },
                        ),
                        color: Colors.transparent,
                      ),
                    ):Container()
                  ],
                ),
              );
              return newInstance;
            }
          }
          Widget newInstance = Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: Container(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: MyTheme.darkgrey,
                        child:Container(
                          constraints: BoxConstraints.expand(),
                          child:  Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(right: 15),
                                child: SizedBox(
                                  height: 62,
                                  width: 62,
                                  child: FadeInImage(
                                    placeholder: AssetImage('images/track.png'),
                                    fadeInDuration: Duration(milliseconds: 200),
                                    fadeOutDuration: Duration(milliseconds: 100),
                                    image: _song.albumArt != null
                                        ? FileImage(
                                      new File(_song.albumArt),
                                    )
                                        : AssetImage('images/track.png'),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: (!_isSelectedSong || _song.title.length<25)?Text(
                                        (_song.title == null)
                                            ? "Unknon Title"
                                            : _song.title,
                                        overflow: TextOverflow.fade,
                                        maxLines: 1,
                                        textWidthBasis: TextWidthBasis.parent,
                                        softWrap: false,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: _fontWeight,
                                          color: colors!=null?colors[1].withAlpha(200):Colors.white,
                                        ),
                                      ): Container(
                                        height: 14,
                                        child: Marquee(
                                          text: (_song.title == null)
                                              ? "Unknon Title"
                                              : _song.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: _fontWeight,
                                            color: colors!=null?colors[1]:Colors.white,
                                          ),
                                          scrollAxis: Axis.horizontal,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          blankSpace: _song.title.length*2.0,
                                          velocity: (_song.title == null)?30.0:_song.title.length*1.2,
                                          pauseAfterRound: Duration(seconds: (1+_song.title.length*0.110).floor()),
                                          startPadding: 0.0,
                                          accelerationDuration: Duration(milliseconds: (_song.title == null)?500:_song.title.length*40),
                                          accelerationCurve: Curves.linear,
                                          decelerationDuration: Duration(milliseconds: (_song.title == null)?500:_song.title.length*30),
                                          decelerationCurve: Curves.easeOut,
                                        ),
                                      ),

                                    ),
                                    Text(
                                      (_song.artist == null)
                                          ? "Unknown Artist"
                                          : _song.artist,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: _fontWeight,
                                        color: _textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: (){
                          onTap();
                        },
                      ),
                    ),
                  ),
                  flex: 12,
                ),
                /*choices!=null?Expanded(
                  flex: 2,
                  child: Material(
                    child: PopupMenuButton<ContextMenuOptions>(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: MyTheme.darkgrey,
                          radius: 30.0,
                          child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child:Icon(
                                IconData(0xea7c, fontFamily: 'boxicons'),
                                size: 22,
                                color: Colors.white70,
                              )
                          ),
                        ),
                      ),
                      elevation: 3.2,
                      onCanceled: () {
                        print('You have not chosen anything');
                      },
                      tooltip: 'Playing options',
                      onSelected: (ContextMenuOptions choice){
                        onContextSelect(choice);
                      },
                      offset: Offset(0.0, -100),
                      itemBuilder: (BuildContext context) {
                        return choices.map((ContextMenuOptions choice) {
                          return PopupMenuItem<ContextMenuOptions>(
                            value: choice,
                            child: Text(choice.title),
                          );
                        }).toList();
                      },
                    ),
                    color: Colors.transparent,
                  ),
                ):Container()*/
                choices!=null?Expanded(
                  flex: 2,
                  child: GestureDetector(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: MyTheme.darkgrey,
                        radius: 30.0,
                        child: Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child:Icon(
                              IconData(0xea7c, fontFamily: 'boxicons'),
                              size: 22,
                              color: Colors.white70,
                            )
                        ),
                      ),
                    ),
                    onTapDown: (details){
                      List itemList = choices.map((ContextMenuOptions choice) {
                        return PopupMenuItem<ContextMenuOptions>(
                          value: choice,
                          child: Text(choice.title),
                        );
                      }).toList();
                      RenderBox box = context.findRenderObject();
                      Offset _tapPos = box.globalToLocal(details.globalPosition);
                      Offset ButtonOffset = box.size.bottomRight(Offset.zero);
                      print(details.globalPosition.toString());
                      showPopMenu(context,itemList,Buttonoffset:ButtonOffset, ExtraOffset: Offset(-0,-120) );
                    },
                  )
                ):Container()
              ],
            ),
          );
          return newInstance;
        }*/
        Widget newInstance = Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      splashColor: MyTheme.darkgrey,
                      child:Container(
                        constraints: BoxConstraints.expand(),
                        child:  Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 15),
                              child: SizedBox(
                                height: 62,
                                width: 62,
                                child: FadeInImage(
                                  placeholder: AssetImage('images/track.png'),
                                  fadeInDuration: Duration(milliseconds: 200),
                                  fadeOutDuration: Duration(milliseconds: 100),
                                  image: _song.albumArt != null
                                      ? FileImage(
                                    new File(_song.albumArt),
                                  )
                                      : AssetImage('images/track.png'),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: (!_isSelectedSong || _song.title.length<25)?Text(
                                      (_song.title == null)
                                          ? "Unknon Title"
                                          : _song.title,
                                      overflow: TextOverflow.fade,
                                      maxLines: 1,
                                      textWidthBasis: TextWidthBasis.parent,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: _fontWeight,
                                        color: colors!=null?colors[1].withAlpha(200):Colors.white,
                                      ),
                                    ): Container(
                                      height: 14,
                                      child: Marquee(
                                        text: (_song.title == null)
                                            ? "Unknon Title"
                                            : _song.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: _fontWeight,
                                          color: colors!=null?colors[1]:Colors.white,
                                        ),
                                        scrollAxis: Axis.horizontal,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        blankSpace: _song.title.length*2.0,
                                        velocity: (_song.title == null)?30.0:_song.title.length*1.2,
                                        pauseAfterRound: Duration(seconds: (1+_song.title.length*0.110).floor()),
                                        startPadding: 0.0,
                                        accelerationDuration: Duration(milliseconds: (_song.title == null)?500:_song.title.length*40),
                                        accelerationCurve: Curves.linear,
                                        decelerationDuration: Duration(milliseconds: (_song.title == null)?500:_song.title.length*30),
                                        decelerationCurve: Curves.easeOut,
                                      ),
                                    ),

                                  ),
                                  Text(
                                    (_song.artist == null)
                                        ? "Unknown Artist"
                                        : _song.artist,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: _fontWeight,
                                      color: _textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: (){
                        onTap();
                      },
                    ),
                  ),
                ),
                flex: 12,
              ),
              /*choices!=null?Expanded(
                  flex: 2,
                  child: Material(
                    child: PopupMenuButton<ContextMenuOptions>(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: MyTheme.darkgrey,
                          radius: 30.0,
                          child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child:Icon(
                                IconData(0xea7c, fontFamily: 'boxicons'),
                                size: 22,
                                color: Colors.white70,
                              )
                          ),
                        ),
                      ),
                      elevation: 3.2,
                      onCanceled: () {
                        print('You have not chosen anything');
                      },
                      tooltip: 'Playing options',
                      onSelected: (ContextMenuOptions choice){
                        onContextSelect(choice);
                      },
                      offset: Offset(0.0, -100),
                      itemBuilder: (BuildContext context) {
                        return choices.map((ContextMenuOptions choice) {
                          return PopupMenuItem<ContextMenuOptions>(
                            value: choice,
                            child: Text(choice.title),
                          );
                        }).toList();
                      },
                    ),
                    color: Colors.transparent,
                  ),
                ):Container()*/
              choices!=null?ThreeDotPopupMenu(
                choices: choices,
                onContextSelect: onContextSelect,
                screenSize: ScreenSize,
                staticOffsetFromBottom: StaticContextMenuFromBottom,
              ):Container()
            ],
          ),
        );
        return newInstance;
      },
    );
  }


}


