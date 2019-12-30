import 'dart:io';

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
              Container(
                child: ListView.builder(itemBuilder: (context, index){
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child:  AlbumCard(album: _albums[3*index],
                          onTap: (){
                            goToAlbumSongsList(_albums[3*index]);
                          },
                        ),
                        flex: 4,
                      ),
                      Expanded(
                        child:  AlbumCard(album: _albums[(3*index)+1],
                          onTap: (){
                            goToAlbumSongsList(_albums[(3*index)+1]);
                          },
                        ),
                        flex: 4,
                      ),
                      Expanded(
                        child:  AlbumCard(album: _albums[(3*index)+2],
                          onTap: (){
                            goToAlbumSongsList(_albums[(3*index)+2]);
                          },
                        ),
                        flex: 4,
                      )
                    ],
                  );
                },
                  itemCount: (_albums.length/3).round()>=_albums.length/3?(_albums.length/3).round():(_albums.length/3).round()+1,
                ),
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
