import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:flutter/material.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:rxdart/rxdart.dart';

class MusicBoardControls extends StatelessWidget {
  final List<int> colors;
  PlayerState state;
  Tune currentSong;
  PlayerState localState;
  MusicBoardControls(this.colors,{this.state, this.currentSong}){
   this.localState=this.state;
  }


  Widget playPauseButton(MusicService musicService){

    return StreamBuilder<
        MapEntry<PlayerState, Tune>>(
      stream: musicService.playerState$,
      builder: (BuildContext context,
          AsyncSnapshot<
              MapEntry<PlayerState, Tune>>
          snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final _state = snapshot.data.key;
        final _currentSong = snapshot.data.value;

        return InkWell(
            onTap: () {
              if (_currentSong.uri == null) {
                return;
              }
              if (PlayerState.paused == _state) {
                musicService.playMusic(_currentSong);
              } else {
                musicService.pauseMusic(_currentSong);
              }
            },
            child: Container(
                decoration: BoxDecoration(
                    color: new Color(colors[1]).withOpacity(.7),
                    borderRadius: BorderRadius.circular(30)),
                height: 60,
                width: 60,
                child: Center(
                  child: AnimatedCrossFade(
                    duration: Duration(milliseconds: 200),
                    crossFadeState: _state == PlayerState.playing
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Icon(
                      Icons.pause,
                      color: Color(colors[0]),
                      size: 30,
                    ),
                    secondChild: Icon(
                      Icons.play_arrow,
                      color: Color(colors[0]),
                      size: 30,
                    ),
                  ),
                )
            )
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    final musicService = locator<MusicService>();
    if(state!=localState)localState=state;
    return Material(
      color: Colors.transparent,
      child: Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 0),
          width: double.infinity,
          child: (this.state ==null || this.currentSong==null)?Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconButton(
                padding: EdgeInsets.all(5),
                  icon: Icon(
                    Icons.repeat,
                    color: new Color(colors[1]).withOpacity(.5),
                    size: 20,
                  ),
                  onPressed: () {}
              ),
              IconButton(
                icon: Icon(
                  IconData(0xeb40, fontFamily: 'boxicons'),
                  color: new Color(colors[1]).withOpacity(.7),
                  size: 35,
                ),
                onPressed: () => musicService.playPreviousSong(),
              ),
              IconButton(
                  iconSize: 50,
                  onPressed: () {
                    if (currentSong.uri == null) {
                      return;
                    }
                    if (PlayerState.paused == state) {
                      this.localState==PlayerState.playing;
                      musicService.playMusic(currentSong);
                    } else {
                      this.localState=PlayerState.paused;
                      musicService.pauseMusic(currentSong);
                    }
                  },
                  icon: Container(
                      padding: EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          color: new Color(colors[1]).withOpacity(.7),
                          borderRadius: BorderRadius.circular(30)),
                      height: 60,
                      width: 60,
                      child: Center(
                        child: AnimatedCrossFade(
                          duration: Duration(milliseconds: 200),
                          crossFadeState: localState == PlayerState.playing
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Icon(
                            Icons.pause,
                            color: Color(colors[0]),
                            size: 30,
                          ),
                          secondChild: Icon(
                            Icons.play_arrow,
                            color: Color(colors[0]),
                            size: 30,
                          ),
                        ),
                      ))),
              IconButton(
                icon: Icon(
                  IconData(0xeb3f, fontFamily: 'boxicons'),
                  color: new Color(colors[1]).withOpacity(.7),
                  size: 35,
                ),
                onPressed: () => musicService.playNextSong(),
              ),
              IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: new Color(colors[1]).withOpacity(.5),
                    size: 20,
                  ),
                  onPressed: () {

                  }
              ),
            ],
          ):Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconButton(
                padding: EdgeInsets.all(5),
                  icon: Icon(
                    Icons.repeat,
                    color: new Color(colors[1]).withOpacity(.5),
                    size: 20,
                  ),
                  onPressed: () {}
              ),
              IconButton(
                icon: Icon(
                  IconData(0xeb40, fontFamily: 'boxicons'),
                  color: new Color(colors[1]).withOpacity(.7),
                  size: 35,
                ),
                onPressed: () => musicService.playPreviousSong(),
              ),
              IconButton(
                iconSize: 50,
                  onPressed: () {
                    if (currentSong.uri == null) {
                      return;
                    }
                    if (PlayerState.paused == state) {
                      this.localState==PlayerState.playing;
                      musicService.playMusic(currentSong);
                    } else {
                      this.localState=PlayerState.paused;
                      musicService.pauseMusic(currentSong);
                    }
                  },
                  icon: Container(
                    padding: EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          color: new Color(colors[1]).withOpacity(.7),
                          borderRadius: BorderRadius.circular(30)),
                      height: 60,
                      width: 60,
                      child: Center(
                        child: AnimatedCrossFade(
                          duration: Duration(milliseconds: 200),
                          crossFadeState: localState == PlayerState.playing
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Icon(
                            Icons.pause,
                            color: Color(colors[0]),
                            size: 30,
                          ),
                          secondChild: Icon(
                            Icons.play_arrow,
                            color: Color(colors[0]),
                            size: 30,
                          ),
                        ),
                      ))),
              IconButton(
                icon: Icon(
                  IconData(0xeb3f, fontFamily: 'boxicons'),
                  color: new Color(colors[1]).withOpacity(.7),
                  size: 35,
                ),
                onPressed: () => musicService.playNextSong(),
              ),
              IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: new Color(colors[1]).withOpacity(.5),
                    size: 20,
                  ),
                  onPressed: () {
                    musicService.fetchAlbums();
                  }
              ),
            ],
          )
      ),
    );
  }
}
