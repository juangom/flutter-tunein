import 'package:Tunein/components/card.dart';
import 'package:Tunein/components/pageheader.dart';
import 'package:Tunein/components/scrollbar.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/values/contextMenus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AlbumSongList extends StatefulWidget {

  final Album album;

  AlbumSongList(this.album);

  @override
  _AlbumSongListState createState() => _AlbumSongListState();
}

class _AlbumSongListState extends State<AlbumSongList> {
  final musicService = locator<MusicService>();
  ScrollController controller;

  @override
  void initState() {
    // TODO: implement initState
    controller = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {


    return StreamBuilder(
      stream:  themeService.getThemeColors(widget.album.songs[0]).asStream(),
      builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot){
        List<int> bgColor;

        bgColor=snapshot.data;

        return Container(
          alignment: Alignment.center,
          color: bgColor!=null?Color(bgColor[0]).withRed(30).withGreen(30).withBlue(30):MyTheme.darkBlack,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Flexible(
                      child: ListView.builder(
                        padding: EdgeInsets.all(0).add(EdgeInsets.only(
                            left:10
                        )),
                        controller: controller,
                        shrinkWrap: true,
                        itemExtent: 62,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: widget.album.songs.length + 1,
                        itemBuilder: (context, index) {
                          return StreamBuilder<MapEntry<PlayerState, Tune>>(
                            stream: musicService.playerState$,
                            builder: (BuildContext context,
                                AsyncSnapshot<MapEntry<PlayerState, Tune>>
                                snapshot) {
                              if (!snapshot.hasData) {
                                return Container();
                              }
                              if (index == 0) {
                                return Material(
                                  child: PageHeader(
                                    "Suffle",
                                    "All Tracks",
                                    MapEntry(
                                        IconData(Icons.shuffle.codePoint,
                                            fontFamily: Icons.shuffle.fontFamily),
                                        Colors.white),
                                  ),
                                  color: Colors.transparent,
                                );
                              }

                              int newIndex = index - 1;
                              final PlayerState _state = snapshot.data.key;
                              final Tune _currentSong = snapshot.data.value;
                              final bool _isSelectedSong =
                                  _currentSong == widget.album.songs[newIndex];

                              return MyCard(
                                song: widget.album.songs[newIndex],
                                choices: songCardContextMenulist,
                                onContextSelect: (choice){
                                  switch(choice.id){
                                    case 1: {
                                      musicService.playOne(widget.album.songs[newIndex]);
                                      break;
                                    }
                                    case 2:{
                                      musicService.startWithAndShuffleQueue(widget.album.songs[newIndex], widget.album.songs);
                                      break;
                                    }
                                    case 3:{
                                      musicService.startWithAndShuffleAlbum(widget.album.songs[newIndex]);
                                      break;
                                    }
                                  }
                                },
                                onContextCancel: (choice){
                                  print("Cancelled");
                                },
                                onTap: (){
                                  musicService.updatePlaylist(widget.album.songs);
                                  switch (_state) {
                                    case PlayerState.playing:
                                      if (_isSelectedSong) {
                                        musicService.pauseMusic(_currentSong);
                                      } else {
                                        musicService.stopMusic();
                                        musicService.playMusic(
                                          widget.album.songs[newIndex],
                                        );
                                      }
                                      break;
                                    case PlayerState.paused:
                                      if (_isSelectedSong) {
                                        musicService.playMusic(widget.album.songs[newIndex]);
                                      } else {
                                        musicService.stopMusic();
                                        musicService.playMusic(
                                          widget.album.songs[newIndex],
                                        );
                                      }
                                      break;
                                    case PlayerState.stopped:
                                      musicService.playMusic(widget.album.songs[newIndex]);
                                      break;
                                    default:
                                      break;
                                  }
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
                color: bgColor!=null?Color(bgColor[0]).withRed(30).withGreen(30).withBlue(30):null,
              ),
            ],
          ),
        );
      },
    );




  }
}
