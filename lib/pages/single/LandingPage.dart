import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:Tunein/components/cards/AnimatedDialog.dart';
import 'package:Tunein/components/cards/PreferedPicks.dart';
import 'package:Tunein/components/cards/expandableItems.dart';
import 'package:Tunein/components/genericSongList.dart';
import 'package:Tunein/components/itemListDevider.dart';
import 'package:Tunein/components/trackListDeck.dart';
import 'package:Tunein/components/trackListDeckItem.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playback.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/plugins/upnp.dart';
import 'package:Tunein/services/castService.dart';
import 'package:Tunein/services/dialogService.dart';
import 'package:Tunein/services/fileService.dart';
import 'package:flutter/rendering.dart';
import 'package:popup_menu/popup_menu.dart';
import 'package:rxdart/rxdart.dart';
import 'package:upnp/upnp.dart' as upnp;
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicMetricsService.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/utils/ConversionUtils.dart';
import 'package:Tunein/values/contextMenus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';








class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {

  final metricService = locator<MusicMetricsService>();
  final musicService = locator<MusicService>();
  final castService = locator<CastService>();
  final FileService = locator<fileService>();

  Map<String,TrackListDeckItemState> deckItemState;
  Map<String,Key> deckItemKeys;
  Map<String, BehaviorSubject> deckItemStateStream;
  Map<String, PopupMenu> deckItemMenu;


  @override
  void initState() {
    deckItemState={
      "play":TrackListDeckItemState(),
      "save": TrackListDeckItemState(),
      "shuffle": TrackListDeckItemState(),

    };
    deckItemKeys={
      "save":GlobalKey(),
      "play": GlobalKey(),
      "shuffle": GlobalKey(),
    };

    deckItemStateStream={
      "save": BehaviorSubject<Map<String,dynamic>>()
    };

    deckItemMenu={
      "save":null,
      "play": null,
      "shuffle": null,
    };

  }

  Map<String,dynamic> getMostPlayedSongs(Map<String,dynamic> metricValues){

    Map<String,dynamic> newValue = metricValues??metricService.metrics.value[MetricIds.MET_GLOBAL_SONG_PLAY_TIME];
    if(newValue.length==0){
      return null;
    }
    var sortedKeys = newValue.keys.toList(growable:false)
      ..sort((k1, k2) => int.parse(newValue[k2]).compareTo(int.parse(newValue[k1])));
    Map<String,String> sortedMap = new Map
        .fromIterable(sortedKeys, key: (k) => k, value: (k) => newValue[k]);

    Map<Tune,int> newSongMap = sortedMap.map((key, value) {
      Tune newKey = musicService.songs$.value.firstWhere((element) => element.id==key, orElse: ()=>null);
      return MapEntry(newKey, int.tryParse(value));
    });

    Map<String, int> artistsAndTheirPresenceInMostPlayed =Map();
    newSongMap.keys.toList().forEach((element) {
      artistsAndTheirPresenceInMostPlayed[element.artist]=artistsAndTheirPresenceInMostPlayed[element.artist]!=null?artistsAndTheirPresenceInMostPlayed[element.artist]++:1;
    });
    if(newSongMap.length<10){
      //picking a random song to add to fill the 10 songs mark
      //picking will be done from the artists in the existing songs with a coefficient based on the number of songs in the most played
      for(int i=0; i < 10-newSongMap.length; i++){

        //Sorting the presenceMap
        var sortedPresenceKeys = newValue.keys.toList(growable:false)
          ..sort((v1, v2) => newValue[v2].compareTo(newValue[v1]));
        Map<String,int> sortedPresenceMap = new Map
            .fromIterable(sortedPresenceKeys, key: (k) => k, value: (k) => int.parse(newValue[k]));

        //Picking the artist with the lowest priority without having too many songs from same artist
        int indexOfArtistWithPriority =0;
        String nameOfArtistsToPickFrom = sortedPresenceMap.keys.toList()[indexOfArtistWithPriority];
        while(sortedPresenceMap[nameOfArtistsToPickFrom]<2 && indexOfArtistWithPriority< sortedPresenceMap.keys.toList().length){
          indexOfArtistWithPriority++;
          nameOfArtistsToPickFrom = sortedPresenceMap.keys.toList()[indexOfArtistWithPriority];
        }
        Artist artistToPickFrom = musicService.artists$.value.firstWhere((element) => element.name==nameOfArtistsToPickFrom, orElse: ()=>null);
        if(artistToPickFrom==null){
          continue;
        }
        //MathUtils should be created for this kind of functions
        int getRandomFromRange(int min, int max){
          Random rnd;
          int min = 5;
          int max = 10;
          rnd = new Random();
          return min + rnd.nextInt(max - min);
        }
        //Tis will pick random numbers from the albums length and then from the songs length and add them use them as indexes to get random songs to add.
        int albumIndex = getRandomFromRange(0, artistToPickFrom.albums.length);
        int songIndex = getRandomFromRange(0, artistToPickFrom.albums[albumIndex].songs.length);
        while(newSongMap.keys.toList().firstWhere((element) => element.id==artistToPickFrom.albums[albumIndex].songs[songIndex].id, orElse: ()=>null)!=null){
          songIndex =getRandomFromRange(0, artistToPickFrom.albums[albumIndex].songs.length);
        }

        newSongMap[artistToPickFrom.albums[albumIndex].songs[songIndex]] = newSongMap.values.toList().last;
        artistsAndTheirPresenceInMostPlayed[artistToPickFrom.name]++;
      }
    }

    return {
      "artistsPresence" : artistsAndTheirPresenceInMostPlayed,
      "mostPlayedSongs" : newSongMap.keys.toList(),
    };
  }

