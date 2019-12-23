import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Tunein/components/albumCard.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/plugins/nano.dart';

class AlbumsPage extends StatefulWidget {
  AlbumsPage({Key key}) : super(key: key);

  _AlbumsPageState createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {

  final musicService = locator<MusicService>();


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

          return Container(
            child: ListView.builder(itemBuilder: (context, index){
              return Row(
                children: <Widget>[
                  Expanded(
                    child:  AlbumCard(album: _albums[3*index]),
                    flex: 4,
                  ),
                  Expanded(
                    child:  AlbumCard(album: _albums[(3*index)+1]),
                    flex: 4,
                  ),
                  Expanded(
                    child:  AlbumCard(album: _albums[(3*index)+2]),
                    flex: 4,
                  )
                ],
              );
            },
            itemCount: (_albums.length/3).round()>=_albums.length/3?(_albums.length/3).round():(_albums.length/3).round()+1,
            ),
          );
        },
      ),
    );
  }


}
