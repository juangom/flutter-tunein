import 'dart:io';

import 'package:Tunein/components/artistAlbumsList.dart';
import 'package:Tunein/components/card.dart';
import 'package:Tunein/components/albumSongList.dart';
import 'package:Tunein/components/genericSongList.dart';
import 'package:Tunein/components/pageheader.dart';
import 'package:Tunein/components/scrollbar.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:Tunein/models/playback.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:Tunein/values/contextMenus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:Tunein/components/ArtistCell.dart';

class SinglePlaylistPage extends StatelessWidget {
  Playlist playlist;
  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();

  SinglePlaylistPage(this.playlist);

  @override
  Widget build(BuildContext context) {
    if (playlist != null) {
      return new Container(
        child: Column(
          children: <Widget>[
            Material(
              child: Container(
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
                            image: playlist.covertArt != null
                                ? FileImage(
                                    new File(playlist.covertArt),
                                  )
                                : AssetImage('images/track.png'),
                          ),
                        ),
                        flex: 4,
                      ),
                      Expanded(
                        flex: 7,
                        child: Container(
                          margin: EdgeInsets.all(8)
                              .subtract(EdgeInsets.only(left: 8))
                              .add(EdgeInsets.only(top: 10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    (playlist.name == null)
                                        ? "Unnamed Playlist"
                                        : playlist.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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
                                        switch(choice.id){
                                          case 1: {
                                            musicService.updatePlaylist(playlist.songs);
                                            musicService.playOne(playlist.songs[0]);
                                            break;
                                          }
                                          case 2:{
                                            musicService.updatePlayback(Playback.shuffle);
                                            musicService.updatePlaylist(playlist.songs);
                                            musicService.playOne(playlist.songs[0]);
                                            break;
                                          }
                                          case 3:{
                                            print("not implemented yet");
                                            break;
                                          }
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return playlistCardContextMenulist.map((ContextMenuOptions choice) {
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
                                (playlist.songs.length == 0)
                                    ? "No Songs"
                                    : "${playlist.songs.length} song(s)",
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
                                        "${Duration(milliseconds: sumDurationsofPlaylist(playlist).floor()).inMinutes} min",
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
                color: MyTheme.bgBottomBar,
              ),
              elevation: 12.0,
            ),
            Flexible(
              child: GenericSongList(
                songs: playlist.songs,
                bgColor: null,
                contextMenuOptions: playlistSongCardContextMenulist,
                onContextOptionSelect: (choice,tune){
                  switch(choice.id){
                    case 1: {
                      musicService.playOne(tune);
                      break;
                    }
                    case 2:{
                      musicService.startWithAndShuffleQueue(tune, playlist.songs);
                      break;
                    }
                    case 3:{
                      musicService.startWithAndShuffleAlbum(tune);
                      break;
                    }
                  }
                },
                onSongCardTap: (song){
                  print("tapped ${song.title}");
                },
              ),
            )
          ],
        ),
      );
    }
  }

  int countSongsInAlbums(List<Album> albums) {
    int count = 0;
    albums.forEach((elem) {
      count += elem.songs.length;
    });
    return count;
  }

  double sumDurationsofPlaylist(Playlist playlist) {
    double FinalDuration = 0;

    playlist.songs.forEach((song) {
      FinalDuration += song.duration;
    });

    return FinalDuration;
  }
}
