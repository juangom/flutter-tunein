import 'dart:io';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:Tunein/services/layout.dart';
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
import 'package:Tunein/pages/single/playingQueue.dart';

class NowPlayingScreen extends StatefulWidget {
  PageController controller;

  NowPlayingScreen({controller}) {
    this.controller = controller != null ? controller : new PageController(
      initialPage: 1
    );
  }

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
    BehaviorSubject<Tune> songStream = new BehaviorSubject<Tune>();
    Tune song;
    return PageView(
      controller: widget.controller,
      children: <Widget>[
        playingQueue(),
        PlayingPage(songStream),
        AlbumSongs(songStream: musicService.playerState$),
      ],
      physics: ClampingScrollPhysics(),
    );
  }
}

class PlayingPage extends StatefulWidget {
  BehaviorSubject<Tune> getTuneWhenReady;

  PlayingPage(this.getTuneWhenReady);

  @override
  _PlayingPageState createState() => _PlayingPageState();
}

class _PlayingPageState extends State<PlayingPage>
    with AutomaticKeepAliveClientMixin<PlayingPage> {
  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();
  final layoutService = locator<LayoutService>();


  @override
  Widget build(BuildContext context) {
    final _screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<MapEntry<MapEntry<PlayerState, Tune>, List<Tune>>>(
      stream: Rx.combineLatest2(
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
        widget.getTuneWhenReady.add(_currentSong);

        return Scaffold(
            body: StreamBuilder<List<int>>(
                stream: themeService.color$,
                builder: (context, AsyncSnapshot<List<int>> snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  final List<int> colors = snapshot.data;
                  return Stack(
                    children: <Widget>[
                      AnimatedContainer(
                        padding: MediaQuery.of(context).padding,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.decelerate,
                        color: Color(colors[0]),
                        child: getPlayinglayout(
                            _currentSong, colors, _screenHeight, _isFavorited),
                      ),
                      Positioned(
                          right: 3,
                          top: (_screenHeight / 2)-40,
                          child: Container(
                            child:
                            RotatedBox(
                              quarterTurns: -1,
                              child: Column(
                                children: <Widget>[
                                  Text("Album songs",
                                      style: TextStyle(
                                          color: Color(colors[1]).withOpacity(0.4),
                                          fontSize: 12.5)
                                  ),
                                  Container(
                                    constraints: BoxConstraints.tightFor(height: 4.0),
                                    margin: EdgeInsets.only(top: 1),
                                    width: 80,
                                    decoration: BoxDecoration(
                                        color: Color(colors[1]),
                                        borderRadius:
                                        BorderRadius.circular(9.5708)),
                                  ),
                                ],
                              ),
                            ),
                          )
                      ),
                      Positioned(
                          left: 3,
                          top: (_screenHeight / 2)-40,
                          child: Container(
                            child:
                            RotatedBox(
                              quarterTurns: 1,
                              child: Column(
                                children: <Widget>[
                                  Text("Playing queue",
                                      style: TextStyle(
                                          color: Color(colors[1]).withOpacity(0.4),
                                          fontSize: 12.5)
                                  ),
                                  Container(
                                    constraints: BoxConstraints.tightFor(height: 4.0),
                                    margin: EdgeInsets.only(top: 1),
                                    width: 80,
                                    decoration: BoxDecoration(
                                        color: Color(colors[1]),
                                        borderRadius:
                                        BorderRadius.circular(9.5708)),
                                  ),
                                ],
                              ),
                            ),
                          )
                      )
                    ],
                  );
                }));
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

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
      return Container(
        height: _screenHeight,
      );
    }

    String image = songs.value.albumArt;
    String image2 = songs.key.albumArt;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Container(
            height: _screenHeight,
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
                        radius: 90.0,
                        child: Icon(
                          Icons.album,
                          size: 30,
                          color: Color(colors[1]).withOpacity(.7),
                        ),
                        onTap: () {
                          gotoFullAlbumPage(context, _currentSong);
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

  gotoFullAlbumPage(context, Tune song) {
    ///opens an other page, Deprecated in favor of a pageView slide
    //MyUtils.createDelayedPageroute(context, SingleAlbumPage(song),this.widget);
    layoutService.albumPlayerPageController
        .nextPage(duration: Duration(milliseconds: 200), curve: Curves.easeIn);
  }
}

class AlbumSongs extends StatefulWidget {
  Stream songStream;
  Tune song;

  AlbumSongs({songStream, song}) {
    this.songStream = songStream;
    this.song = song;
    assert((song == null && songStream != null) ||
        (song != null && songStream == null));
  }

  @override
  _AlbumSongsState createState() => _AlbumSongsState();
}

class _AlbumSongsState extends State<AlbumSongs>
    with AutomaticKeepAliveClientMixin<AlbumSongs> {
  @override
  Widget build(BuildContext context) {
    if (widget.song != null) {
      return SingleAlbumPage(widget.song);
    } else
      return StreamBuilder<MapEntry<PlayerState, Tune>>(
        stream: widget.songStream,
        builder: (BuildContext context, AsyncSnapshot<MapEntry<PlayerState, Tune>> snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: MyTheme.bgBottomBar,
            );
          }
          final _currentSong = snapshot.data.value;

          if (_currentSong.id == null) {
            return Scaffold(
              backgroundColor: MyTheme.bgBottomBar,
            );
          }
          return Scaffold(
            body: SingleAlbumPage(_currentSong),
          );
        },
      );
  }

  @override
  bool get wantKeepAlive => true;
}
