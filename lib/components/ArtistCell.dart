import 'dart:io';

import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:flutter/material.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/globals.dart';

class ArtistGridCell extends StatelessWidget {
  final void Function(ContextMenuOptions) onContextSelect;
  final void Function(ContextMenuOptions) onContextCancel;
  List<ContextMenuOptions> choices;
  ArtistGridCell(this.artist, this.imageHeight, this.panelHeight,{this.onContextCancel, this.onContextSelect, this.choices});
  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();
  @required
  final Artist artist;
  final double imageHeight;
  final double panelHeight;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: themeService.getArtistColors(artist).asStream(),
      builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
        List<int> songColors;
        if(snapshot.hasData) {
          songColors=snapshot.data;
        }

        int numberOfSongsPresentForThisArtist =countSongsInAlbums(artist.albums);
        return AnimatedContainer(
          duration: Duration(milliseconds: 150),
            curve: Curves.fastOutSlowIn,
            decoration: BoxDecoration(
              color: (songColors!=null?new Color(songColors[0]).withAlpha(100):MyTheme.darkgrey).withOpacity(.7),
              backgroundBlendMode: BlendMode.colorBurn
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                /*artist.coverArt == null ? Image.asset("images/artist.jpg",height: imageHeight+2, width: double.infinity, fit: BoxFit.cover) : Image(
                  image: FileImage(File(artist.coverArt)),
                  fit: BoxFit.fill,
                  height: imageHeight+2,
                  colorBlendMode: BlendMode.darken,
                ),*/
                FadeInImage(
                  placeholder: AssetImage('images/artist.jpg'),
                  fadeInDuration: Duration(milliseconds: 200),
                  fadeOutDuration: Duration(milliseconds: 100),
                  height: imageHeight+2,
                  repeat: ImageRepeat.noRepeat,
                  fit: artist.coverArt != null?BoxFit.fill:BoxFit.cover,
                  image: artist.coverArt != null
                      ? FileImage(
                    new File(artist.coverArt),
                  )
                      : AssetImage('images/artist.jpg'),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5,vertical: 2),
                    width: double.infinity,
                    color: songColors!=null?new Color(songColors[0]).withAlpha(225):MyTheme.darkgrey,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            artist.name!=null?artist.name:"Unknown Name",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13.5,
                                color: (songColors!=null?new Color(songColors[1]):Colors.black87).withOpacity(.7),
                                fontWeight: FontWeight.w700
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex:9,
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    child: Text(
                                      artist.albums.length!=0?"${artist.albums.length} ${artist.albums.length>1?"Albums":"Album"}":"No Albums",
                                      overflow: TextOverflow.ellipsis,
                                      strutStyle: StrutStyle(
                                          height: 0.8,
                                          forceStrutHeight: true
                                      ),
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: (songColors!=null?new Color(songColors[1]):Colors.black54).withOpacity(.7)
                                      ),
                                    ),
                                    padding: EdgeInsets.only(bottom: 2),
                                  ),
                                  Text(
                                    artist.albums.length!=0?"${numberOfSongsPresentForThisArtist} ${numberOfSongsPresentForThisArtist>1?"Songs":"Song"}":"No Songs",
                                    overflow: TextOverflow.ellipsis,
                                    strutStyle: StrutStyle(
                                        height: 0.8,
                                        forceStrutHeight: true
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: (songColors!=null?new Color(songColors[1]):Colors.black54).withOpacity(.7),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child:  choices!=null?Material(
                                child: PopupMenuButton<ContextMenuOptions>(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      splashColor: MyTheme.darkgrey,
                                      radius: 30.0,
                                      child: Padding(
                                          padding: const EdgeInsets.only(right: 10.0),
                                          child:Icon(
                                            IconData(0xea7c, fontFamily: 'boxicons'),
                                            size: 22,
                                            color: (songColors!=null?new Color(songColors[1]):Colors.black54).withOpacity(.7),
                                          )
                                      ),
                                    ),
                                  ),
                                  elevation: 3.2,
                                  onCanceled: () {
                                    print('You have not chosen anything');
                                  },
                                  tooltip: 'Playing options',
                                  onSelected: (ContextMenuOptions choice){
                                    onContextSelect!=null?onContextSelect(choice):null;
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return choices.map((ContextMenuOptions choice) {
                                      return PopupMenuItem<ContextMenuOptions>(
                                        value: choice,
                                        child: Text(choice.title),
                                      );
                                    }).toList();
                                  },
                                ),
                                color: Colors.transparent,
                              ):Container(),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ));
      },
    );
  }

  int countSongsInAlbums(List<Album> albums){
    int count=0;
    albums.forEach((elem){
      count+=elem.songs.length;
    });
    return count;
  }

}

