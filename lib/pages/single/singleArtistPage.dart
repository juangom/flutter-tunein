import 'dart:io';

import 'package:Tunein/components/artistAlbumsList.dart';
import 'package:Tunein/components/card.dart';
import 'package:Tunein/components/albumSongList.dart';
import 'package:Tunein/components/pageheader.dart';
import 'package:Tunein/components/scrollbar.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:Tunein/values/contextMenus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:Tunein/components/ArtistCell.dart';


class SingleArtistPage extends StatelessWidget {

  Artist artist;
  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();


  SingleArtistPage(this.artist);

  @override
  Widget build(BuildContext context) {
    if(artist!=null){
      return new Container(
        child: Column(
          children: <Widget>[
            Material(
              child: StreamBuilder(
                stream:  themeService.getArtistColors(artist).asStream(),
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
                                  placeholder: AssetImage('images/artist.jpg'),
                                  fadeInDuration: Duration(milliseconds: 200),
                                  fadeOutDuration: Duration(milliseconds: 100),
                                  image: artist.coverArt != null
                                      ? FileImage(
                                    new File(artist.coverArt),
                                  )
                                      : AssetImage('images/artist.jpg'),
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
                                        (artist.name == null)
                                            ? "Unknon Artist"
                                            : artist.name,
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
                                      (artist.albums.length == 0)
                                          ? "No Albums"
                                          : "${artist.albums.length} album(s)",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      (artist.albums.length == 0)
                                          ? "No Songs"
                                          : "${countSongsInAlbums(artist.albums)} song(s)",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
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
                                              "${Duration(milliseconds: sumDurationsofArtist(artist).floor()).inMinutes} min",
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
                                    ),
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
                                placeholder: AssetImage('images/artist.jpg'),
                                fadeInDuration: Duration(milliseconds: 200),
                                fadeOutDuration: Duration(milliseconds: 100),
                                image: artist.coverArt != null
                                    ? FileImage(
                                  new File(artist.coverArt),
                                )
                                    : AssetImage('images/artist.jpg'),
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
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          (artist.name == null)
                                              ? "Unknon Artist"
                                              : artist.name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 17.5,
                                            fontWeight: FontWeight.w700,
                                            color: bgColor!=null?Color(bgColor[2]).withAlpha(200):Colors.white,
                                          ),
                                        ),
                                      ),
                                      Material(
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
                                                    color: bgColor!=null?Color(bgColor[2]).withAlpha(200):Colors.white70,
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
                                            switch(choice.id){
                                              case 1: {
                                                musicService.playAllArtistAlbums(artist);
                                                break;
                                              }
                                              case 2:{
                                                musicService.suffleAllArtistAlbums(artist);
                                                break;
                                              }
                                            }
                                          },
                                          itemBuilder: (BuildContext context) {
                                            return artistCardContextMenulist.map((ContextMenuOptions choice) {
                                              return PopupMenuItem<ContextMenuOptions>(
                                                value: choice,
                                                child: Text(choice.title),
                                              );
                                            }).toList();
                                          },
                                        ),
                                        color: Colors.transparent,
                                      )
                                    ],

                                  ),
                                  Text(
                                    (artist.albums.length == 0)
                                        ? "No Albums"
                                        : "${artist.albums.length} ${artist.albums.length>1?"albums":"album"}",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w400,
                                      color: bgColor!=null?Color(bgColor[2]).withAlpha(200):Colors.white,
                                    ),
                                  ),
                                  Text(
                                    (artist.albums.length == 0)
                                        ? "No Songs"
                                        : "${countSongsInAlbums(artist.albums)} ${countSongsInAlbums(artist.albums)>1?"songs":"song"}",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w400,
                                      color: bgColor!=null?Color(bgColor[2]).withAlpha(150):Colors.white,
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
                                            "${Duration(milliseconds: sumDurationsofArtist(artist).floor()).inMinutes} min",
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
              child: ArtistAlbumList(artist),
            )
          ],
        ),
      );

    }
  }

  int countSongsInAlbums(List<Album> albums){
    int count=0;
    albums.forEach((elem){
      count+=elem.songs.length;
    });
    return count;
  }


  double sumDurationsofArtist(Artist artist) {
    double FinalDuration = 0;

    artist.albums.forEach((album){
      album.songs.forEach((elem) {
        FinalDuration += elem.duration;
      });
    });

    return FinalDuration;
  }
}
