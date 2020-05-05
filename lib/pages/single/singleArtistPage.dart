import 'dart:io';
import 'dart:ui';

import 'package:Tunein/components/AlbumSongCell.dart';
import 'package:Tunein/components/artistAlbumsList.dart';
import 'package:Tunein/components/card.dart';
import 'package:Tunein/components/albumSongList.dart';
import 'package:Tunein/components/cards/optionsCard.dart';
import 'package:Tunein/components/itemListDevider.dart';
import 'package:Tunein/components/pageheader.dart';
import 'package:Tunein/components/scrollbar.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/pages/single/singleAlbum.page.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:Tunein/values/contextMenus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:Tunein/components/ArtistCell.dart';

class SingleArtistPage extends StatelessWidget {

  Artist artist;
  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();


  SingleArtistPage(this.artist);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    final double itemWidth = size.width / 3;
    if(artist!=null){
      List<int> bgColor=(artist.colors!=null && artist.colors.length!=0)?artist.colors:themeService.defaultColors;
      return new Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Material(
              child: Container(
                child: new Container(
                  margin: EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          child: FadeInImage(
                            placeholder: AssetImage('images/artist.jpg'),
                            fadeInDuration: Duration(milliseconds: 200),
                            fadeOutDuration: Duration(milliseconds: 100),
                            image: artist.coverArt != null
                                ? FileImage(
                              new File(artist.coverArt),
                            )
                                : AssetImage('images/artist.jpg'),
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
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      (artist.name == null)
                                          ? "Unknon Artist"
                                          : artist.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: 17.5,
                                        fontWeight: FontWeight.w700,
                                        color: bgColor!=null?Color(bgColor[2]).withAlpha(200):Colors.white,
                                      ),
                                    ),
                                  ),
                                  Material(
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
                                                color: bgColor!=null?Color(bgColor[2]).withAlpha(200):Colors.white70,
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
                                        switch(choice.id){
                                          case 1: {
                                            musicService.playAllArtistAlbums(artist);
                                            break;
                                          }
                                          case 2:{
                                            musicService.suffleAllArtistAlbums(artist);
                                            break;
                                          }
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return artistCardContextMenulist.map((ContextMenuOptions choice) {
                                          return PopupMenuItem<ContextMenuOptions>(
                                            value: choice,
                                            child: Text(choice.title),
                                          );
                                        }).toList();
                                      },
                                    ),
                                    color: Colors.transparent,
                                  )
                                ],

                              ),
                              Text(
                                (artist.albums.length == 0)
                                    ? "No Albums"
                                    : "${artist.albums.length} ${artist.albums.length>1?"albums":"album"}",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w400,
                                  color: bgColor!=null?Color(bgColor[2]).withAlpha(200):Colors.white,
                                ),
                              ),
                              Text(
                                (artist.albums.length == 0)
                                    ? "No Songs"
                                    : "${countSongsInAlbums(artist.albums)} ${countSongsInAlbums(artist.albums)>1?"songs":"song"}",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w400,
                                  color: bgColor!=null?Color(bgColor[2]).withAlpha(150):Colors.white,
                                ),
                              ),
                              Container(
                                alignment: Alignment.bottomRight,
                                margin: EdgeInsets.all(5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      child: Text(
                                        "${Duration(milliseconds: sumDurationsofArtist(artist).floor()).inMinutes} min",
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
                              )
                            ],
                          ),
                          padding: EdgeInsets.all(10),
                          alignment: Alignment.topCenter,
                        ),
                      )
                    ],
                  ),
                ),
                height: 200,
                color: bgColor!=null?Color(bgColor[0]):MyTheme.bgBottomBar,
              ),
            ),
            Flexible(
              child: Container(
                color: MyTheme.bgBottomBar,
                child: CustomScrollView(
                  scrollDirection: Axis.vertical,
                  slivers: <Widget>[
                    SliverAppBar(
                      elevation: 0,
                      expandedHeight: 131,
                      backgroundColor: MyTheme.bgBottomBar,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Column(
                          children: <Widget>[
                            ItemListDevider(DeviderTitle: "More choices"),
                            Container(
                              color:MyTheme.bgBottomBar,
                              height: 120,
                              child: ListView.builder(
                                itemExtent: 180,
                                itemCount: 1,
                                cacheExtent:MediaQuery.of(context).size.width ,
                                addAutomaticKeepAlives: true,
                                shrinkWrap: false,

                                scrollDirection: Axis.horizontal,

                                itemBuilder: (context, index){
                                  return MoreOptionsCard(
                                    imageUri: artist.coverArt,
                                    colors: artist.colors,
                                    bottomTitle: "Most Played",
                                    onPlayPressed: (){
                                      musicService.playMostPlayedOfArtist(artist);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      automaticallyImplyLeading: false,
                      stretch: true,
                      stretchTriggerOffset: 166,
                      floating: true,
                    ),
                    SliverPersistentHeader(
                      delegate: DynamicSliverHeaderDelegate(
                          child: Material(
                            child: ItemListDevider(DeviderTitle: "Albums"),
                            color: Colors.transparent,
                          ),
                          minHeight: 35,
                          maxHeight: 35
                      ),
                      pinned: true,
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 3,
                        crossAxisSpacing: 3,
                        childAspectRatio: (itemWidth / (itemWidth + 50)),
                      ),
                      delegate: SliverChildBuilderDelegate((context, index){
                        int newIndex = (index%3)+2;
                        return GestureDetector(
                          onTap: () {
                            goToSingleArtistPage(context, artist.albums[index]);
                          },
                          child: Material( // the material widget here helps with the themes
                            //the non inclusion of it means you get double bars underneath the text
                            //this is not a must but you need to find a way to give a theme to your widget
                            //Material widget is the easiest and the one i am using in this app
                            child: AlbumGridCell(artist.albums[index],135,80,
                              animationDelay: (50*newIndex) - (index<6?((6-index)*160):0),
                            ),
                            color: Colors.transparent,
                          ),
                        );
                      },
                        childCount: artist.albums.length,
                      ),
                    )
                    /*AlbumSongList(album)*/
                  ],
                ),
              ),

            ),
          ],
        ),
      );

    }
  }

  int countSongsInAlbums(List<Album> albums){
    int count=0;
    albums.forEach((elem){
      count+=elem.songs.length;
    });
    return count;
  }


  double sumDurationsofArtist(Artist artist) {
    double FinalDuration = 0;

    artist.albums.forEach((album){
      album.songs.forEach((elem) {
        FinalDuration += elem.duration;
      });
    });

    return FinalDuration;
  }

  void goToSingleArtistPage(context, Album album){
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SingleAlbumPage(null,album:album),
      ),
    );
  }
}
