import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:Tunein/components/cards/AnimatedDialog.dart';
import 'package:Tunein/components/cards/PreferedPicks.dart';
import 'package:Tunein/components/cards/expandableItems.dart';
import 'package:Tunein/components/common/ShowWithFadeComponent.dart';
import 'package:Tunein/components/genericSongList.dart';
import 'package:Tunein/components/itemListDevider.dart';
import 'package:Tunein/components/songInfoWidget.dart';
import 'package:Tunein/components/stageScrollingPhysics.dart';
import 'package:Tunein/components/trackListDeck.dart';
import 'package:Tunein/components/trackListDeckItem.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playback.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/pages/single/singleAlbum.page.dart';
import 'package:Tunein/pages/single/singleArtistPage.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/plugins/upnp.dart';
import 'package:Tunein/services/castService.dart';
import 'package:Tunein/services/dialogService.dart';
import 'package:Tunein/services/fileService.dart';
import 'package:Tunein/services/isolates/musicServiceIsolate.dart';
import 'package:Tunein/utils/MathUtils.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
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

  Future<dynamic> getMostPlayedSongs(Map<String,dynamic> metricValues){

    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage(
        sender: tempPort.sendPort,
        command: "getMostPlayedSongs",
        message: [metricValues, musicService.ArtistList, musicService.SongList]
    ));
    return (tempPort.firstWhere((event) {
      return event!="OK";
    }));
  }

  Future<dynamic> getTopAlbum(Map<String,dynamic> GlobalSongPlayTime){

    ReceivePort tempPort = ReceivePort();
    MusicServiceIsolate.sendCrossIsolateMessage(CrossIsolatesMessage(
        sender: tempPort.sendPort,
        command: "getTopAlbums",
        message: [GlobalSongPlayTime, musicService.AlbumList, musicService.SongList]
    ));
    return (tempPort.firstWhere((event) {
      return event!="OK";
    }));
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
    Size screenSize = MediaQuery.of(context).size;
    ScrollController queuWidgetController = new ScrollController();
    int currentSongIndex =0;
    int currentListIndex=0;
    int currentSelectedItem;

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
                        return Container(
                          height:150,
                          child: PreferredPicks(
                            bottomTitle: "Most Played",
                            colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                          ),
                        );
                      }
                      Widget MostPlayedWiget = getMostPlayedWidget(context, msnapshot.data);
                      int firstLimiter = MathUtils.getRandomFromRange(0,  musicService.songs$.value.length-10);
                      List<Tune> randomSongs = musicService.songs$.value.sublist(firstLimiter, firstLimiter+10);
                      Widget RandomSongsWidgets = getRandomSongsWidget(context, randomSongs);
                      return Container(
                        height:150,
                        child: ListView(
                          children: <Widget>[
                            if (MostPlayedWiget!=null) MostPlayedWiget,
                            if(RandomSongsWidgets!=null) StreamBuilder(
                              initialData: "stwidget",
                              stream: Stream.periodic(Duration(minutes: 5)),
                              builder: (context, s){
                                if(s.data=="stwidget"){
                                  return RandomSongsWidgets;
                                }
                                int firstLimiter = MathUtils.getRandomFromRange(0,  musicService.songs$.value.length-10);
                                List<Tune> randomSongs = musicService.songs$.value.sublist(firstLimiter, firstLimiter+10);
                                return getRandomSongsWidget(context, randomSongs);
                              },
                            )
                          ],
                          scrollDirection: Axis.horizontal,
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
                    // ignore: missing_return
                    builder: (context, AsyncSnapshot<dynamic> msnapshot) {
                      List<Album> topAlbums;
                      if(msnapshot.hasData){
                        // ignore: missing_return
                        return StreamBuilder(
                          stream: getTopAlbum(msnapshot.data).asStream(),
                          builder: (context, AsyncSnapshot<dynamic> snapshot){
                            if(!snapshot.hasData){
                              return Container(
                                height: 190,
                                color: MyTheme.darkBlack,
                                padding: EdgeInsets.only(top: 10, bottom: 10),
                                child: Center(
                                  child: Text("Looking for Albums",
                                    style: TextStyle(
                                        color: MyTheme.grey300.withOpacity(.8),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18
                                    ),
                                  ),
                                ),
                              );
                            }
                            Map albumData = snapshot.data;
                            topAlbums = albumData["topAlbums"];
                            Map PlayDuration = albumData["playDuration"];
                            Widget shallowWidget = Container(
                              height: 190,
                              color: MyTheme.darkBlack,
                              padding: EdgeInsets.only(top: 10, bottom: 10),
                              child: Center(
                                child: Text("Looking for Albums",
                                  style: TextStyle(
                                      color: MyTheme.grey300.withOpacity(.8),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18
                                  ),
                                ),
                              ),
                            );
                            if(topAlbums==null){
                              return shallowWidget;
                            }
                            return getTopAlbumsWidget(context, topAlbums, PlayDuration);
                          },
                        );
                      }else{
                        return Container(
                          child: PreferredPicks(
                            allImageBlur:false,
                            bottomTitle: "",
                            colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                          ),
                          height: 190,
                        );
                      }
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Queue",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height:150,
                    child: ListView(
                      children: [
                        Material(
                            child: Container(
                              child: StreamBuilder(
                                stream: Rx.combineLatest3(musicService.playerState$, musicService.playlist$, musicService.playback$,(a, b, c) => [a,b,c]),
                                builder: (context, AsyncSnapshot<List> snapshot){
                                  if(!snapshot.hasData){
                                    return Container();
                                  }

                                  currentListIndex=0;
                                  Tune currentSong = snapshot.data[0].value;
                                  FixedExtentScrollController controller = new FixedExtentScrollController(initialItem: musicService.getSongIndex(currentSong));
                                  PlayerState currentState = snapshot.data[0].key;
                                  bool isPlaying = currentState==PlayerState.playing;
                                  final bool _isShuffle = snapshot.data[2].contains(Playback.shuffle);
                                  final List<Tune> currentPlaylist = _isShuffle ? snapshot.data[1].value : snapshot.data[1].key;


                                  return Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          child: Container(
                                            child: FadeInImage(
                                              placeholder: AssetImage('images/track.png'),
                                              fadeInDuration: Duration(milliseconds: 200),
                                              fadeOutDuration: Duration(milliseconds: 100),
                                              image: currentSong.albumArt != null
                                                  ? FileImage(
                                                new File(currentSong.albumArt),
                                              )
                                                  : AssetImage('images/track.png'),
                                            ),
                                          ),
                                          onTap: (){
                                            controller.animateToItem(currentSongIndex-1, curve: Curves.easeIn, duration: Duration(milliseconds: 200));
                                          },
                                        ),
                                        flex: 3,
                                      ),
                                      Expanded(
                                        flex: 9,
                                        child: Container(
                                          height: screenSize.width/3,
                                          /*margin: EdgeInsets.all(8).subtract(EdgeInsets.only(left: 8, right: 8))
                                  .add(EdgeInsets.only(top: 10)),*/
                                          child: GestureDetector(
                                            child: FadingEdgeScrollView.fromListWheelScrollView(
                                              child: ListWheelScrollView(
                                                children: currentPlaylist.map((e){
                                                  currentListIndex++;
                                                  bool isCurrentSong = e.id == currentSong.id;
                                                  if(isCurrentSong) currentSongIndex=currentListIndex;
                                                  return ListTile(
                                                    visualDensity: VisualDensity.compact,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                                    dense: true,
                                                    leading: isCurrentSong?Icon(isPlaying?Icons.pause_circle_outline:Icons.play_circle_outline, size: 28, color: MyTheme.darkRed):Icon(Icons.play_circle_outline, size: 28, color: MyTheme.darkgrey),
                                                    title: Text(e.title,
                                                      maxLines: 1,
                                                      strutStyle: StrutStyle(
                                                          height: 1,
                                                          forceStrutHeight: true
                                                      ),
                                                      style: TextStyle(
                                                          color: MyTheme.grey300,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 15
                                                      ),
                                                    ),
                                                    subtitle: SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Text(
                                                          "${e.album} by ${e.artist}",
                                                          maxLines: 1,
                                                          strutStyle: StrutStyle(
                                                              height: 1,
                                                              forceStrutHeight: true
                                                          ),
                                                          style: TextStyle(
                                                            color: MyTheme.grey300,
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: 13,
                                                          ),
                                                        )
                                                    ),
                                                    onTap: (){
                                                      musicService.playOrPause(e);
                                                    },
                                                    enabled: true,
                                                  );
                                                }).toList(),
                                                physics: FixedExtentScrollPhysics(),
                                                controller: controller,
                                                itemExtent: 45,
                                                magnification: 1.2,
                                                useMagnifier: false,
                                                diameterRatio: 3,
                                                perspective: 0.003,
                                                onSelectedItemChanged: (index){
                                                  currentSelectedItem=index;
                                                },
                                              ),
                                              gradientFractionOnEnd: 0.4,
                                              gradientFractionOnStart: 0.35,
                                            ),
                                            onTap: (){
                                              if(currentSelectedItem!=null)musicService.playOrPause(currentPlaylist[currentSelectedItem]);
                                            },
                                          ),
                                          padding: EdgeInsets.only(right: 5, left :5),
                                        ),
                                      )
                                    ],
                                  );
                                },
                              ),
                            ),
                            color: Colors.transparent
                        ),
                      ],
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: false,
                      itemExtent: 500,
                      physics: StageScrollingPhysics(
                          currentStage: 0,
                          stages: [0,(screenSize.width/4)+40]
                      ),
                      cacheExtent: 122,
                      controller: queuWidgetController,

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
                                  allImageBlur:false,
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


  ///Will return a single MostPlayed Widget
  Widget getMostPlayedWidget(context, Map PlayedSongData){
    Size screensize = MediaQuery.of(context).size;
    Future<List<int>> Asset8bitList = Future.sync(() async{
      ByteData dibd = await rootBundle.load("images/artist.jpg");
      List<int> defaultImageBytes = dibd.buffer.asUint8List();
      return defaultImageBytes;
    });

    Uint8List topImage;
    return Material(
        child: StreamBuilder(
          stream: getMostPlayedSongs(PlayedSongData).asStream(),
          builder: (context, AsyncSnapshot<dynamic> snapshot){
            Map mostPlayed = snapshot.data;
            if(!snapshot.hasData || mostPlayed==null){
              return Container(
                height: 190,
                child: PreferredPicks(
                  allImageBlur:false,
                  bottomTitle: "Most Played",
                  colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                ),
              );
            }

            Map<String,int> artistPresence = mostPlayed["artistsPresence"];
            List<Tune> mostPlayedSongs = mostPlayed["mostPlayedSongs"];
            mostPlayedSongs = mostPlayedSongs.sublist(0,min(9,mostPlayedSongs.length));
            List<Artist> artistToPutToWidgetBackground = artistPresence.keys.toList().sublist(0,min(4,artistPresence.length)).map((e) {
              return musicService.artists$.value.firstWhere((element) => element.name==e);
            }).toList();
            Future<List<List<int>>> backgroundimagesForMostPlayedSongs = Future.wait(artistToPutToWidgetBackground.map((e) async{
              if(e.coverArt==null){
                return await Asset8bitList;
              }
              return await ConversionUtils.FileUriTo8Bit(e.coverArt);
            }).toList());
            return StreamBuilder(
              stream: artistToPutToWidgetBackground.length!=0?backgroundimagesForMostPlayedSongs.asStream():Future.wait([Asset8bitList]).asStream(),
              builder: (context, AsyncSnapshot<List<List<int>>> snapshot){
                if(!snapshot.hasData){
                  return Container(
                    child: PreferredPicks(
                      allImageBlur:false,
                      bottomTitle: "Most Played",
                      colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                    ),
                  );
                }
                return GestureDetector(
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    child: ShowWithFade.fromStream(
                      inStream: ConversionUtils.createImageFromWidget(
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child:PreferredPicks(
                              bottomTitle: "Most Played",
                              allImageBlur:false,
                              colors: [MyTheme.grey300.value, MyTheme.darkBlack.value],
                              backgroundWidget: getCombinedImages(snapshot.data, standardHeight: 150, standardWidth: 200, maxWidth: 200),
                            ),
                          ),
                          imageSize: Size(200, 150),
                          logicalSize: Size(200, 150),
                          wait: Duration(milliseconds: 450)
                      ).then((value) {
                        topImage = value;
                        return Image.memory(value);
                      }).asStream(),
                      inCurve: Curves.easeIn,
                      fadeDuration: Duration(milliseconds: 100),
                      durationUntilFadeStarts: Duration(milliseconds: 350),
                      shallowWidget: PreferredPicks(
                        allImageBlur:false,
                        bottomTitle: "Most Played",
                        colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                      ),
                    ),
                  ),
                  onTap: (){
                    showGeneralDialog(
                        barrierLabel: "MostPlayed",
                        barrierDismissible: true,
                        barrierColor: Colors.black.withOpacity(0.8),
                        transitionDuration: Duration(milliseconds: 100),
                        context: context,
                        pageBuilder: (context, anim1, anim2){
                          return MultipleSongTapPopupWidget(
                              TopBackgroundWidget: getCombinedImages(snapshot.data, standardHeight: screensize.height*0.2, standardWidth: screensize.width*0.85, maxWidth: screensize.width*0.85),
                              screensize: screensize,
                              onShuffleButtonTap: (){
                                musicService.updatePlaylist(mostPlayedSongs);
                                musicService.updatePlayback(Playback.shuffle);
                                musicService.stopMusic();
                                musicService.playMusic(musicService.playlist$.value.value[0]);
                              },
                              listOfSongs: mostPlayedSongs,
                              TopwidgetBottomTitle: "Most Played Songs'List",
                              onPlaybuttonTap: (){
                                musicService.updatePlaylist(mostPlayedSongs);
                                musicService.stopMusic();
                                musicService.playMusic(mostPlayedSongs[0]);
                              },
                              onSaveButtonTap: () async{
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
                                  Uri fileURI = await FileService.saveBytesToFile(topImage);
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
                              }
                          );
                        },
                        transitionBuilder: (context, anim1, anim2, child){
                          return AnimatedDialog(
                            dialogContent: child,
                            inputAnimation: anim1,
                          );
                        }
                    );
                  },
                );
              },
            );
          },
        ),
        color: Colors.transparent
    );
  }

  ///Will return a single RandomSongs widget
  Widget getRandomSongsWidget(context, List<Tune> songsToChooseFrom){
    if(songsToChooseFrom !=null && songsToChooseFrom.length!=0){
      Size screensize = MediaQuery.of(context).size;
      Future<List<int>> Asset8bitList = Future.sync(() async{
        ByteData dibd = await rootBundle.load("images/artist.jpg");
        List<int> defaultImageBytes = dibd.buffer.asUint8List();
        return defaultImageBytes;
      });
      int firstBracket = MathUtils.getRandomFromRange(0, (min((songsToChooseFrom.length-4).abs(),songsToChooseFrom.length)));

      List<Tune> backgroundIamgeSongs = songsToChooseFrom.sublist(firstBracket,firstBracket+min(4,songsToChooseFrom.length-firstBracket));
      Future<List<List<int>>> backgroundimagesForMostPlayedSongs = Future.wait(backgroundIamgeSongs.map((e) async{
        if(e.albumArt==null){
          return await Asset8bitList;
        }
        return await ConversionUtils.FileUriTo8Bit(e.albumArt);
      }).toList());

      Uint8List topImage;

      return Material(
          child: StreamBuilder(
            stream: backgroundIamgeSongs.length!=0?backgroundimagesForMostPlayedSongs.asStream():Future.wait([Asset8bitList]).asStream(),
            builder: (context, AsyncSnapshot<List<List<int>>> snapshot){
              GlobalKey MostPlayedKey = new GlobalKey();
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                switchInCurve: Curves.easeInToLinear,
                child: !snapshot.hasData?Container(
                  child: PreferredPicks(
                    allImageBlur:false,
                    bottomTitle: "Random Songs",
                    colors: [MyTheme.grey300.value, MyTheme.darkBlack.value],
                  ),
                ):GestureDetector(
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    child: ShowWithFade.fromStream(
                      inStream: ConversionUtils.createImageFromWidget(
                          Container(
                            height: 150,
                            width: 200,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child:PreferredPicks(
                                bottomTitle: "Random Songs",
                                allImageBlur:false,
                                colors: [MyTheme.grey300.value, MyTheme.darkBlack.value],
                                backgroundWidget: getCombinedImages(snapshot.data, standardHeight: 150, standardWidth: 200, maxWidth: 200),
                              ),
                            ),
                          ),
                          imageSize: Size(200, 150),
                          logicalSize: Size(200, 150),
                        wait: Duration(milliseconds: 450)
                      ).then((value){
                       topImage= value;
                       return Image.memory(value);
                      }).asStream(),
                      inCurve: Curves.easeIn,
                      fadeDuration: Duration(milliseconds: 100),
                      durationUntilFadeStarts: Duration(milliseconds: 350),
                      shallowWidget: PreferredPicks(
                        allImageBlur:false,
                        bottomTitle: "Most Played",
                        colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                      ),
                    ),
                  ),
                  onTap: (){
                    showGeneralDialog(
                        barrierLabel: "RandomSongs",
                        barrierDismissible: true,
                        barrierColor: Colors.black.withOpacity(0.7),
                        transitionDuration: Duration(milliseconds: 80),
                        context: context,
                        pageBuilder: (context, anim1, anim2){
                          return MultipleSongTapPopupWidget(
                            listOfSongs: songsToChooseFrom,
                            TopwidgetBottomTitle: "Random Songs' List",
                            onPlaybuttonTap: (){
                              musicService.updatePlaylist(songsToChooseFrom);
                              musicService.stopMusic();
                              musicService.playMusic(songsToChooseFrom[0]);
                            },
                            onSaveButtonTap: () async{
                              bool result = await  DialogService.showConfirmDialog(context,
                                  message: "Save this songs list as a playlist",
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
                                Uri fileURI = await FileService.saveBytesToFile(topImage);
                                Playlist newPlaylist = new Playlist(
                                    "Random Songs Playlist ${DateTime.now().toIso8601String()}",
                                    songsToChooseFrom,
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
                            },
                            onShuffleButtonTap: (){
                              musicService.updatePlaylist(songsToChooseFrom);
                              musicService.updatePlayback(Playback.shuffle);
                              musicService.stopMusic();
                              musicService.playMusic(musicService.playlist$.value.value[0]);
                            },
                            screensize: screensize,
                            TopBackgroundWidget: getCombinedImages(snapshot.data, standardHeight: screensize.height*0.2, standardWidth: screensize.width*0.85, maxWidth: screensize.width*0.85),
                          );
                        },
                        transitionBuilder: (context, anim1, anim2, child){
                          return AnimatedDialog(
                            dialogContent: child,
                            inputAnimation: anim1,
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
    }
    else{
      return null;
    }
  }

  ///Will return a single topAlbum widget
  Widget getTopAlbumsWidget(context, List<Album> AlbumSongs, Map<String, Duration> playDuration){
    if(AlbumSongs !=null && AlbumSongs.length!=0){
      Size screensize = MediaQuery.of(context).size;
      Future<List<int>> Asset8bitList = Future.sync(() async{
        ByteData dibd = await rootBundle.load("images/artist.jpg");
        List<int> defaultImageBytes = dibd.buffer.asUint8List();
        return defaultImageBytes;
      });


      return Material(
          child: Container(
            height:190,
            child: ListView.builder(
              itemBuilder: (context, index){
                return Material(
                    child: StreamBuilder(
                      stream: AlbumSongs[index].albumArt!=null?ConversionUtils.FileUriTo8Bit(AlbumSongs[index].albumArt).asStream():Asset8bitList.asStream(),
                      builder: (context, AsyncSnapshot<List<int>> snapshot){
                        if(snapshot.hasError){

                          return PreferredPicks(
                            allImageBlur:false,
                            bottomTitle: "",
                            colors: [MyTheme.grey300.value, MyTheme.darkBlack.value],
                          );
                        }
                        return AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          switchInCurve: Curves.easeInToLinear,
                          child: !snapshot.hasData?Container(
                            child: PreferredPicks(
                              allImageBlur:false,
                              bottomTitle: "Most Played",
                              colors: [MyTheme.grey300.value, MyTheme.darkBlack.value],
                            ),
                          ):GestureDetector(
                            child: Container(
                              margin: EdgeInsets.only(right: 8),
                              child: Stack(
                                children: <Widget>[
                                  PreferredPicks(
                                    allImageBlur:false,
                                    bottomTitle: "${AlbumSongs[index].title.split(' ').join('\n')}",
                                    backgroundWidget: getCombinedImages([snapshot.data], maxWidth: 122, standardWidth: 122, standardHeight: 190),
                                    colors: AlbumSongs[index].songs[0].colors.map((e){
                                      return Color(e).withOpacity(.5).value;
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            onTap: (){
                              List<int> colors = AlbumSongs[index].songs[0].colors;
                              showGeneralDialog(
                                  barrierLabel: "TopAlbums",
                                  barrierDismissible: true,
                                  barrierColor: Colors.black.withOpacity(0.7),
                                  transitionDuration: Duration(milliseconds: 100),
                                  context: context,
                                  pageBuilder: (context, anim1, anim2){
                                    return SinglePicturePopupWidget(
                                        listOfSongs: AlbumSongs[index].songs,
                                        onPlaybuttonTap: (){
                                          musicService.updatePlaylist(AlbumSongs[index].songs);
                                          musicService.stopMusic();
                                          musicService.playMusic(AlbumSongs[index].songs[0]);
                                        },
                                        onShuffleButtonTap: (){
                                          musicService.updatePlaylist(AlbumSongs[index].songs);
                                          musicService.updatePlayback(Playback.shuffle);
                                          musicService.stopMusic();
                                          musicService.playMusic(musicService.playlist$.value.value[0]);
                                        },
                                        screensize: screensize,
                                        title: AlbumSongs[index].title,
                                        subtitle: AlbumSongs[index].artist,
                                        colors: colors,
                                        topLeftImage: AlbumSongs[index].albumArt,
                                        Description: "3333333333",
                                        underSubtitleTray: Column(
                                          children: <Widget>[
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.max,
                                              children: <Widget>[
                                                Row(
                                                  mainAxisSize: MainAxisSize.max,
                                                  children: <Widget>[
                                                    Container(
                                                      margin: EdgeInsets.only(right: 5),
                                                      child: Text(
                                                        AlbumSongs[index].songs.length.toString(),
                                                        style: TextStyle(
                                                          color: (colors!=null && colors.length!=null)!=null?Color(colors[1]):Colors.white70,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.audiotrack,
                                                      color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                                    )
                                                  ],
                                                ),
                                                Container(
                                                  margin: EdgeInsets.only(right: 8, left :8),
                                                  width: 1,
                                                  color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: <Widget>[
                                                    Container(
                                                      child: Text(
                                                        "${Duration(milliseconds: ConversionUtils.songListToDuration(AlbumSongs[index].songs).floor()).inMinutes} min",
                                                        style: TextStyle(
                                                          color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      margin: EdgeInsets.only(right: 5),
                                                    ),
                                                    Icon(
                                                      Icons.access_time,
                                                      color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                                    )
                                                  ],
                                                ),
                                                Container(
                                                  margin: EdgeInsets.only(right: 8, left :8),
                                                  width: 4,
                                                  color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                                ),
                                              ],
                                            ),
                                            SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Padding(
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.max,
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: <Widget>[
                                                      Icon(
                                                        Icons.av_timer,
                                                        color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                                      ),
                                                      Container(
                                                        child: Text(
                                                          "${ConversionUtils.DurationToFancyText(playDuration[AlbumSongs[index].id.toString()])} of play time",
                                                          style: TextStyle(
                                                            color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        margin: EdgeInsets.only(left: 5),
                                                      ),
                                                    ],
                                                  ),
                                                  padding: EdgeInsets.only(left: 4),
                                                )
                                            )

                                          ],
                                        )
                                    );
                                  },
                                  transitionBuilder: (context, anim1, anim2, child){
                                    return AnimatedDialog(
                                      dialogContent: child,
                                      inputAnimation: anim1,
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
              itemCount: min(4,AlbumSongs.length),
              shrinkWrap: false,
              itemExtent: 122,
              physics: AlwaysScrollableScrollPhysics(),
              cacheExtent: 122,
            ),
            padding: EdgeInsets.all(10),
          ),
          color: Colors.transparent
      );
    }
    else{
      return null;
    }
  }

  void goToAlbumSongsList(Tune song) async {
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

  void goToSingleArtistPage(Tune song){
    Artist artist = musicService.getArtistTitle(song.artist);
    if(artist!=null){
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SingleArtistPage(artist, heightToSubstract: 60),
        ),
      );
    }
  }

  ///Will return the content of the popup widget with a list of songs and a control deck
  MultipleSongTapPopupWidget({
    Size screensize,
    Widget TopBackgroundWidget,
    bool showPlaybutton=true,
    bool showSaveButton=true,
    bool showShuffleButton=true,
    VoidCallback onPlaybuttonTap,
    VoidCallback onSaveButtonTap,
    VoidCallback onShuffleButtonTap,
    List<Tune> listOfSongs = const [],
    String TopwidgetBottomTitle="",

  }){

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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onPanUpdate: (details){
              if (details.delta.dy > 10){
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: ShowWithFade.fromStream(
              inStream: ConversionUtils.createImageFromWidget(
                  Container(
                    height: screensize.height*0.2,
                    width: (screensize.width*0.85)+10,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child:PreferredPicks(
                        allImageBlur: false,
                        bottomTitle: TopwidgetBottomTitle,
                        colors: [MyTheme.grey300.value, MyTheme.darkBlack.value],
                        backgroundWidget: TopBackgroundWidget,
                        borderRadius: Radius.zero,
                      ),
                    ),
                  ),
                  imageSize: Size((screensize.width*0.85)+10, screensize.height*0.2),
                  logicalSize: Size((screensize.width*0.85)+10, screensize.height*0.2),
                  wait: Duration(milliseconds: 300)
              ).then((value) =>Image.memory(value)).asStream(),
              inCurve: Curves.easeIn,
              fadeDuration: Duration(milliseconds: 100),
              durationUntilFadeStarts: Duration(milliseconds: 350),
              shallowWidget: Container(
                height: screensize.height*0.2,
                width: (screensize.width*0.85)+10,
                color: MyTheme.bgBottomBar,
              ),
            ),
          ),

          Container(
            color: MyTheme.darkBlack,
            height: 62,
            width: screensize.width*0.85,
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
                    if(onPlaybuttonTap!=null){
                      onPlaybuttonTap();
                    }
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
                    if(onShuffleButtonTap!=null){
                      onShuffleButtonTap();
                    }
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
                    if(onSaveButtonTap!=null){
                      onSaveButtonTap();
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          ShowWithFade(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
              ),
              height: screensize.height*0.5,
              width: screensize.width*0.85,
              child: GenericSongList(
                songs: listOfSongs,
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
                      musicService.startWithAndShuffleQueue(tune, listOfSongs);
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
                    case 7: {
                      DialogService.showAlertDialog(context,
                          title: "Song Information",
                          content: SongInfoWidget(null, song: tune),
                          padding: EdgeInsets.only(top: 10)
                      );
                      break;
                    }
                    case 8:{
                      goToAlbumSongsList(tune);
                      break;
                    }
                    case 9:{
                      goToSingleArtistPage(tune);
                      break;
                    }
                  }
                },
                onSongCardTap: (song,state,isSelectedSong){
                  musicService.updatePlaylist([song]);
                  musicService.playOrPause(song);
                },
              ),
            ),
            durationUntilFadeStarts: Duration(milliseconds: 150),
            fadeDuration: Duration(milliseconds: 150),
            shallowWidget: Container(
              width: screensize.width*0.85,
              height: screensize.height*0.5,
              color: MyTheme.bgBottomBar,
            ),
          )
        ],
      ),
    );
  }

  ///Will return the content of the popup widget with a single picture on the top and information on the right and a list
  ///of songs beneath (used in topAlbums)
  SinglePicturePopupWidget({
    Size screensize,
    Widget TopLeftWidget,
    String topLeftImage,
    String title,
    String subtitle,
    String Description,
    Widget underSubtitleTray,
    bool showPlaybutton=true,
    bool showShuffleButton=true,
    VoidCallback onPlaybuttonTap,
    VoidCallback onShuffleButtonTap,
    List<int> colors,
    List<Tune> listOfSongs = const [],
  }){
    File imageFile = TopLeftWidget==null?topLeftImage!=null?File.fromUri(Uri.parse(topLeftImage)):null:TopLeftWidget;
    double popupWidth = screensize.width*0.85;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
              onPanUpdate: (details){
                if (details.delta.dy > 10){
                  Navigator.of(context, rootNavigator: true).pop();
                }
              },
              child: Container(
                color: MyTheme.bgBottomBar,
                width: popupWidth,
                child: ShowWithFade(
                  durationUntilFadeStarts: Duration(milliseconds: 300),
                  fadeDuration: Duration(milliseconds: 50),
                  child: Container(
                    color: (colors!=null && colors.length!=0)?Color(colors[0]):MyTheme.darkBlack,
                    width: popupWidth,
                    child: Row(
                      children: <Widget>[
                        Container(
                            height: 80,
                            width: 80,
                            child: TopLeftWidget??FadeInImage(
                              fit: BoxFit.cover,
                              placeholder: AssetImage('images/cover.png'),
                              fadeInDuration: Duration(milliseconds: 300),
                              fadeOutDuration: Duration(milliseconds: 100),
                              image: (imageFile!=null &&  imageFile.existsSync())
                                  ? FileImage(
                                imageFile,
                              )
                                  : AssetImage('images/cover.png'),
                            )
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 5, left: 5),
                          width: popupWidth - 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Padding(
                                child: Text(title??"Unknown title",
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: TextStyle(
                                      color: colors!=null?Color(colors[1]):MyTheme.grey300,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17
                                  ),
                                ),
                                padding: EdgeInsets.only(bottom: 5),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(subtitle??"Unknown Artist",
                                  overflow: TextOverflow.fade,
                                  maxLines: 1,
                                  style: TextStyle(
                                      color: (colors!=null?Color(colors[1]):MyTheme.grey300).withOpacity(.8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15
                                  ),
                                ),
                              ),
                              underSubtitleTray??Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Container(
                                        margin: EdgeInsets.only(right: 5),
                                        child: Text(
                                          listOfSongs.length.toString(),
                                          style: TextStyle(
                                            color: (colors!=null && colors.length!=null)!=null?Color(colors[1]):Colors.white70,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.audiotrack,
                                        color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                      )
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(right: 8, left :8),
                                    width: 1,
                                    color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Container(
                                        child: Text(
                                          "${Duration(milliseconds: ConversionUtils.songListToDuration(listOfSongs).floor()).inMinutes} min",
                                          style: TextStyle(
                                            color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        margin: EdgeInsets.only(right: 5),
                                      ),
                                      Icon(
                                        Icons.access_time,
                                        color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                      )
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(right: 8, left :8),
                                    width: 4,
                                    color: (colors!=null && colors.length!=null)?Color(colors[1]):Colors.white70,
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  inCurve: Curves.easeIn,
                  shallowWidget: Container(
                    width: popupWidth,
                    color: MyTheme.bgBottomBar.withOpacity(.3),
                  ),
                ),
              ),
            ),
            ShowWithFade(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                ),
                width: screensize.width*0.85,
                height: screensize.height*0.5,
                child: GenericSongList(
                  songs: listOfSongs,
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
                        musicService.startWithAndShuffleQueue(tune, listOfSongs);
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
                      case 7: {
                        DialogService.showAlertDialog(context,
                            title: "Song Information",
                            content: SongInfoWidget(null, song: tune),
                            padding: EdgeInsets.only(top: 10)
                        );
                        break;
                      }
                      case 8:{
                        goToAlbumSongsList(tune);
                        break;
                      }
                      case 9:{
                        goToSingleArtistPage(tune);
                        break;
                      }
                    }
                  },
                  onSongCardTap: (song,state,isSelectedSong){
                    musicService.updatePlaylist([song]);
                    musicService.playOrPause(song);
                  },
                ),
              ),
              durationUntilFadeStarts: Duration(milliseconds: 200),
              fadeDuration: Duration(milliseconds: 150),
              shallowWidget: Container(
                width: screensize.width*0.85,
                height: screensize.height*0.5,
                color: MyTheme.bgBottomBar,
              ),
            ),

          ],
        ),
      ),
    );
  }
}
