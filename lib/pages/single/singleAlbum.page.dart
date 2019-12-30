import 'dart:io';

import 'package:Tunein/components/card.dart';
import 'package:Tunein/components/albumSongList.dart';
import 'package:Tunein/components/pageheader.dart';
import 'package:Tunein/components/scrollbar.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SingleAlbumPage extends StatelessWidget {
  final Tune song;

  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();
  @override
  Widget build(BuildContext context){
    return StreamBuilder(
      stream: musicService.fetchAlbum(artist: song.artist, title: song.album),
      builder: (BuildContext context, AsyncSnapshot<List<Album>> snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        if (snapshot.data.length == 0) {
          return new Container();
        }
        Album album = snapshot.data[0];

        return new Container(
          child: Column(
            children: <Widget>[
              Material(
                child: StreamBuilder(
                  stream:  themeService.getThemeColors(song).asStream(),
                  builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot){
                    List<int> bgColor;
                    if(!snapshot.hasData || snapshot.data.length==0){
                      return Container(

                        child: new Container(
                          margin: EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  child: FadeInImage(
                                    placeholder: AssetImage('images/track.png'),
                                    fadeInDuration: Duration(milliseconds: 200),
                                    fadeOutDuration: Duration(milliseconds: 100),
                                    image: album.albumArt != null
                                        ? FileImage(
                                      new File(album.albumArt),
                                    )
                                        : AssetImage('images/track.png'),
                                  ),
                                ),
                                flex: 4,
                              ),
                              Expanded(
                                flex: 7,
                                child: Container(
                                  margin: EdgeInsets.all(8).subtract(EdgeInsets.only(left: 8))
                                      .add(EdgeInsets.only(top: 10)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          (album.title == null)
                                              ? "Unknon Title"
                                              : album.title,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 17.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        (album.artist == null)
                                            ? "Unknown Artist"
                                            : album.artist,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.bottomRight,
                                        margin: EdgeInsets.all(5)
                                            .add(EdgeInsets.only(top: 2)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Container(
                                              margin: EdgeInsets.only(right: 5),
                                              child: Text(
                                                album.songs.length.toString(),
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.audiotrack,
                                              color: Colors.white70,
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.bottomRight,
                                        margin: EdgeInsets.all(5),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Container(
                                              child: Text(
                                                "${Duration(milliseconds: sumDurationsofAlbum(album).floor()).inMinutes} min",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              margin: EdgeInsets.only(right: 5),
                                            ),
                                            Icon(
                                              Icons.access_time,
                                              color: Colors.white70,
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  padding: EdgeInsets.all(10),
                                  alignment: Alignment.topCenter,
                                ),
                              )
                            ],
                          ),
                          height: 200,
                        ),
                        color: bgColor!=null?Color(bgColor[0]):MyTheme.bgBottomBar,
                      );
                    }

                    bgColor=snapshot.data;

                    return Container(
                      child: new Container(
                        margin: EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                child: FadeInImage(
                                  placeholder: AssetImage('images/track.png'),
                                  fadeInDuration: Duration(milliseconds: 200),
                                  fadeOutDuration: Duration(milliseconds: 100),
                                  image: album.albumArt != null
                                      ? FileImage(
                                    new File(album.albumArt),
                                  )
                                      : AssetImage('images/track.png'),
                                ),
                              ),
                              flex: 4,
                            ),
                            Expanded(
                              flex: 7,
                              child: Container(
                                margin: EdgeInsets.all(8).subtract(EdgeInsets.only(left: 8))
                                    .add(EdgeInsets.only(top: 10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        (album.title == null)
                                            ? "Unknon Title"
                                            : album.title,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontSize: 17.5,
                                          fontWeight: FontWeight.w700,
                                          color: bgColor!=null?Color(bgColor[2]).withAlpha(200):Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      (album.artist == null)
                                          ? "Unknown Artist"
                                          : album.artist,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w400,
                                        color: bgColor!=null?Color(bgColor[2]):Colors.white,
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.bottomRight,
                                      margin: EdgeInsets.all(5)
                                          .add(EdgeInsets.only(top: 2)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Container(
                                            margin: EdgeInsets.only(right: 5),
                                            child: Text(
                                              album.songs.length.toString(),
                                              style: TextStyle(
                                                color: bgColor!=null?Color(bgColor[2]):Colors.white70,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.audiotrack,
                                            color: bgColor!=null?Color(bgColor[2]):Colors.white70,
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.bottomRight,
                                      margin: EdgeInsets.all(5),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Container(
                                            child: Text(
                                              "${Duration(milliseconds: sumDurationsofAlbum(album).floor()).inMinutes} min",
                                              style: TextStyle(
                                                color: bgColor!=null?Color(bgColor[2]):Colors.white70,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            margin: EdgeInsets.only(right: 5),
                                          ),
                                          Icon(
                                            Icons.access_time,
                                            color: bgColor!=null?Color(bgColor[2]):Colors.white70,
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                padding: EdgeInsets.all(10),
                                alignment: Alignment.topCenter,
                              ),
                            )
                          ],
                        ),
                      ),
                      height: 200,
                      color: bgColor!=null?Color(bgColor[0]):MyTheme.bgBottomBar,
                    );
                  },
                ),
                elevation: 12.0,
              ),
              Flexible(
                child: AlbumSongList(album),
              )
            ],
          ),
        );
      },
    );
  }

  double sumDurationsofAlbum(Album album) {
    double FinalDuration = 0;

    album.songs.forEach((elem) {
      FinalDuration += elem.duration;
    });

    return FinalDuration;
  }

  SingleAlbumPage(this.song);
}