  List<Album> getTopAlbum(Map<String,dynamic> GlobalSongPlayTime){

    Map<String,dynamic> newValue = GlobalSongPlayTime??metricService.metrics.value[MetricIds.MET_GLOBAL_SONG_PLAY_TIME];
    if(GlobalSongPlayTime.length==0){
      return null;
    }
    var sortedKeys = newValue.keys.toList(growable:false)
      ..sort((k1, k2) => int.parse(newValue[k2]).compareTo(int.parse(newValue[k1])));
    Map<String,String> sortedMap = new Map
        .fromIterable(sortedKeys, key: (k) => k, value: (k) => newValue[k]);

    Map<Tune,int> newSongMap = sortedMap.map((key, value) {
      Tune newKey = musicService.songs$.value.firstWhere((element) => element.id==key, orElse: ()=>null);
      return MapEntry(newKey, int.tryParse(value));
    });
    List<Album> topAlbums = newSongMap.keys.map((e) {
      return musicService.albums$.value.firstWhere((element) => element.title==e.album);
    }).toList();

    topAlbums = topAlbums.toSet().toList();
    return topAlbums;
  }

  /// [standardWidth] is the width of the images being reconstructed from the 8Bit
  ///
  ///
  /// [standardHeight] is the height of the images being reconstructed from the 8Bit
  ///
  ///
  /// [standardHeight] and [standardWidth] may need to be equal for the best merging output
  Widget getCombinedImages(List<List<int>> image8BitList, {double standardWidth =400, double standardHeight =400, double maxWidth =400}){
    double maxWidthPerImage = maxWidth/image8BitList.length;
      List<Image> imageList =  List.from(image8BitList.map((e) {
        return Image.memory(e,height: standardHeight, width: maxWidthPerImage, fit: BoxFit.cover,);
      }));
      int imageIndex=-1;
      double leftPosition = (standardWidth - maxWidthPerImage)/2;
      return Stack(
        overflow: Overflow.clip,
        children: imageList.map((e){
          imageIndex++;
          return Positioned(
            child: e,
            left: (imageIndex*maxWidthPerImage),
            top: 0,
            width: maxWidthPerImage,
            height: standardHeight,
          );
        }).toList()
      );
  }



