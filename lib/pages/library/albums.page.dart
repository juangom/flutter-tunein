import 'dart:io';

import 'package:Tunein/components/AlbumSongCell.dart';
import 'package:Tunein/components/gridcell.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:flutter/material.dart';
import 'package:Tunein/components/albumCard.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/pages/single/singleAlbum.page.dart';
import 'package:rxdart/rxdart.dart';

class AlbumsPage extends StatefulWidget {

  PageController controller;
  AlbumsPage({Key key,controller}) : this.controller = controller != null ? controller : new PageController(), super(key: key);

  _AlbumsPageState createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {

  final musicService = locator<MusicService>();
  BehaviorSubject<Album> currentAlbum= new BehaviorSubject<Album>();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    final double itemWidth = size.width / 3;
    return Container(
      child:  StreamBuilder(
        stream: musicService.albums$,
        builder: (BuildContext context,
            AsyncSnapshot<List<Album>> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          if(snapshot.data.length==0){
            return Container();
          }
          final _albums = snapshot.data;
          return PageView(
            controller: widget.controller,
            children: <Widget>[
              GridView.builder(
                padding: EdgeInsets.all(0),
                itemCount: _albums.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  childAspectRatio: (itemWidth / (itemWidth + 50)),
                ),
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      goToAlbumSongsList(_albums[index]);
                    },
                    child: AlbumGridCell(_albums[index],135,80),
                  );
                },
              ),
              StreamBuilder<Album>(
                stream: currentAlbum,
                builder: (BuildContext context,
                    AsyncSnapshot<Album> snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }

                  final _album = snapshot.data;
                  return SingleAlbumPage(null, album: _album);
                },
              ),
            ],
            physics: NeverScrollableScrollPhysics(),
          );

        },
      ),
    );
  }


  void goToAlbumSongsList(album){
      currentAlbum.add(album);
      widget.controller.nextPage(duration: Duration(milliseconds: 200), curve: Curves.easeIn);
  }


}
