import 'dart:io';
import 'dart:math';
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
import 'package:Tunein/values/contextMenus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'package:Tunein/models/playback.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:Tunein/components/smallControlls.dart';

class playingQueue extends StatefulWidget {
  @override
  _playingQueueState createState() => _playingQueueState();
}

class _playingQueueState extends State<playingQueue> with AutomaticKeepAliveClientMixin<playingQueue> {

  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();
  ScrollController controller;
  List<Tune> songs;

  @override
  void initState() {
    controller = ScrollController();

    super.initState();
  }


  @override
  bool get wantKeepAlive {
    return true;
  }

  @override
  void dispose() {
    controller.dispose();
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
                milliseconds: (pow(log((indexOfThePlayingSong>0?indexOfThePlayingSong:1)*2), 2)).floor() + 50
            ),
                curve: Curves.fastOutSlowIn
            );
        }
      });
    });


    return StreamBuilder<MapEntry<List<Playback>,MapEntry<List<Tune>,List<Tune>>>>(
      stream: Rx.combineLatest2(
        musicService.playback$,
        musicService.playlist$,
            (a, b) => MapEntry(a, b),
      ),
      builder: (BuildContext context, AsyncSnapshot<MapEntry<List<Playback>,MapEntry<List<Tune>,List<Tune>>>> snapshot){

        if(!snapshot.hasData){
          return Container(
            color: MyTheme.bgBottomBar,
          );
        }

        final bool _isShuffle = snapshot.data.key.contains(Playback.shuffle);
        final List<Tune> _playlist =
        _isShuffle ? snapshot.data.value.value : snapshot.data.value.key;
        songs=_playlist;

        return StreamBuilder(
          stream: musicService.playerState$,
          builder: (BuildContext context, AsyncSnapshot<MapEntry<PlayerState, Tune>> snapshotOne){
            if(!snapshotOne.hasData ){
              return Container();
            }

            Tune _currentSong = snapshotOne.data.value;

            return StreamBuilder(
              stream:  themeService.getThemeColors(_currentSong!=null?_currentSong:null).asStream(),
              builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot){
                List<int> bgColor;
                if(!snapshot.hasData || snapshot.data.length==0){
                  return Container(
                    color: MyTheme.bgBottomBar,
                  );
                }

                bgColor=snapshot.data;

                return Container(

                  color: bgColor!=null?Color(bgColor[0]):MyTheme.darkBlack,

                  child: new Column(
                    children: <Widget>[
                      Material(
                        child: AnimatedContainer(
                          duration: Duration(
                              milliseconds: 500
                          ),
                          curve: Curves.fastOutSlowIn,
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
                                      image: _currentSong.albumArt != null
                                          ? FileImage(
                                        new File(_currentSong.albumArt),
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
                                            (_currentSong.title == null)
                                                ? "Unknon Title"
                                                : _currentSong.title,
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
                                          (_currentSong.artist == null)
                                              ? "Unknown Artist"
                                              : _currentSong.artist,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w400,
                                            color: bgColor!=null?Color(bgColor[2]):Colors.white,
                                          ),
                                        ),
                                        /*Container(
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
                                    ),*/
                                        Container(
                                          alignment: Alignment.bottomRight,
                                          margin: EdgeInsets.all(5),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Container(
                                                child: Text(
                                                  "${Duration(milliseconds: _currentSong.duration).inMinutes} min",
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
                                        ),
                                        MusicBoardControls(bgColor)
                                      ],
                                    ),
                                    padding: EdgeInsets.all(7),
                                    alignment: Alignment.topCenter,
                                  ),
                                )
                              ],
                            ),
                          ),
                          height: 200,

                          ///The color here is necessary due to the FadingEdgeScrollView component that needs real contrast in order to display the fading effect
                            ///the animated container on instead of a container for some reason breaks that contrast. In order to use the animated container in the top part of
                            ///the page we had to add it only on that part inside the Material widget. to work this animated container needs a  color attribute thus the duplication between the
                            ///global container and this animated container.
                          color: bgColor!=null?Color(bgColor[0]):MyTheme.darkBlack
                        ),
                          color: Colors.transparent
                      ),
                      Flexible(
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Expanded(
                                child: FadingEdgeScrollView.fromScrollView(
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(0).add(EdgeInsets.only(
                                        left:10
                                    )),
                                    controller: controller,
                                    shrinkWrap: true,
                                    itemExtent: 62,
                                    physics: AlwaysScrollableScrollPhysics(),
                                    itemCount: _playlist.length,
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
                                          final bool _isSelectedSong =
                                              _currentSong == _playlist[newIndex];

                                          return MyCard(
                                            choices: songCardContextMenulist,
                                            onContextSelect: (choice){
                                              switch(choice.id){
                                                case 1: {
                                                  musicService.playOne(_playlist[newIndex]);
                                                  break;
                                                }
                                                case 2:{
                                                  musicService.startWithAndShuffleQueue(_playlist[newIndex], _playlist);
                                                  break;
                                                }
                                                case 3:{
                                                  musicService.startWithAndShuffleAlbum(_playlist[newIndex]);
                                                  break;
                                                }
                                              }
                                            },
                                            onContextCancel: (choice){
                                              print("Cancelled");
                                            },
                                            song: _playlist[newIndex],
                                            colors: bgColor!=null?[Color(bgColor[0]),Color(bgColor[1])]:null,
                                            onTap: (){
                                              switch (_state) {
                                                case PlayerState.playing:
                                                  if (_isSelectedSong) {
                                                    musicService.pauseMusic(_currentSong);
                                                  } else {
                                                    musicService.stopMusic();
                                                    musicService.playMusic(
                                                      _playlist[newIndex],
                                                    );
                                                  }
                                                  break;
                                                case PlayerState.paused:
                                                  if (_isSelectedSong) {
                                                    musicService.playMusic(_playlist[newIndex]);
                                                  } else {
                                                    musicService.stopMusic();
                                                    musicService.playMusic(
                                                      _playlist[newIndex],
                                                    );
                                                  }
                                                  break;
                                                case PlayerState.stopped:
                                                  musicService.playMusic(_playlist[newIndex]);
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
                                  gradientFractionOnStart: 0.2 ,
                                  gradientFractionOnEnd: 0.0,
                                ),
                              ),
                              MyScrollbar(
                                controller: controller,
                                color: bgColor!=null?Color(bgColor[0]):null,
                              ),
                            ],
                          ),
                          ///The color here is necessary for the
                          color: bgColor!=null?Color(bgColor[0]):MyTheme.darkBlack,
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );




      },
    );
  }
}
