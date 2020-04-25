import 'dart:io';

import 'package:Tunein/components/card.dart';
import 'package:Tunein/components/genericSongList.dart';
import 'package:Tunein/components/scrollbar.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:Tunein/models/playback.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/dialogService.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/values/contextMenus.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';


class EditPlaylist extends StatefulWidget {

  Playlist playlist;

  EditPlaylist({this.playlist});

  @override
  _EditPlaylistState createState() => _EditPlaylistState();
}

class _EditPlaylistState extends State<EditPlaylist> {
  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();

  List<String> removedSongsIds=[];
  List<Tune> songsToBeRemoved=[];
  ScrollController controller = new ScrollController();

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: (){
        OnPopWithUnsavedContent();
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          child: Column(
            children: <Widget>[
              Material(
                child: Container(
                    child: new Container(
                      margin: EdgeInsets.all(0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height:60,
                              width:60,
                              child: FadeInImage(
                                placeholder: AssetImage('images/track.png'),
                                fadeInDuration: Duration(milliseconds: 200),
                                fadeOutDuration: Duration(milliseconds: 100),
                                image: widget.playlist.covertArt != null
                                    ? FileImage(
                                  new File(widget.playlist.covertArt),
                                )
                                    : AssetImage('images/track.png'),
                              ),
                            ),
                            flex: 2,
                          ),
                          Expanded(
                            flex: 8,
                            child: Container(
                              margin: EdgeInsets.all(0)
                                  .subtract(EdgeInsets.only(left: 0))
                                  .add(EdgeInsets.only(top: 0)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          (widget.playlist.name == null)
                                              ? "Unnamed Playlist"
                                              : widget.playlist.name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 17.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          songsToBeRemoved.length!=0?IconButton(
                                            onPressed: () {
                                              clearAllChanges();
                                            },
                                            iconSize: 26,
                                            tooltip: "cancel all changes",
                                            splashColor: MyTheme.grey700,
                                            icon: Icon(
                                              Icons.close,
                                              color: MyTheme.darkRed,
                                            ),
                                          ):Container(),
                                          IconButton(
                                            onPressed: () {
                                              saveBackTheRemovedSongs();
                                            },
                                            iconSize: 26,
                                            tooltip: "save all changes",
                                            splashColor: MyTheme.grey700,
                                            icon: Icon(
                                              Icons.check,
                                              color: MyTheme.darkRed,
                                            ),
                                          )
                                        ],
                                      )
                                    ],
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                  ),
                                  Text(
                                    (widget.playlist.songs.length == 0)
                                        ? "No Songs"
                                        : "${widget.playlist.songs.length} song(s) ${removedSongsIds.length!=0?"(-${removedSongsIds.length})":""}",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(10),
                              alignment: Alignment.center,
                              height: 100,
                            ),
                          )
                        ],
                      ),
                      height: 100,
                    ),
                    color: MyTheme.bgBottomBar,
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top
                    )
                ),
                elevation: 5.0,
              ),
              Flexible(
                child: ReorderableList(
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
                                itemCount: widget.playlist.songs.length,
                                itemBuilder: (context, index) {
                                  if(!removedSongsIds.contains(widget.playlist.songs[index].id)){
                                    return DelayedReorderableListener(
                                      child: ReorderableItem(
                                        key: Key(widget.playlist.songs[index].id),
                                        childBuilder: (context, state){
                                          return MyCard(
                                            song: widget.playlist.songs[index],
                                            choices: editPlaylistSongCardContextMenulist,
                                            ScreenSize: screenSize,
                                            onContextSelect: (choice){
                                              switch(choice.id){
                                                case 1:{
                                                  deleteSongFromPlaylist(widget.playlist.songs[index]);
                                                }
                                              }
                                            },
                                            onContextCancel: (choice){
                                              print("Cancelled");
                                            },
                                            onTap: (){
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  }else{
                                    return MyCard(
                                      song: new Tune("NOT A REAL${index}",
                                          "(${widget.playlist.songs[index].title}) To be deleted",
                                          "(${widget.playlist.songs[index].artist}) Tap to Undo",
                                          "",
                                          0,
                                          "",
                                          null,
                                          [],
                                          null
                                      ),
                                      choices: null,
                                      onContextSelect: (choice){

                                      },
                                      onContextCancel: (choice){
                                        print("Cancelled");
                                      },
                                      onTap: (){
                                        undoDeletingDong(widget.playlist.songs[index].id);
                                      },
                                      colors: [MyTheme.darkBlack,MyTheme.darkRed.withAlpha(200)],
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      MyScrollbar(
                        controller: controller,
                        color: MyTheme.darkBlack,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );

  }

  void deleteSongFromPlaylist(Tune song) async {
    int indexOfSongToDelete = widget.playlist.songs.indexOf(song);
    if(indexOfSongToDelete!=-1){
      print("will delete song title : ${song.title}");
      // widget.playlist.songs.removeAt(indexOfSongToDelete);
      removedSongsIds.add(song.id);
      songsToBeRemoved.add(song);
      setState(() {

      });
      print(widget.playlist.songs.length);
    }
  }

  Future<bool> OnPopWithUnsavedContent() async{
    if(removedSongsIds.length >0){
      String deletionMessage="Unsaved changes, would you like to save now? Songs that would be deleted : ";
      songsToBeRemoved.forEach((song){
        deletionMessage="${deletionMessage} ${song.title}";
      });
      deletionMessage="${deletionMessage} ?";
      deletionMessage="${deletionMessage} ?";
      bool deleting = await DialogService.showConfirmDialog(context,
          title: "Unsaved Changes",
          confirmButtonText: "SAVE & QUIT",
          cancelButtonText: "Don't save",
          message: deletionMessage,
          titleColor: MyTheme.darkRed
      );
      if(deleting!=null && deleting==true){
        ///Modifying the playlist name is not implemented yet so the value in the MapEntry is null
        Navigator.of(context).pop(MapEntry<List<String>,String>(removedSongsIds,null));
      }else{
        //This will signal that no songs have been deleted
        Navigator.of(context).pop(MapEntry<List<String>,String>(new List<String>(0),null));
      }
    }else{
      Navigator.of(context).pop(MapEntry<List<String>,String>(new List<String>(0),null));
    }

  }

  void saveBackTheRemovedSongs({String message}) async {
    if(removedSongsIds.length!=0){

      String deletionMessage="Delete : ";
      songsToBeRemoved.forEach((song){
        deletionMessage="${deletionMessage} ${song.title}";
      });
      deletionMessage="${deletionMessage} ?";
      bool deleting = await DialogService.showConfirmDialog(context,
          title: "Confirm Your Action",
          message: message??deletionMessage,
          titleColor: MyTheme.darkRed
      );
      if(deleting!=null && deleting==true){
        ///Modifying the playlist name is not implemented yet so the value in the MapEntry is null
        Navigator.of(context).pop(MapEntry<List<String>,String>(removedSongsIds,null));
      }
    }
  }

  void clearAllChanges(){
    removedSongsIds.clear();
    songsToBeRemoved.clear();
    setState(() {

    });
  }

  void undoDeletingDong(String id){
    removedSongsIds.remove(id);

    songsToBeRemoved.removeWhere((song){
      return song.id==id;
    });
    setState(() {

    });
  }
}
