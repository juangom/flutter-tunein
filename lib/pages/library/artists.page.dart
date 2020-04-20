import 'dart:io';

import 'package:Tunein/components/AlbumSongCell.dart';
import 'package:Tunein/components/ArtistCell.dart';
import 'package:Tunein/components/gridcell.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/pages/single/singleArtistPage.dart';
import 'package:Tunein/values/contextMenus.dart';
import 'package:flutter/material.dart';
import 'package:Tunein/components/albumCard.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/pages/single/singleAlbum.page.dart';
import 'package:rxdart/rxdart.dart';
import 'package:animations/animations.dart';

class ArtistsPage extends StatefulWidget {
  PageController controller;
  ArtistsPage({Key key, controller}) : this.controller = controller != null ? controller : new PageController(), super(key: key);

  _ArtistsPageState createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> with AutomaticKeepAliveClientMixin<ArtistsPage> {



  final musicService = locator<MusicService>();
  BehaviorSubject<Album> currentAlbum= new BehaviorSubject<Album>();
  ContainerTransitionType transitionType = ContainerTransitionType.fade;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    final double itemWidth = size.width / 3;
    return Container(
      child:  StreamBuilder(
        stream: musicService.artists$,
        builder: (BuildContext context,
            AsyncSnapshot<List<Artist>> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          if(snapshot.data.length==0){
            return Container();
          }
          final _artists = snapshot.data;
          return GridView.builder(
            padding: EdgeInsets.all(0),
            itemCount: _artists.length,
            cacheExtent: size.height/3,
            addAutomaticKeepAlives: false,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: (itemWidth / (itemWidth + 50)),
            ),
            itemBuilder: (BuildContext context, int index) {

              return OpenContainer(
                closedColor: Colors.transparent,
                openColor: Colors.transparent,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.zero)
                ),
                transitionDuration: Duration(milliseconds: 90),
                transitionType: transitionType,
                openBuilder: (BuildContext context, VoidCallback _) {
                  return SingleArtistPage( _artists[index]);
                },
                tappable: false,
                closedBuilder: (BuildContext context, VoidCallback openContainer){
                  return GestureDetector(
                    onTap: () {
                      openContainer();
                      //goToSingleArtistPage(_artists[index]);
                    },
                    child: ArtistGridCell(
                      _artists[index],
                      125,
                      80,
                      choices: artistCardContextMenulist,
                      onContextSelect: (choice){
                        switch(choice.id){
                          case 1: {
                            musicService.playAllArtistAlbums(_artists[index]);
                            break;
                          }
                          case 2:{
                            musicService.suffleAllArtistAlbums(_artists[index]);
                            break;
                          }
                        }
                      },
                      onContextCancel: (choice){
                        print("Cancelled");
                      },
                      Screensize: size,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }




  void goToSingleArtistPage(Artist artist){
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SingleArtistPage(artist),
      ),
    );
  }

  @override
  bool get wantKeepAlive {
    return true;
  }


}