  @override
  Widget build(BuildContext context) {

    Size screensize = MediaQuery.of(context).size;
    Future<List<int>> Asset8bitList = Future.sync(() async{
      ByteData dibd = await rootBundle.load("images/artist.jpg");
      List<int> defaultImageBytes = dibd.buffer.asUint8List();
      return defaultImageBytes;
    });
    return Container(
      color: MyTheme.darkBlack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: MediaQuery.of(context).padding,
          ),
          Flexible(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Preferred Pics",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: StreamBuilder(
                    stream: metricService.getOrCreateSingleSettingStream(MetricIds.MET_GLOBAL_SONG_PLAY_TIME),
                    builder: (context, AsyncSnapshot<dynamic> msnapshot){
                      if(!msnapshot.hasData){
                        print("DATA IS HERE ${msnapshot.data}");
                        return Container(
                          child: PreferredPicks(
                            bottomTitle: "Most Played",
                            colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                          ),
                        );
                      }
                      Map<String,dynamic> mostPlayed = getMostPlayedSongs(msnapshot.data);
                      if(mostPlayed==null){
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          child: Container(
                            color: MyTheme.darkBlack,
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: Center(
                              child: Text("No Data Found",
                                style: TextStyle(
                                   color: MyTheme.grey300,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 25
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      Map<String,int> artistPresence = mostPlayed["artistsPresence"];
                      List<Tune> mostPlayedSongs = mostPlayed["mostPlayedSongs"];
                      List<Artist> artistToPutToWidgetBackground = artistPresence.keys.toList().sublist(0,4).map((e) {
                        return musicService.artists$.value.firstWhere((element) => element.name==e);
                      }).toList();
                      Future<List<List<int>>> backgroundimagesForMostPlayedSongs = Future.wait(artistToPutToWidgetBackground.map((e) async{
                        return await ConversionUtils.FileUriTo8Bit(e.coverArt);
                      }).toList());
                      return Container(
                        height:150,
                        child: ListView.builder(
                          itemBuilder: (context, index){
                            return Material(
                                child: StreamBuilder(
                                  stream: artistToPutToWidgetBackground.length!=0?backgroundimagesForMostPlayedSongs.asStream():Future.wait([Asset8bitList]).asStream(),
                                  builder: (context, AsyncSnapshot<List<List<int>>> snapshot){
                                    GlobalKey MostPlayedKey = new GlobalKey();
                                    return AnimatedSwitcher(
                                      duration: Duration(milliseconds: 200),
                                      switchInCurve: Curves.easeInToLinear,
                                      child: !snapshot.hasData?Container(
                                        child: PreferredPicks(
                                          bottomTitle: "Most Played",
                                          colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                        ),
                                      ):GestureDetector(
                                        child: Container(
                                          margin: EdgeInsets.only(right: 8),
                                          child: RepaintBoundary(
                                            child: PreferredPicks(
                                              bottomTitle: "Most Played",
                                              colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                              backgroundWidget: getCombinedImages(snapshot.data, standardHeight: 150, standardWidth: 200, maxWidth: 200),
                                            ),
                                            key: MostPlayedKey,
                                          ),
                                        ),
                                        onTap: (){
                                          showDialog(context: context,
                                              builder: (_){
                                                return Container(
                                                  child: AnimatedDialog(
                                                    dialogContent: Center(
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: <Widget>[
                                                          Container(
                                                            height: screensize.height*0.2,
                                                            width: screensize.width*0.85,
                                                            child: PreferredPicks(
                                                              bottomTitle: "Most Played Songs' List",
                                                              colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                                              backgroundWidget: getCombinedImages(snapshot.data, standardHeight: screensize.height*0.2, standardWidth: screensize.width*0.85, maxWidth: screensize.width*0.85),
                                                            ),
                                                          ),
                                                          Container(
                                                            color: MyTheme.darkBlack,
                                                            height: 62,
                                                            width: screensize.width*0.85,
                                                            margin: EdgeInsets.only(bottom: 5),
                                                            child: TrackListDeck(
                                                              items: [
                                                                TrackListDeckItem(
                                                                  initialState: deckItemState["play"],
                                                                  globalWidgetKey: deckItemKeys["play"],
                                                                  title: "Play All",
                                                                  subtitle:"Play All Tracks",
                                                                  icon: Icon(
                                                                    Icons.play_arrow,
                                                                  ),
                                                                  onTap: (){
                                                                    musicService.updatePlaylist(mostPlayedSongs);
                                                                    musicService.playMusic(mostPlayedSongs[0]);
                                                                  },
                                                                ),
                                                                TrackListDeckItem(
                                                                  initialState: deckItemState["shuffle"],
                                                                  globalWidgetKey: deckItemKeys["shuffle"],
                                                                  title: "Shuffle",
                                                                  subtitle:"Shuffle All Tracks",
                                                                  icon: Icon(
                                                                    Icons.shuffle,
                                                                  ),
                                                                  onTap: (){
                                                                    musicService.updatePlaylist(mostPlayedSongs);
                                                                    musicService.updatePlayback(Playback.shuffle);
                                                                    musicService.stopMusic();
                                                                    musicService.playMusic(musicService.playlist$.value.value[0]);
                                                                  },
                                                                ),
                                                                TrackListDeckItem(
                                                                  initialState: deckItemState["save"],
                                                                  globalWidgetKey: deckItemKeys["save"],
                                                                  stateStream: deckItemStateStream["save"],
                                                                  title: "Save",
                                                                  subtitle:"Save As Playlist",
                                                                  iconColor: MyTheme.grey300,
                                                                  withBadge: false,
                                                                  icon: Icon(
                                                                    Icons.save,
                                                                  ),
                                                                  onTap: () async{
                                                                   bool result = await  DialogService.showConfirmDialog(context,
                                                                      message: "Save the most played songs as a playlist",
                                                                      title: "Save as a Playlist"
                                                                    );
                                                                    if(result){
                                                                      deckItemStateStream["save"].add(
                                                                          {
                                                                            "withBadge":true,
                                                                            "badgeContent": Icon(
                                                                              Icons.hourglass_empty,
                                                                              color: MyTheme.darkRed,
                                                                               size: 17,
                                                                            ),
                                                                            "badgeColor":Colors.transparent,
                                                                            "iconColor":null,
                                                                            "icon":null,
                                                                            "title":"Saving"
                                                                          }
                                                                      );
                                                                      Uint8List bytesList = await ConversionUtils.fromWidgetGlobalKeyToImageByteList(MostPlayedKey);
                                                                      Uri fileURI = await FileService.saveBytesToFile(bytesList);
                                                                      Playlist newPlaylist = new Playlist(
                                                                        "Most Played ${DateTime.now().toIso8601String()}",
                                                                        mostPlayedSongs,
                                                                        PlayerState.stopped,
                                                                        fileURI.path
                                                                      );

                                                                      musicService.addPlaylist(newPlaylist).then(
                                                                          (value){
                                                                            deckItemStateStream["save"].add(
                                                                                {
                                                                                  "withBadge":false,
                                                                                  "badgeContent": null,
                                                                                  "badgeColor":null,
                                                                                  "iconColor":MyTheme.darkRed,
                                                                                  "icon":null,
                                                                                  "title":"Saved !"
                                                                                }
                                                                            );

                                                                            Future.delayed(Duration(milliseconds: 1000), (){
                                                                              deckItemStateStream["save"].add(
                                                                                  {
                                                                                    "withBadge":false,
                                                                                    "badgeContent": null,
                                                                                    "badgeColor":null,
                                                                                    "iconColor":MyTheme.grey300,
                                                                                    "icon":Icon(
                                                                                      Icons.save,
                                                                                    ),
                                                                                    "title":"Save"
                                                                                  }
                                                                              );
                                                                            });
                                                                          }
                                                                      );
                                                                    }
                                                                    return null;
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                                                            ),
                                                            height: screensize.height*0.5,
                                                            width: screensize.width*0.85,
                                                            child: GenericSongList(
                                                              songs: mostPlayedSongs,
                                                              screenSize: screensize,
                                                              staticOffsetFromBottom: 100.0,
                                                              bgColor: null,
                                                              contextMenuOptions: (song){
                                                                return songCardContextMenulist;
                                                              },
                                                              onContextOptionSelect: (choice,tune) async{
                                                                switch(choice.id){
                                                                  case 1: {
                                                                    musicService.playOne(tune);
                                                                    break;
                                                                  }
                                                                  case 2:{
                                                                    musicService.startWithAndShuffleQueue(tune, mostPlayedSongs);
                                                                    break;
                                                                  }
                                                                  case 3:{
                                                                    musicService.startWithAndShuffleAlbum(tune);
                                                                    break;
                                                                  }
                                                                  case 4:{
                                                                    musicService.playAlbum(tune);
                                                                    break;
                                                                  }
                                                                  case 5:{
                                                                    if(castService.currentDeviceToBeUsed.value==null){
                                                                      upnp.Device result = await DialogService.openDevicePickingDialog(context, null);
                                                                      if(result!=null){
                                                                        castService.setDeviceToBeUsed(result);
                                                                      }
                                                                    }
                                                                    musicService.castOrPlay(tune, SingleCast: true);
                                                                    break;
                                                                  }
                                                                  case 6:{
                                                                    upnp.Device result = await DialogService.openDevicePickingDialog(context, null);
                                                                    if(result!=null){
                                                                      musicService.castOrPlay(tune, SingleCast: true, device: result);
                                                                    }
                                                                    break;
                                                                  }
                                                                }
                                                              },
                                                              onSongCardTap: (song,state,isSelectedSong){
                                                                musicService.updatePlaylist([song]);
                                                                musicService.playOrPause(song);
                                                              },
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                                color: Colors.transparent
                            );
                          },
                          scrollDirection: Axis.horizontal,
                          itemCount: 1,
                          shrinkWrap: false,
                          itemExtent: 200,
                          physics: AlwaysScrollableScrollPhysics(),
                          cacheExtent: 122,
                        ),
                        padding: EdgeInsets.all(10),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Top Albums",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: StreamBuilder(
                    stream: metricService.getOrCreateSingleSettingStream(MetricIds.MET_GLOBAL_SONG_PLAY_TIME),
                    builder: (context, AsyncSnapshot<dynamic> msnapshot){
                      List<Album> topAlbums;
                      if(msnapshot.hasData){
                        topAlbums = getTopAlbum(msnapshot.data);
                        if(topAlbums==null){
                          return Container(
                            color: MyTheme.darkBlack,
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: Center(
                              child: Text("No Data Found",
                                style: TextStyle(
                                    color: MyTheme.grey300,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 25
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: msnapshot.hasData?Container(
                        height:190,
                        child: ListView.builder(
                          itemBuilder: (context, index){
                            return Material(
                                child: StreamBuilder(
                                  stream: topAlbums[index].albumArt!=null?ConversionUtils.FileUriTo8Bit(topAlbums[index].albumArt).asStream():Asset8bitList.asStream(),
                                  builder: (context, AsyncSnapshot<List<int>> snapshot){
                                    if(snapshot.hasError){

                                      return PreferredPicks(
                                        bottomTitle: "",
                                        colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                      );
                                    }
                                    return AnimatedSwitcher(
                                      duration: Duration(milliseconds: 200),
                                      switchInCurve: Curves.easeInToLinear,
                                      child: !snapshot.hasData?Container(
                                        child: PreferredPicks(
                                          bottomTitle: "Most Played",
                                          colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                        ),
                                      ):GestureDetector(
                                        child: Container(
                                          margin: EdgeInsets.only(right: 8),
                                          child: Stack(
                                            children: <Widget>[
                                              PreferredPicks(
                                                bottomTitle: "${topAlbums[index].title.split(' ').join('\n')}",
                                                backgroundWidget: getCombinedImages([snapshot.data], maxWidth: 122, standardWidth: 122, standardHeight: 190),
                                                colors: topAlbums[index].songs[0].colors.map((e){
                                                  return Color(e).withOpacity(.5).value;
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onTap: (){

                                        },
                                      ),
                                    );
                                  },
                                ),
                                color: Colors.transparent
                            );
                          },
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          shrinkWrap: false,
                          itemExtent: 122,
                          physics: AlwaysScrollableScrollPhysics(),
                          cacheExtent: 122,
                        ),
                        padding: EdgeInsets.all(10),
                      ):Container(height:190),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Preferred Pics",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height:150,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Material(
                            child: GestureDetector(
                              child: Container(
                                margin: EdgeInsets.only(right: 8),
                                child: PreferredPicks(
                                  bottomTitle: "Most Played",
                                  colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                ),
                              ),
                              onTap: (){

                              },
                            ),
                            color: Colors.transparent
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      shrinkWrap: false,
                      itemExtent: 200,
                      physics: AlwaysScrollableScrollPhysics(),
                      cacheExtent: 122,
                    ),
                    padding: EdgeInsets.all(10),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Preferred Pics",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height:190,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Material(
                            child: GestureDetector(
                              child: Container(
                                margin: EdgeInsets.only(right: 8),
                                child: PreferredPicks(
                                  bottomTitle: "Most Played",
                                  colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                ),
                              ),
                              onTap: (){

                              },
                            ),
                            color: Colors.transparent
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      shrinkWrap: false,
                      itemExtent: 122,
                      physics: AlwaysScrollableScrollPhysics(),
                      cacheExtent: 122,
                    ),
                    padding: EdgeInsets.all(10),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
