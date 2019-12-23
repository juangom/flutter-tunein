import 'dart:io';
import 'package:page_transition/page_transition.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:Tunein/components/slider.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:flutter/widgets.dart';
import 'package:Tunein/pages/single/singleAlbum.page.dart';
import 'controlls.dart';
import 'package:rxdart/rxdart.dart';

class NowPlayingScreen extends StatefulWidget {
  @override
  NowPlayingScreenState createState() => NowPlayingScreenState();
}

class NowPlayingScreenState extends State<NowPlayingScreen> {
  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<MapEntry<MapEntry<PlayerState, Tune>, List<Tune>>>(
      stream: Observable.combineLatest2(
        musicService.playerState$,
        musicService.favorites$,
        (a, b) => MapEntry(a, b),
      ),
      builder: (BuildContext context,
          AsyncSnapshot<MapEntry<MapEntry<PlayerState, Tune>, List<Tune>>>
              snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: MyTheme.bgBottomBar,
          );
        }
        final _state = snapshot.data.key.key;
        final _currentSong = snapshot.data.key.value;
        final List<Tune> _favorites = snapshot.data.value;

        final int index =
            _favorites.indexWhere((song) => song.id == _currentSong.id);
        final bool _isFavorited = index == -1 ? false : true;

        if (_currentSong.id == null) {
          return Scaffold(
            backgroundColor: MyTheme.bgBottomBar,
          );
        }

        return Scaffold(
            body: StreamBuilder<List<int>>(
                stream: themeService.color$,
                builder: (context, AsyncSnapshot<List<int>> snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  final List<int> colors = snapshot.data;
                  return AnimatedContainer(
                    padding: MediaQuery.of(context).padding,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.decelerate,
                    color: Color(colors[0]),
                    child: getPlayinglayout(
                        _currentSong, colors, _screenHeight, _isFavorited),
                  );
                }));
      },
    );
  }

  String getDuration(Tune _song) {
    final double _temp = _song.duration / 1000;
    final int _minutes = (_temp / 60).floor();
    final int _seconds = (((_temp / 60) - _minutes) * 60).round();
    if (_seconds.toString().length != 1) {
      return _minutes.toString() + ":" + _seconds.toString();
    } else {
      return _minutes.toString() + ":0" + _seconds.toString();
    }
  }

  getPlayinglayout(Tune _currentSong, List<int> colors, double _screenHeight,
      bool _isFavorited) {
    MapEntry<Tune, Tune> songs = musicService.getNextPrevSong(_currentSong);
    if (_currentSong == null || songs == null) {
      return Container();
    }

    String image = songs.value.albumArt;
    String image2 = songs.key.albumArt;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Container(
            constraints: BoxConstraints(
                maxHeight: _screenHeight / 2, minHeight: _screenHeight / 2),
            padding: const EdgeInsets.all(10),
            child: Dismissible(
              key: UniqueKey(),
              background: image == null
                  ? Image.asset("images/cover.png")
                  : Image.file(File(image)),
              secondaryBackground: image2 == null
                  ? Image.asset("images/cover.png")
                  : Image.file(File(image2)),
              movementDuration: Duration(milliseconds: 500),
              resizeDuration: Duration(milliseconds: 2),
              dismissThresholds: const {
                DismissDirection.endToStart: 0.3,
                DismissDirection.startToEnd: 0.3
              },
              direction: DismissDirection.horizontal,
              onDismissed: (DismissDirection direction) {
                if (direction == DismissDirection.startToEnd) {
                  musicService.playPreviousSong();
                } else {
                  musicService.playNextSong();
                }
              },
              child: _currentSong.albumArt == null
                  ? Image.asset("images/cover.png")
                  : Image.file(File(_currentSong.albumArt)),
            )),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                new BoxShadow(
                    color: Color(colors[0]),
                    blurRadius: 50,
                    spreadRadius: 50,
                    offset: new Offset(0, -20)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      child: InkWell(
                        child: Icon(
                          _isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: new Color(colors[1]).withOpacity(.7),
                          size: 30,
                        ),
                        onTap: () {
                          if (_isFavorited) {
                            musicService.removeFromFavorites(_currentSong);
                          } else {
                            musicService.addToFavorites(_currentSong);
                          }
                        },
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text(
                            _currentSong.title,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(colors[1]).withOpacity(.7),
                              fontSize: 18,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              MyUtils.getArtists(_currentSong.artist),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(colors[1]).withOpacity(.7),
                                fontSize: 15,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      child: InkWell(
                        child: Icon(
                          Icons.album,
                          size: 30,
                          color: Colors.white70,
                        ),
                        onTap: () {
                          gotoFullAlbumPage(context,_currentSong);
                        },
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ],
                ),
                NowPlayingSlider(colors),
                MusicBoardControls(colors),
              ],
            ),
          ),
        ),
      ],
    );
  }

  gotoFullAlbumPage(context,Tune song){
    MyUtils.createDelayedPageroute(context, SingleAlbumPage(song),this.widget);
  }
}
