


import 'package:Tunein/pages/single/singleAlbum.page.dart';
import 'package:Tunein/pages/single/singleArtistPage.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final musicService = locator<MusicService>();

class PageRoutes{


  static void goToAlbumSongsList(Tune song, context) async {
    Album album = musicService.getAlbumFromSong(song);
    if(album!=null){
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SingleAlbumPage(null,
            album:album,
            heightToSubstract: 60,
          ),
        ),
      );
    }
  }

  static void goToSingleArtistPage(Tune song, context){
    Artist artist = musicService.getArtistTitle(song.artist);
    if(artist!=null){
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SingleArtistPage(artist, heightToSubstract: 60),
        ),
      );
    }
  }
}