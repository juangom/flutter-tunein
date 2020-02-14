import 'package:Tunein/components/card.dart';
import 'package:Tunein/components/pageheader.dart';
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

class TracksPage extends StatefulWidget {
  _TracksPageState createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage>
    with AutomaticKeepAliveClientMixin<TracksPage> {
  final musicService = locator<MusicService>();
  ScrollController controller;

  List<Tune> songs;
  @override
  void initState() {
    controller = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screensize = MediaQuery.of(context).size;

    double getSongPosition(int indexOfThePlayingSong,double numberOfSongsPerScreen){
      double finalNumber =((((indexOfThePlayingSong)/numberOfSongsPerScreen) - ((indexOfThePlayingSong)/numberOfSongsPerScreen).floor()));
      if(finalNumber.abs() <numberOfSongsPerScreen/2){
        return -((numberOfSongsPerScreen/2) - finalNumber)*62;
      }else{
        return (finalNumber - (numberOfSongsPerScreen/2))*62;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((duration){
      double numberOfSongsPerScreen =((screensize.height-160)/62);
      musicService.playerState$.listen((MapEntry<PlayerState, Tune> value){
        if(value!=null && songs!=null){
          int indexOfThePlayingSong =songs.indexOf(value.value);
          if(indexOfThePlayingSong>0)
          /*print("  index : ${indexOfThePlayingSong} final value : ${(pow(log(indexOfThePlayingSong)*2, 2)).floor()}  value of Songs per screen : ${numberOfSongsPerScreen}  and the pool ${(indexOfThePlayingSong/numberOfSongsPerScreen)}");
          print("the difference between the pool number based postion and the oridnary index*size postion : ${((indexOfThePlayingSong)/numberOfSongsPerScreen - ((indexOfThePlayingSong)/numberOfSongsPerScreen).floor())*numberOfSongsPerScreen}");
          print(" the ideal position would be equal to the desired pool and a portion of the next pool so that the final position to scroll to would be determined by creating a virtual pool between the previous"
              "pool and the next one in order to put the desired song in the middle of the screen this will be done by finding out the difference between the position of the song in the pool and "
              "half of the pool : the position of the song in the new pool : ${((indexOfThePlayingSong)/numberOfSongsPerScreen - ((indexOfThePlayingSong)/numberOfSongsPerScreen).floor())*numberOfSongsPerScreen}, The difference "
              "is (${numberOfSongsPerScreen} - ${((indexOfThePlayingSong)/numberOfSongsPerScreen - ((indexOfThePlayingSong)/numberOfSongsPerScreen).floor())*numberOfSongsPerScreen}) = ${((indexOfThePlayingSong)/numberOfSongsPerScreen - ((indexOfThePlayingSong)/numberOfSongsPerScreen).floor())*numberOfSongsPerScreen - numberOfSongsPerScreen}"
              "if the difference is less than half of the pool size in number of songs the scroll position should be pulled back else it should be pushed forward");


          print("${((((indexOfThePlayingSong)/numberOfSongsPerScreen))*numberOfSongsPerScreen*62)} added value : ${getSongPosition(indexOfThePlayingSong,numberOfSongsPerScreen)} final Value : ${(indexOfThePlayingSong*61.2)+getSongPosition(indexOfThePlayingSong,numberOfSongsPerScreen)}");*/
          if(controller.hasClients)
          controller.animateTo(((indexOfThePlayingSong+1)*62)+getSongPosition(indexOfThePlayingSong,numberOfSongsPerScreen),duration: Duration(
            milliseconds: (pow(log(indexOfThePlayingSong*2), 2)).floor() + 50
          ),
            curve: Curves.fastOutSlowIn
          );
        }
      });
    });
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
                    stream: musicService.songs$,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Tune>> snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }

                      final _songs = snapshot.data;
                      songs=_songs;
                      _songs.sort((a, b) {
                        return a.title
                            .toLowerCase()
                            .compareTo(b.title.toLowerCase());
                      });
                      return ListView.builder(
                        padding: EdgeInsets.all(0),
                        controller: controller,
                        shrinkWrap: true,
                        itemExtent: 62,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: _songs.length + 1,
                        itemBuilder: (context, index) {
                          return StreamBuilder<MapEntry<PlayerState, Tune>>(
                            stream: musicService.playerState$,
                            builder: (BuildContext context,
                                AsyncSnapshot<MapEntry<PlayerState, Tune>>
                                    snapshot) {
                              if (!snapshot.hasData) {
                                return Container();
                              }
                              int newIndex = index - 1;
                              final PlayerState _state = snapshot.data.key;
                              final Tune _currentSong = snapshot.data.value;

                              if (index == 0) {
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
                              }



                              final bool _isSelectedSong =
                                  _currentSong == _songs[newIndex];


                              return InkWell(
                                enableFeedback: false,
                                child: MyCard(
                                  choices: songCardContextMenulist,
                                  onContextSelect: (choice){
                                      switch(choice.id){
                                        case 1: {
                                          musicService.playOne(_songs[newIndex]);
                                          break;
                                        }
                                        case 2:{
                                          musicService.startWithAndShuffleQueue(_songs[newIndex], _songs);
                                          break;
                                        }
                                        case 3:{
                                          musicService.startWithAndShuffleAlbum(_songs[newIndex]);
                                          break;
                                        }
                                      }
                                  },
                                  onContextCancel: (choice){
                                    print("Cancelled");
                                  },
                                  song: _songs[newIndex],
                                  onTap: (){
                                    musicService.updatePlaylist(_songs);
                                    switch (_state) {
                                      case PlayerState.playing:
                                        if (_isSelectedSong) {
                                          musicService.pauseMusic(_currentSong);
                                        } else {
                                          musicService.stopMusic();
                                          musicService.playMusic(
                                            _songs[newIndex],
                                          );
                                        }
                                        break;
                                      case PlayerState.paused:
                                        if (_isSelectedSong) {
                                          musicService
                                              .playMusic(_songs[newIndex]);
                                        } else {
                                          musicService.stopMusic();
                                          musicService.playMusic(
                                            _songs[newIndex],
                                          );
                                        }
                                        break;
                                      case PlayerState.stopped:
                                        musicService.playMusic(_songs[newIndex]);
                                        break;
                                      default:
                                        break;
                                    }
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

  @override
  bool get wantKeepAlive => true;

}
