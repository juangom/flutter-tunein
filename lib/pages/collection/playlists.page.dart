import 'package:Tunein/components/card.dart';
import 'package:Tunein/components/pageheader.dart';
import 'package:Tunein/components/playlistCell.dart';
import 'package:Tunein/components/scrollbar.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:Tunein/models/playback.dart';
import 'dart:math';
import 'dart:core';
import 'package:Tunein/values/contextMenus.dart';


class PlaylistsPage extends StatefulWidget {
  PlaylistsPage({Key key}) : super(key: key);

  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {

  final musicService = locator<MusicService>();
  ScrollController controller = new ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: MyTheme.darkBlack,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Flexible(
                  child: StreamBuilder(
                    stream: musicService.playlists$,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Playlist>> snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                            child: Text(
                              "LOADING PLAYLISTS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                        );
                      }

                      final _playlists = snapshot.data;

                      if(_playlists.length==0){
                        return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  "NO PLAYLISTS",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "Tap to add",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Icon(
                                  Icons.add,
                                  size: 25,
                                  color: Colors.white70,
                                )
                              ],
                            ),
                        );
                      }
                      //playlists=_playlists;
                      _playlists.sort((a, b) {
                        return a.name
                            .toLowerCase()
                            .compareTo(b.name.toLowerCase());
                      });
                      return ListView.builder(
                        padding: EdgeInsets.all(0),
                        controller: controller,
                        shrinkWrap: true,
                        itemExtent: 62,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: _playlists.length,
                        itemBuilder: (context, index) {
                          return StreamBuilder<MapEntry<PlayerState, Tune>>(
                            stream: musicService.playerState$,
                            builder: (BuildContext context,
                                AsyncSnapshot<MapEntry<PlayerState, Tune>>
                                snapshot) {
                              if (!snapshot.hasData) {
                                return Container();
                              }
                              int newIndex = index;
                              final PlayerState _state = snapshot.data.key;
                              final Tune _currentSong = snapshot.data.value;

                             /* if (index == 0) {
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    child: PageHeader(
                                      "Suffle",
                                      "All Tracks",
                                      MapEntry(
                                          IconData(Icons.shuffle.codePoint,
                                              fontFamily: Icons.shuffle.fontFamily),
                                          Colors.white),
                                    ),
                                    onTap: (){
                                      musicService.updatePlayback(Playback.shuffle);
                                      switch (_state) {
                                        case PlayerState.playing:
                                          musicService.stopMusic();
                                          musicService.playNextSong();
                                          break;
                                        case PlayerState.paused:
                                          musicService.stopMusic();
                                          musicService.playNextSong();
                                          break;
                                        case PlayerState.stopped:
                                          musicService.playNextSong();
                                          break;
                                        default:
                                          break;
                                      }
                                    },
                                  ),
                                );
                              }*/



                              /*final bool _isSelectedSong =
                                  _currentSong == _playlists[newIndex];*/
                              final Playlist _currentPlaylist = _playlists[index];

                              return InkWell(
                                enableFeedback: false,
                                child: PlaylistCell(
                                  choices: playlistCardContextMenulist,
                                  onContextSelect: (choice){
                                    switch(choice.id){
                                      case 1: {
                                        musicService.updatePlaylist(_currentPlaylist.songs);
                                        musicService.playOne(_currentPlaylist.songs[0]);
                                        break;
                                      }
                                      case 2:{
                                        musicService.updatePlayback(Playback.shuffle);
                                        musicService.updatePlaylist(_currentPlaylist.songs);
                                        musicService.playOne(_currentPlaylist.songs[0]);
                                        break;
                                      }
                                      case 3:{
                                        print("not implemented yet");
                                        break;
                                      }
                                    }
                                  },
                                  onContextCancel: (){
                                    print("Cancelled");
                                  },
                                  playlistItem: _playlists[newIndex],
                                  onTap: (){

                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          MyScrollbar(
            controller: controller,
          ),
        ],
      ),
    );
  }



  void goToSinglePlaylistPage(Playlist playlist){

  }
}
