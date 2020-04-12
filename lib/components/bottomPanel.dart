import 'dart:io';

import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Tunein/models/playerstate.dart';

import '../globals.dart';

class BottomPanel extends StatelessWidget {
  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();
  Widget playPauseButton;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapEntry<PlayerState, Tune>>(
      stream: musicService.playerState$,
      builder: (BuildContext context,
          AsyncSnapshot<MapEntry<PlayerState, Tune>> snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: MyTheme.bgBottomBar,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.bottomCenter,
          );
        }

        final Tune _currentSong = snapshot.data.value;

        if (_currentSong.id == null) {
          return Container(
            color: MyTheme.bgBottomBar,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.bottomCenter,
          );
        }

        final PlayerState _state = snapshot.data.key;
        final String _artists = getArtists(_currentSong);

        return StreamBuilder<List<int>>(
            stream: themeService.color$,
            builder: (context, AsyncSnapshot<List<int>> snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  color: MyTheme.bgBottomBar,
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                );
              }

              final List<int> colors = snapshot.data;

              return AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.decelerate,
                  color: Color(colors[0]),
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                  child: getBottomPanelLayout(
                      _state, _currentSong, _artists, colors));
            });
      },
    );
  }

  String getArtists(Tune song) {
    if(song.artist == null) return "Unknow Artist";
    return song.artist.split(";").reduce((String a, String b) {
      return a + " & " + b;
    });
  }

  getBottomPanelLayout(_state, _currentSong, _artists, colors) {
    /*if(playPauseButton==null){
      playPauseButton = PlayPauseButton(_state,_currentSong,colors);
    }*/
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 0, left: 5),
          child: _currentSong.albumArt != null
              ? Image.file(File(_currentSong.albumArt))
              : Image.asset("images/track.png"),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              getSlider(colors, _currentSong),
              Padding(
                padding: EdgeInsets.only(left: 20, top: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _currentSong.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(colors[1]).withOpacity(.7),
                              ),
                            ),
                          ),
                          Text(
                            _artists,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(colors[1]).withOpacity(.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (_currentSong.uri == null) {
                                return;
                              }
                              musicService.playPreviousSong();
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Icon(
                                    IconData(0xeb40, fontFamily: 'boxicons'),
                                    color: new Color(colors[1]).withOpacity(.7),
                                    size: 35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            onPressed: () {
                              if (_currentSong.uri == null) {
                                return;
                              }
                              if (PlayerState.paused == _state) {
                                musicService.playMusic(_currentSong);
                              } else {
                                musicService.pauseMusic(_currentSong);
                              }
                            },
                            icon: _state == PlayerState.playing
                                ? Icon(
                              Icons.pause,
                              color: Color(colors[1]).withOpacity(.7),
                            )
                                : Icon(
                              Icons.play_arrow,
                              color: Color(colors[1]).withOpacity(.7),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }


  Widget getSlider(List<int> colors, Tune song){

        return Stack(
          children: <Widget>[
            StreamBuilder(
              initialData: Duration(milliseconds: 1),
              stream: musicService.position$,
              builder: (BuildContext context,
                  AsyncSnapshot<Duration> snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }
                final Duration _currentDuration = snapshot.data;

                return new LinearProgressIndicator(
                  value: _currentDuration != null &&
                      _currentDuration.inMilliseconds > 0
                      ? (_currentDuration.inMilliseconds.toDouble()/song.duration)
                      : 0.0,
                  valueColor:
                  new AlwaysStoppedAnimation(Color(colors[1])),
                  backgroundColor: Color(colors[0]),
                ) ;
              },
            )
          ],
        );
  }
//Deprecated
  Widget PlayPauseButton(PlayerState state, Tune _currentSong, List<int> colors){
    PlayerState _state = state;
    return PlayPauseButtonWidget(_state,colors);
  }
}

class PlayPauseButtonWidget extends StatefulWidget {
  PlayerState _state;
  List<int> colors;


  PlayPauseButtonWidget(this._state, this.colors);

  @override
  _PlayPauseButtonState createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButtonWidget> {
  Tune _currentSong;
  PlayerState _state;
  List<int> colors;
  final musicService = locator<MusicService>();


  @override
  void initState() {
    _currentSong=musicService.playerState$.value.value;
    _state = widget._state;
    colors=widget.colors;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: () {
          if (_currentSong.uri == null) {
            return;
          }
          if (PlayerState.paused == _state) {
            setState(() {
              _state = PlayerState.playing;
            });
            musicService.playMusic(_currentSong);
          } else {
            setState(() {
              _state=PlayerState.paused;
            });
            musicService.pauseMusic(_currentSong);
          }
        },
        icon: _state == PlayerState.playing
            ? Icon(
          Icons.pause,
          color: Color(colors[1]).withOpacity(.7),
        )
            : Icon(
          Icons.play_arrow,
          color: Color(colors[1]).withOpacity(.7),
        ),
      ),
    );;
  }
}
